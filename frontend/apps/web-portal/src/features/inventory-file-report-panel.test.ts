import { describe, expect, it } from "vitest";
import { resolveTrackedValue } from "./inventory-file-report-panel";

describe("inventory/report tracked value", () => {
  it("clears the tracked requester when the login hint is removed", () => {
    expect(
      resolveTrackedValue({
        currentValue: "manual-requester",
        nextHint: "",
        previousHint: "smoke-user"
      })
    ).toBe("");
  });

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

  it("tracks the next login after a logout reset", () => {
    const clearedValue = resolveTrackedValue({
      currentValue: "smoke-user",
      nextHint: "",
      previousHint: "smoke-user"
    });

    expect(
      resolveTrackedValue({
        currentValue: clearedValue,
        nextHint: "smoke-admin",
        previousHint: ""
      })
    ).toBe("smoke-admin");
  });
});
