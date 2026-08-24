import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

// ---------------------------------------------------------------------------
// Contract-drift guard for API v1. Fails RED whenever the checked-in generated
// TypeScript (packages/shared-types/ts/src/valgate-api-v1.ts) has fallen out of
// sync with the authoritative OpenAPI YAML (packages/api-spec/valgate-api-v1.yaml).
// Deliberately does NOT parse YAML — greps the raw text for the operationId /
// schema shapes the generated artifact must mirror. Paths are resolved relative
// to this file (not process.cwd()) so the test works from any invocation dir.
// ---------------------------------------------------------------------------

const testDir = path.dirname(fileURLToPath(import.meta.url));
const yamlPath = path.resolve(testDir, "../../../../../packages/api-spec/valgate-api-v1.yaml");
const generatedTsPath = path.resolve(
  testDir,
  "../../../../../packages/shared-types/ts/src/valgate-api-v1.ts",
);

const yamlSource = readFileSync(yamlPath, "utf8");
const generatedSource = readFileSync(generatedTsPath, "utf8");

// Extracts the text of a top-level `"key": { ... }` or `Key: { ... }` block by
// brace-matching from the first `{` after the key, without a full parser.
function extractBlock(source: string, keyPattern: string): string {
  const keyIndex = source.indexOf(keyPattern);
  if (keyIndex === -1) {
    throw new Error(`extractBlock: could not find "${keyPattern}" in source`);
  }
  const braceStart = source.indexOf("{", keyIndex);
  if (braceStart === -1) {
    throw new Error(`extractBlock: no opening brace after "${keyPattern}"`);
  }
  let depth = 0;
  for (let i = braceStart; i < source.length; i++) {
    if (source[i] === "{") depth++;
    else if (source[i] === "}") {
      depth--;
      if (depth === 0) return source.slice(braceStart, i + 1);
    }
  }
  throw new Error(`extractBlock: unbalanced braces for "${keyPattern}"`);
}

describe("OpenAPI v1 contract sync: YAML source vs generated TypeScript", () => {
  it("sanity: the authoritative YAML declares POST /properties as createProperty", () => {
    // Precondition for the drift assertions below — if this ever fails, the YAML
    // itself changed and the generated-artifact expectations must be revisited.
    const propertiesPostBlock = yamlSource.slice(
      yamlSource.indexOf("  /properties:"),
      yamlSource.indexOf("  /properties/{id}:"),
    );
    expect(propertiesPostBlock).toMatch(/operationId:\s*createProperty/);
  });

  it("generated paths['/properties'] declares post: operations[\"createProperty\"] (regen required)", () => {
    const pathsPropertiesBlock = extractBlock(generatedSource, '"/properties": {');
    expect(pathsPropertiesBlock).toContain('post: operations["createProperty"];');
  });

  it("generated operations interface defines createProperty (regen required)", () => {
    const operationsBlock = extractBlock(generatedSource, "export interface operations {");
    expect(operationsBlock).toMatch(/\bcreateProperty:\s*\{/);
  });

  it("generated PropertyListItemDtoV1 includes lat/lng (regen required)", () => {
    const dtoBlock = extractBlock(generatedSource, "PropertyListItemDtoV1: {");
    expect(dtoBlock).toContain("lat: number;");
    expect(dtoBlock).toContain("lng: number;");
  });
});
