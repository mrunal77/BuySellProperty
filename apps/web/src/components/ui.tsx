import { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes, useState } from 'react';
import { passwordStrength } from '../lib/validation';

// ---------- Button ----------
type BtnProps = ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'secondary' | 'ghost'; loading?: boolean };
export function Button({ variant = 'primary', loading, children, className = '', disabled, ...rest }: BtnProps) {
  const base = 'inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold transition focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 disabled:cursor-not-allowed disabled:opacity-60';
  const styles = {
    primary: 'bg-brand-600 text-white hover:bg-brand-700 dark:bg-brand-500 dark:hover:bg-brand-400 dark:text-slate-950',
    secondary: 'border border-slate-300 bg-white text-slate-800 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:hover:bg-slate-800',
    ghost: 'text-brand-700 hover:bg-brand-50 dark:text-brand-300 dark:hover:bg-slate-800',
  }[variant];
  return (
    <button className={`${base} ${styles} ${className}`} disabled={disabled || loading} {...rest}>
      {loading && <Spinner className="h-4 w-4" />}
      {children}
    </button>
  );
}

// ---------- Spinner ----------
export function Spinner({ className = 'h-5 w-5' }: { className?: string }) {
  return (
    <svg className={`animate-spin ${className}`} viewBox="0 0 24 24" fill="none" aria-hidden>
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path className="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
    </svg>
  );
}

// ---------- TextField ----------
type FieldProps = InputHTMLAttributes<HTMLInputElement> & { label: string; error?: string; hint?: string };
export function TextField({ label, error, hint, id, className = '', ...rest }: FieldProps) {
  const inputId = id ?? `f-${label.replace(/\W+/g, '-').toLowerCase()}`;
  return (
    <div className={className}>
      <label htmlFor={inputId} className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">{label}</label>
      <input
        id={inputId}
        aria-invalid={!!error}
        className={`w-full rounded-lg border bg-white px-3 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 dark:bg-slate-900 dark:text-slate-100 ${
          error ? 'border-red-500 focus:ring-red-200' : 'border-slate-300 focus:border-brand-500 focus:ring-brand-100 dark:border-slate-700 dark:focus:border-brand-400'
        }`}
        {...rest}
      />
      {error ? <p role="alert" className="mt-1 text-xs text-red-600 dark:text-red-400">{error}</p>
        : hint ? <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{hint}</p> : null}
    </div>
  );
}

// ---------- PasswordField (show/hide) ----------
export function PasswordField(props: FieldProps) {
  const [show, setShow] = useState(false);
  return (
    <div className="relative">
      <TextField {...props} type={show ? 'text' : 'password'} className={props.className} />
      <button
        type="button"
        aria-label={show ? 'Hide password' : 'Show password'}
        onClick={() => setShow((s) => !s)}
        className="absolute right-2 top-[30px] rounded p-1 text-xs font-semibold text-slate-500 hover:text-brand-600 dark:text-slate-400"
      >
        {show ? 'HIDE' : 'SHOW'}
      </button>
    </div>
  );
}

// ---------- Select ----------
type SelectProps = SelectHTMLAttributes<HTMLSelectElement> & { label: string; error?: string };
export function Select({ label, error, id, children, className = '', ...rest }: SelectProps) {
  const inputId = id ?? `s-${label.replace(/\W+/g, '-').toLowerCase()}`;
  return (
    <div className={className}>
      <label htmlFor={inputId} className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">{label}</label>
      <select
        id={inputId}
        className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm dark:border-slate-700 dark:bg-slate-900"
        {...rest}
      >
        {children}
      </select>
      {error && <p role="alert" className="mt-1 text-xs text-red-600">{error}</p>}
    </div>
  );
}

// ---------- ErrorAlert ----------
export function ErrorAlert({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div role="alert" className="flex items-start justify-between gap-3 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800 dark:border-red-900 dark:bg-red-950 dark:text-red-200">
      <span>{message}</span>
      {onRetry && <button onClick={onRetry} className="shrink-0 font-semibold underline">Retry</button>}
    </div>
  );
}

// ---------- Badge ----------
export function Badge({ children, tone = 'green' }: { children: ReactNode; tone?: 'green' | 'blue' | 'amber' | 'slate' }) {
  const tones = {
    green: 'bg-brand-50 text-brand-700 dark:bg-brand-900/40 dark:text-brand-300',
    blue: 'bg-blue-50 text-blue-700 dark:bg-blue-950 dark:text-blue-300',
    amber: 'bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300',
    slate: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
  }[tone];
  return <span className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold ${tones}`}>{children}</span>;
}

// ---------- SectionHeading ----------
export function SectionHeading({ kicker, title, sub, action }: { kicker?: string; title: string; sub?: string; action?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        {kicker && <p className="text-xs font-bold uppercase tracking-widest text-brand-600 dark:text-brand-400">{kicker}</p>}
        <h2 className="mt-1 text-2xl font-bold sm:text-3xl">{title}</h2>
        {sub && <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{sub}</p>}
      </div>
      {action}
    </div>
  );
}

// ---------- EmptyState ----------
export function EmptyState({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="rounded-xl border border-dashed border-slate-300 p-10 text-center dark:border-slate-700">
      <p className="font-semibold">{title}</p>
      {sub && <p className="mt-1 text-sm text-slate-500">{sub}</p>}
    </div>
  );
}

// ---------- PasswordStrength ----------
export function PasswordStrength({ password }: { password: string }) {
  if (!password) return null;
  const { score, label } = passwordStrength(password);
  const colors = ['bg-red-500', 'bg-orange-500', 'bg-yellow-500', 'bg-lime-500', 'bg-green-600'];
  return (
    <div className="mt-2">
      <div className="flex gap-1" aria-hidden>
        {[0, 1, 2, 3].map((i) => (
          <div key={i} className={`h-1.5 flex-1 rounded ${i < score ? colors[score] : 'bg-slate-200 dark:bg-slate-700'}`} />
        ))}
      </div>
      <p className="mt-1 text-xs text-slate-500">Strength: <span className="font-semibold">{label}</span> — use 8+ chars with upper/lower case, a number and a symbol.</p>
    </div>
  );
}
