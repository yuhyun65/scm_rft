import { describe, expect, it } from "vitest";
import { formatPortalTitle } from "./App";

describe("formatPortalTitle", () => {
  it("appends scope text", () => {
    expect(formatPortalTitle("scm-rft")).toBe("SCM Web Portal (scm-rft)");
  });
});
