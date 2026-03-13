import { describe, expect, it } from "vitest";
import { buildRunbookReferences, pickScenarioMemberId } from "./cutover-runner-panel";

describe("pickScenarioMemberId", () => {
  it("uses the hinted member when present", () => {
    expect(pickScenarioMemberId("smoke-admin")).toBe("smoke-admin");
  });

  it("falls back to smoke-user when no hint exists", () => {
    expect(pickScenarioMemberId("")).toBe("smoke-user");
  });
});

describe("buildRunbookReferences", () => {
  it("keeps the cutover reference list stable", () => {
    expect(buildRunbookReferences()).toContain("runbooks/go-nogo-signoff.md");
    expect(buildRunbookReferences()).toContain("doc/roadmap/scm-201-p0-scenarios.md");
  });
});
