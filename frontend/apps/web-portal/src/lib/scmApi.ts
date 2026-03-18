import { useMemo } from "react";
import { createScmApiClient, formatApiError } from "@scm-rft/api-client";
import { useAuthStore } from "../store/authStore";

const apiBaseUrl = (import.meta as { env?: Record<string, string> }).env?.VITE_API_BASE_URL ?? "";

export function useScmApiClient() {
  const accessToken = useAuthStore((state) => state.accessToken);

  return useMemo(
    () =>
      createScmApiClient({
        baseUrl: apiBaseUrl,
        accessToken,
      }),
    [accessToken]
  );
}

export function useAuthIdentity() {
  const accessToken = useAuthStore((state) => state.accessToken);
  const memberId = useAuthStore((state) => state.memberId);
  const memberName = useAuthStore((state) => state.memberName);
  const roles = useAuthStore((state) => state.roles);

  return { accessToken, memberId, memberName, roles };
}

export function formatDateTime(value?: string | null) {
  if (!value) {
    return "-";
  }

  const normalized = value.replace("T", " ");
  return normalized.length > 16 ? normalized.slice(0, 16) : normalized;
}

export function formatCount(value?: number | null) {
  if (value === null || value === undefined) {
    return "-";
  }
  return value.toLocaleString("ko-KR");
}

export function formatErrorText(error: unknown) {
  return formatApiError(error);
}
