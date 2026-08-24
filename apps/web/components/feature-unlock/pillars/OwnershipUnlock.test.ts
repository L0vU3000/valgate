import { beforeEach, describe, expect, it, vi } from "vitest";

// Server actions are mocked at the module boundary — onSubmitData is exercised
// as a real function, only its I/O (DB-backed server actions) is faked.
const createOwnershipRecord = vi.fn();
const updateOwnershipRecord = vi.fn();
const verifyOwnership = vi.fn();
const getOwnershipWizardInitialAction = vi.fn();

const updateProperty = vi.fn();

const createCoOwner = vi.fn();
const updateCoOwner = vi.fn();
const removeCoOwner = vi.fn();
const listCoOwnersForPropertyAction = vi.fn();

vi.mock("@/app/actions/ownership-records", () => ({
  createOwnershipRecord: (...args: unknown[]) => createOwnershipRecord(...args),
  updateOwnershipRecord: (...args: unknown[]) => updateOwnershipRecord(...args),
  verifyOwnership: (...args: unknown[]) => verifyOwnership(...args),
  getOwnershipWizardInitialAction: (...args: unknown[]) =>
    getOwnershipWizardInitialAction(...args),
}));

vi.mock("@/app/actions/properties", () => ({
  updateProperty: (...args: unknown[]) => updateProperty(...args),
}));

vi.mock("@/app/actions/co-owners", () => ({
  createCoOwner: (...args: unknown[]) => createCoOwner(...args),
  updateCoOwner: (...args: unknown[]) => updateCoOwner(...args),
  removeCoOwner: (...args: unknown[]) => removeCoOwner(...args),
  listCoOwnersForPropertyAction: (...args: unknown[]) =>
    listCoOwnersForPropertyAction(...args),
}));

import { ownershipWizardConfig } from "./OwnershipUnlock";

describe("ownershipWizardConfig.onSubmitData", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("does not delete existing co-owners when Sole Ownership hides the Co-owners step", async () => {
    updateOwnershipRecord.mockResolvedValue({
      ok: true,
      data: { id: "own-1" },
    });
    listCoOwnersForPropertyAction.mockResolvedValue({
      ok: true,
      data: [
        {
          id: "co-1",
          propertyId: "prop-1",
          name: "Jane Doe",
          role: "Primary",
          sharePercent: 100,
        },
      ],
    });

    const result = await ownershipWizardConfig.onSubmitData({
      propertyId: "prop-1",
      entityId: "own-1",
      values: {
        holdingType: "Sole Ownership",
        distributionMethod: undefined,
        coOwners: [],
      },
    });

    expect(result.ok).toBe(true);
    // The Co-owners step is skipped/hidden for Sole Ownership, so the user never
    // saw (or emptied) the existing co-owner list. Submitting must not delete it.
    expect(removeCoOwner).not.toHaveBeenCalled();
  });
});
