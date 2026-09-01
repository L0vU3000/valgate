import { revalidateTag } from "next/cache";

export type ActionResult<T = unknown> =
  | { ok: true; data: T }
  | { ok: false; error: string };

export const NOT_IMPLEMENTED_UNTIL_B6 = {
  ok: false as const,
  error: "not implemented until B6",
};

/** Revalidate FE contract tags using Next's stale-while-revalidate cache profile. */
export function revalidateFeTag(tag: string): void {
  revalidateTag(tag, "max");
}
