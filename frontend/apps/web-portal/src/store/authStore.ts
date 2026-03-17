import { create } from 'zustand';

export interface AuthState {
  accessToken: string;
  memberId: string;
  memberName: string;
  roles: string[];
}

interface AuthStore extends AuthState {
  setAuth: (token: string, memberId: string, memberName: string, roles: string[]) => void;
  clearAuth: () => void;
  isAuthenticated: () => boolean;
}

const STORAGE_KEY = 'scm-rft.auth';

function loadFromStorage(): AuthState {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as AuthState;
  } catch { /* ignore */ }
  return { accessToken: '', memberId: '', memberName: '', roles: [] };
}

export const useAuthStore = create<AuthStore>((set, get) => ({
  ...loadFromStorage(),

  setAuth: (accessToken, memberId, memberName, roles) => {
    const state = { accessToken, memberId, memberName, roles };
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    set(state);
  },

  clearAuth: () => {
    sessionStorage.removeItem(STORAGE_KEY);
    set({ accessToken: '', memberId: '', memberName: '', roles: [] });
  },

  isAuthenticated: () => Boolean(get().accessToken),
}));
