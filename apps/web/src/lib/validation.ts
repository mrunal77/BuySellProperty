// Shared form validation (mirrors backend rules + UX helpers).

export function isEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v.trim());
}

export function isPhone(v: string): boolean {
  return /^[+0-9][0-9\s-]{5,17}$/.test(v.trim());
}

/// Canonical mobile form: optional leading '+', then 8..15 digits.
/// Mirrors backend PhoneNumber.Normalize (strips spaces/dashes/parens first).
export function normalizeMobile(v: string): string {
  return v.trim().replace(/[\s\-()]/g, '');
}

export function isValidMobile(v: string): boolean {
  return /^\+?[1-9]\d{7,14}$/.test(normalizeMobile(v));
}

export type Strength = { score: 0 | 1 | 2 | 3 | 4; label: string; checks: boolean[] };

export function passwordStrength(pw: string): Strength {
  const checks = [
    pw.length >= 8,
    /[a-z]/.test(pw) && /[A-Z]/.test(pw),
    /\d/.test(pw),
    /[^a-zA-Z0-9]/.test(pw),
  ];
  const score = checks.filter(Boolean).length as Strength['score'];
  const label = ['Too weak', 'Weak', 'Okay', 'Good', 'Strong'][score];
  return { score, label, checks };
}

export function apiErrorMessage(err: unknown, fallback: string): string {
  const e = err as { response?: { status?: number; data?: { error?: { code?: string; message?: string } } }; message?: string };
  const code = e?.response?.data?.error?.code;
  const msg = e?.response?.data?.error?.message;
  if (e?.response?.status === 0 || e?.message === 'Network Error') {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  if (code === 'auth.email_taken') return 'This email is already registered. Try logging in instead.';
  if (code === 'auth.phone_taken') return 'This mobile number is already registered. Try logging in with OTP.';
  if (code === 'auth.invalid_credentials') return 'Incorrect email or password.';
  if (code === 'auth.invalid_refresh') return 'Your session expired. Please log in again.';
  if (code === 'auth.invalid_otp') return msg ?? 'Invalid or expired code. Please try again.';
  if (code === 'auth.invalid_phone') return 'Enter a valid mobile number.';
  if (code === 'auth.otp_cooldown' || code === 'auth.phone_mismatch') return msg ?? fallback;
  if (msg) return msg;
  return fallback;
}

export function formatINR(n: number): string {
  if (n >= 1e7) return `₹${(n / 1e7).toFixed(n % 1e7 === 0 ? 0 : 2)} Cr`;
  if (n >= 1e5) return `₹${(n / 1e5).toFixed(n % 1e5 === 0 ? 0 : 2)} L`;
  return `₹${n.toLocaleString('en-IN')}`;
}
