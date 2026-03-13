import { describe, expect, it } from "vitest";
import { resolveTrackedValue } from "./inventory-file-report-panel";

describe("inventory/report tracked value", () => {
  it("follows the latest member hint when the field still mirrors the previous hint", () => {
    expect(
      resolveTrackedValue({
        currentValue: "smoke-user",
        nextHint: "smoke-admin",
        previousHint: "smoke-user"
      })
    ).toBe("smoke-admin");
  });

  it("preserves manual overrides", () => {
    expect(
      resolveTrackedValue({
        currentValue: "manual-requester",
        nextHint: "smoke-admin",
        previousHint: "smoke-user"
      })
    ).toBe("manual-requester");
  });
});
