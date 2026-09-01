import { beforeEach, describe, expect, it, vi } from "vitest";

const { revalidateTagMock } = vi.hoisted(() => ({
  revalidateTagMock: vi.fn(),
}));

vi.mock("next/cache", () => ({
  revalidateTag: revalidateTagMock,
}));

import { revalidateFeTag } from "./_result";

describe("revalidateFeTag", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("revalidates the frontend tag with the Next cache profile", () => {
    revalidateFeTag("properties");

    expect(revalidateTagMock).toHaveBeenCalledWith("properties", "max");
  });
});
