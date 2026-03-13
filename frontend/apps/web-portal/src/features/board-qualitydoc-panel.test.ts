import { describe, expect, it } from "vitest";
import { parseAttachmentRefs, resolveTrackedValue } from "./board-qualitydoc-panel";

describe("resolveTrackedValue", () => {
  it("tracks the latest member hint when the field still mirrors the previous hint", () => {
    expect(
      resolveTrackedValue({
        currentValue: "member-a",
        nextHint: "member-b",
        previousHint: "member-a"
      })
    ).toBe("member-b");
  });

  it("preserves manual overrides", () => {
    expect(
      resolveTrackedValue({
        currentValue: "manual-auditor",
        nextHint: "member-b",
        previousHint: "member-a"
      })
    ).toBe("manual-auditor");
  });
});

describe("parseAttachmentRefs", () => {
  it("parses one file id per line with optional names", () => {
    expect(parseAttachmentRefs("11111111-1111-1111-1111-111111111111\n222|evidence.txt")).toEqual([
      { fileId: "11111111-1111-1111-1111-111111111111" },
      { fileId: "222", fileName: "evidence.txt" }
    ]);
  });

  it("ignores blank lines", () => {
    expect(parseAttachmentRefs("\n \n")).toEqual([]);
  });
});
