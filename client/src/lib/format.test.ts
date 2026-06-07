import { describe, expect, it } from "vitest";
import { roleLabel, rupiah, statusLabel } from "./format";

describe("format helpers", () => {
  it("formats Indonesian rupiah", () => {
    expect(rupiah(100000)).toContain("100.000");
  });

  it("maps roles and statuses to readable labels", () => {
    expect(roleLabel("super_admin")).toBe("Super Administrator");
    expect(statusLabel("va_bca")).toBe("Va Bca");
  });
});

