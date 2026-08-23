import { describe, it, expect, vi, beforeEach } from "vitest";
import { PgDialect } from "drizzle-orm/pg-core";
import type { Ctx } from "@/lib/services/_mapping";

// ---------------------------------------------------------------------------
// bulkAssignProperties: tenant-boundary regression tests for the already-shipped
// cross-org fix. DB fully mocked (same pattern as properties.page.test.ts) — no
// real connection, no credentials, deterministic.
//
// The mock is a *faithful* Drizzle chain, not a stub: every WHERE it receives is
// the real `and(eq(...), eq(...))` SQL object the service built, rendered to
// { sql, params } via the real PgDialect and evaluated against a tiny in-memory
// property store. So a row is returned/updated only when the predicate the code
// actually emitted matches it — which is exactly what proves the tenant scope is
// keyed on ctx.orgId (change the code to scope by the wrong org and these fail).
//
// Proves:
//   1) targetOrgId !== ctx.orgId short-circuits to { assigned: 0, conflicts: ids }
//      WITHOUT ever opening db.transaction.
//   2) a cross-org property id never matches the org-scoped SELECT, so it lands in
//      conflicts and no UPDATE is issued — and the SELECT predicate binds ctx.orgId.
//   3) a same-org property is assigned: clientId is written and success is reported.
// ---------------------------------------------------------------------------

const dialect = new PgDialect();

// Render a real Drizzle WHERE condition to { sql, params } exactly as the driver
// would before sending it to Postgres. No hand-parsing of Drizzle internals.
function render(cond: unknown): { sql: string; params: unknown[] } {
  const q = (dialect as unknown as {
    sqlToQuery: (c: unknown) => { sql: string; params: unknown[] };
  }).sqlToQuery(cond);
  return { sql: q.sql, params: q.params };
}

type Row = { id: string; orgId: string; clientId: string | null };

const store = vi.hoisted(() => ({
  rows: [] as { id: string; orgId: string; clientId: string | null }[],
  transactionCalls: 0,
  selectWheres: [] as { sql: string; params: unknown[] }[],
  updateWheres: [] as { sql: string; params: unknown[] }[],
  updateSets: [] as Record<string, unknown>[],
}));

vi.mock("@/lib/env", () => ({
  env: {
    DATABASE_URL: "postgresql://mock-bulk-assign-tests-only",
    DEMO_MODE: false,
    DEMO_ALLOW_WRITES: false,
  },
}));

// A row satisfies an org-scoped `id = $ AND org_id = $` predicate iff BOTH its id
// and its orgId are among the values the predicate actually bound. Because the
// bound org value comes straight from the code under test, a query scoped to the
// wrong org would bind the wrong org and this membership check would (correctly)
// let a cross-org row through — so the assertions below genuinely pin the scope.
function rowMatches(row: Row, params: unknown[]): boolean {
  return params.includes(row.id) && params.includes(row.orgId);
}

vi.mock("@/lib/db/client", () => {
  const tx = {
    select: () => ({
      from: () => ({
        where: (cond: unknown) => {
          const q = render(cond);
          store.selectWheres.push(q);
          return {
            limit: () =>
              Promise.resolve(store.rows.filter((r) => rowMatches(r, q.params))),
          };
        },
      }),
    }),
    update: () => ({
      set: (vals: Record<string, unknown>) => {
        store.updateSets.push(vals);
        return {
          where: (cond: unknown) => {
            const q = render(cond);
            store.updateWheres.push(q);
            for (const r of store.rows) {
              if (rowMatches(r, q.params)) Object.assign(r, vals);
            }
            return Promise.resolve();
          },
        };
      },
    }),
  };
  return {
    db: {
      transaction: vi.fn(async (fn: (t: typeof tx) => Promise<unknown>) => {
        store.transactionCalls += 1;
        return fn(tx);
      }),
    },
  };
});

import { bulkAssignProperties } from "./properties";

const CTX: Ctx = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" };

beforeEach(() => {
  store.rows = [];
  store.transactionCalls = 0;
  store.selectWheres = [];
  store.updateWheres = [];
  store.updateSets = [];
});

describe("bulkAssignProperties — tenant boundary", () => {
  it("short-circuits when targetOrgId !== ctx.orgId, without opening a transaction", async () => {
    // Even a property that DOES belong to the caller's org must not be touched when
    // the assignment targets a different org.
    store.rows = [{ id: "PROP-0001", orgId: CTX.orgId, clientId: null }];
    const requestedIds = ["PROP-0001", "PROP-0002"];

    const result = await bulkAssignProperties(
      CTX,
      "USR-9999",
      "ORG-OTHER", // != ctx.orgId
      requestedIds,
    );

    expect(result).toEqual({ assigned: 0, conflicts: requestedIds });
    // The whole DB path is skipped — no transaction, no select, no update.
    expect(store.transactionCalls).toBe(0);
    expect(store.selectWheres).toHaveLength(0);
    expect(store.updateWheres).toHaveLength(0);
    // The caller's row is left exactly as it was.
    expect(store.rows[0]!.clientId).toBeNull();
  });

  it("does not assign a cross-org property and issues no update (SELECT is scoped to ctx.orgId)", async () => {
    // The property physically lives in a different org than the caller. targetOrgId
    // equals ctx.orgId so we get past the short-circuit and into the real query path.
    store.rows = [{ id: "PROP-XORG", orgId: "ORG-INTRUDER", clientId: null }];

    const result = await bulkAssignProperties(
      CTX,
      "USR-0002",
      CTX.orgId,
      ["PROP-XORG"],
    );

    // Not found under the caller's org → conflict, nothing assigned.
    expect(result).toEqual({ assigned: 0, conflicts: ["PROP-XORG"] });

    // The transaction ran (past the guard) but no UPDATE was ever issued.
    expect(store.transactionCalls).toBe(1);
    expect(store.updateWheres).toHaveLength(0);
    expect(store.updateSets).toHaveLength(0);

    // The foreign row is untouched.
    expect(store.rows[0]!.clientId).toBeNull();

    // Prove the lookup predicate is tenant-scoped by ctx.orgId: the SELECT the code
    // emitted bound ctx.orgId against the org_id column (and the target id).
    expect(store.selectWheres).toHaveLength(1);
    const sel = store.selectWheres[0]!;
    expect(sel.sql).toContain("org_id");
    expect(sel.params).toContain(CTX.orgId);
    expect(sel.params).toContain("PROP-XORG");
    // It must NOT have been scoped to the property's real (foreign) org.
    expect(sel.params).not.toContain("ORG-INTRUDER");
  });

  it("assigns a same-org property: writes clientId and reports success", async () => {
    store.rows = [{ id: "PROP-0001", orgId: CTX.orgId, clientId: null }];

    const result = await bulkAssignProperties(
      CTX,
      "USR-0002",
      CTX.orgId,
      ["PROP-0001"],
    );

    expect(result).toEqual({ assigned: 1, conflicts: [] });

    // The row was updated in place: clientId set to the target user.
    expect(store.rows[0]!.clientId).toBe("USR-0002");

    // The UPDATE is itself org-scoped to ctx.orgId (no unscoped writes).
    expect(store.updateWheres).toHaveLength(1);
    const upd = store.updateWheres[0]!;
    expect(upd.sql).toContain("org_id");
    expect(upd.params).toContain(CTX.orgId);
    expect(upd.params).toContain("PROP-0001");
    expect(store.updateSets[0]).toMatchObject({ clientId: "USR-0002" });
  });
});
