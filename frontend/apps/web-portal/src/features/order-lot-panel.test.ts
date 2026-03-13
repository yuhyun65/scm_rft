import { describe, expect, it } from "vitest";
import { resolveChangedBy } from "./order-lot-panel";

describe("resolveChangedBy", () => {
  it("syncs changedBy to the latest login identity when the field still tracks the previous hint", () => {
    expect(
      resolveChangedBy({
        currentChangedBy: "member-a",
        changedByHint: "member-b",
        previousChangedByHint: "member-a"
      })
    ).toBe("member-b");
  });

  it("fills an empty field from the current login identity", () => {
    expect(
      resolveChangedBy({
        currentChangedBy: "",
        changedByHint: "member-b",
        previousChangedByHint: "member-a"
      })
    ).toBe("member-b");
  });

  it("preserves a manual override when login identity changes", () => {
    expect(
      resolveChangedBy({
        currentChangedBy: "manual-auditor",
        changedByHint: "member-b",
        previousChangedByHint: "member-a"
      })
    ).toBe("manual-auditor");
  });
});
