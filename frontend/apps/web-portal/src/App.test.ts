import { describe, expect, it } from "vitest";
import { formatPortalTitle } from "./App";
import { formatApiError, ApiError } from "@scm-rft/api-client";

describe("formatPortalTitle", () => {
  it("appends scope text", () => {
    expect(formatPortalTitle("scm-rft")).toBe("SCM Web Portal (scm-rft)");
  });
});

describe("formatApiError", () => {
  it("includes backend error code when available", () => {
    const error = new ApiError(401, { message: "Invalid credentials", code: "AUTH_INVALID" });
    expect(formatApiError(error)).toBe("Invalid credentials [AUTH_INVALID]");
  });
});
