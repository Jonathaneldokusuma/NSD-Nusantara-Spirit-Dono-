import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { api, post } from "../lib/api";
import type { Role, User } from "../types";

interface AuthContextValue {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<User>;
  register: (input: {
    name: string;
    email: string;
    phone: string;
    password: string;
    role: Extract<Role, "donatur" | "pemohon">;
  }) => Promise<User>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  async function refreshUser() {
    if (!localStorage.getItem("nsd_token")) {
      setLoading(false);
      return;
    }
    try {
      setUser(await api<User>("/auth/me"));
    } catch {
      localStorage.removeItem("nsd_token");
      setUser(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void refreshUser();
  }, []);

  async function login(email: string, password: string) {
    const result = await post<{ token: string; user: User }>("/auth/login", {
      email,
      password,
    });
    localStorage.setItem("nsd_token", result.token);
    setUser(result.user);
    return result.user;
  }

  async function register(input: {
    name: string;
    email: string;
    phone: string;
    password: string;
    role: Extract<Role, "donatur" | "pemohon">;
  }) {
    const result = await post<{ token: string; user: User }>(
      "/auth/register",
      input,
    );
    localStorage.setItem("nsd_token", result.token);
    setUser(result.user);
    return result.user;
  }

  function logout() {
    localStorage.removeItem("nsd_token");
    setUser(null);
  }

  const value = useMemo(
    () => ({ user, loading, login, register, logout, refreshUser }),
    [user, loading],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth harus digunakan di dalam AuthProvider.");
  return context;
}

