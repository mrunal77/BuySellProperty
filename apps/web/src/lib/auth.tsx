import { createContext, useContext, useCallback, useState, ReactNode } from 'react';
import { api } from './api';
import { tokenStore } from './storage';

export type UserType = 'Customer' | 'Owner' | 'Agent' | 'Builder' | 'Admin';
export type Session = { email: string; userType: string; roles: string[] };

export type OtpChallenge = { phone: string; maskedPhone: string; expiresInSeconds: number; devCode?: string };
export type OtpVerification = { otpToken: string; isNewUser: boolean; maskedPhone: string };

type AuthCtx = {
  session: Session | null;
  login: (email: string, password: string, remember: boolean) => Promise<Session>;
  register: (input: { email: string; password: string; userType: string; phone?: string }) => Promise<Session>;
  logout: () => Promise<void>;
  requestOtp: (phone: string) => Promise<OtpChallenge>;
  verifyOtp: (phone: string, code: string) => Promise<OtpVerification>;
  loginWithOtp: (otpToken: string, remember: boolean) => Promise<Session>;
  registerWithOtp: (input: { otpToken: string; phone: string; email: string; password: string; userType: string }) => Promise<Session>;
};

const Ctx = createContext<AuthCtx | null>(null);

function readSession(): Session | null {
  const email = tokenStore.read('email');
  if (!email || !tokenStore.read('access')) return null;
  return {
    email,
    userType: tokenStore.read('userType') ?? 'Customer',
    roles: JSON.parse(tokenStore.read('roles') ?? '[]'),
  };
}

function persist(data: { email: string; userType: string; roles: string[]; accessToken: string; refreshToken: string }, remember: boolean) {
  tokenStore.write(
    {
      access: data.accessToken,
      refresh: data.refreshToken,
      email: data.email,
      userType: data.userType,
      roles: JSON.stringify(data.roles ?? []),
    },
    remember,
  );
  return { email: data.email, userType: data.userType, roles: data.roles ?? [] };
}

export const LISTER_TYPES = ['Owner', 'Agent', 'Builder'];

export function dashboardPathFor(s: Session): string {
  if (s.userType === 'Admin' || s.roles.includes('Admin')) return '/admin';
  if (LISTER_TYPES.includes(s.userType) || s.roles.some((r) => LISTER_TYPES.includes(r))) return '/dashboard';
  return '/';
}

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [session, setSession] = useState<Session | null>(readSession);

  const login = useCallback(async (email: string, password: string, remember: boolean) => {
    const { data } = await api.post('/api/v1/auth/login', { email: email.trim(), password });
    const s = persist(data, remember);
    setSession(s);
    return s;
  }, []);

  const register = useCallback(async (input: { email: string; password: string; userType: string; phone?: string }) => {
    const { data } = await api.post('/api/v1/auth/register', {
      email: input.email.trim(),
      password: input.password,
      userType: input.userType,
      phone: input.phone?.trim() || undefined,
    });
    const s = persist(data, true);
    setSession(s);
    return s;
  }, []);

  const logout = useCallback(async () => {
    const rt = tokenStore.read('refresh');
    if (rt) {
      try {
        await api.post('/api/v1/auth/logout', { refreshToken: rt });
      } catch { /* logout is best-effort */ }
    }
    tokenStore.clear();
    setSession(null);
  }, []);

  const requestOtp = useCallback(async (phone: string) => {
    const { data } = await api.post('/api/v1/auth/otp/request', { phone: phone.trim() });
    return data as OtpChallenge;
  }, []);

  const verifyOtp = useCallback(async (phone: string, code: string) => {
    const { data } = await api.post('/api/v1/auth/otp/verify', { phone: phone.trim(), code: code.trim() });
    return data as OtpVerification;
  }, []);

  const loginWithOtp = useCallback(async (otpToken: string, remember: boolean) => {
    const { data } = await api.post('/api/v1/auth/otp/login', { otpToken });
    const s = persist(data, remember);
    setSession(s);
    return s;
  }, []);

  const registerWithOtp = useCallback(async (input: { otpToken: string; phone: string; email: string; password: string; userType: string }) => {
    const { data } = await api.post('/api/v1/auth/otp/register', {
      otpToken: input.otpToken,
      phone: input.phone.trim(),
      email: input.email.trim(),
      password: input.password,
      userType: input.userType,
    });
    const s = persist(data, true);
    setSession(s);
    return s;
  }, []);

  return <Ctx.Provider value={{ session, login, register, logout, requestOtp, verifyOtp, loginWithOtp, registerWithOtp }}>{children}</Ctx.Provider>;
};

export function useAuth(): AuthCtx {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
