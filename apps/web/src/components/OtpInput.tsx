import { useEffect, useRef, useState } from 'react';

// Six-box OTP entry with auto-advance, backspace navigation and paste support,
// plus a resend countdown. Modelled on the 99acres mobile verification flow.
export function OtpBoxes({ value, onChange, disabled }: { value: string; onChange: (v: string) => void; disabled?: boolean }) {
  const refs = useRef<(HTMLInputElement | null)[]>([]);
  const digits = Array.from({ length: 6 }, (_, i) => value[i] ?? '');

  const setAt = (i: number, d: string) => {
    const next = value.split('');
    while (next.length < 6) next.push('');
    next[i] = d;
    onChange(next.join('').slice(0, 6));
  };

  return (
    <div className="flex gap-2" role="group" aria-label="6-digit verification code">
      {digits.map((d, i) => (
        <input
          key={i}
          ref={(el) => { refs.current[i] = el; }}
          value={d}
          disabled={disabled}
          inputMode="numeric"
          autoComplete={i === 0 ? 'one-time-code' : 'off'}
          aria-label={`Digit ${i + 1}`}
          maxLength={1}
          onChange={(e) => {
            const ch = e.target.value.replace(/\D/g, '').slice(-1);
            setAt(i, ch);
            if (ch && i < 5) refs.current[i + 1]?.focus();
          }}
          onKeyDown={(e) => {
            if (e.key === 'Backspace' && !d && i > 0) refs.current[i - 1]?.focus();
          }}
          onPaste={(e) => {
            e.preventDefault();
            const text = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
            if (text) {
              onChange(text);
              refs.current[Math.min(text.length, 5)]?.focus();
            }
          }}
          className="h-12 w-full rounded-lg border border-slate-300 text-center text-lg font-bold focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-100 disabled:opacity-60 dark:border-slate-700 dark:bg-slate-900"
        />
      ))}
    </div>
  );
}

export function ResendTimer({ cooldownUntil, onResend, pending }: { cooldownUntil: number; onResend: () => void; pending: boolean }) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    if (Date.now() >= cooldownUntil) return;
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, [cooldownUntil]);
  const left = Math.max(0, Math.ceil((cooldownUntil - now) / 1000));
  if (left > 0) return <p className="text-sm text-slate-500">Resend code in {left}s</p>;
  return (
    <button type="button" disabled={pending} onClick={onResend} className="text-sm font-semibold text-brand-700 hover:underline disabled:opacity-60 dark:text-brand-300">
      {pending ? 'Sending…' : 'Resend code'}
    </button>
  );
}
