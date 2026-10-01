import { FormEvent, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth, dashboardPathFor, OtpChallenge } from '../lib/auth';
import { isEmail, isValidMobile, apiErrorMessage } from '../lib/validation';
import { Button, TextField, PasswordField, ErrorAlert } from '../components/ui';
import { OtpBoxes, ResendTimer } from '../components/OtpInput';

// 99acres-style login: mobile + OTP is the primary tab, email + password secondary.
export function LoginPage() {
  const nav = useNavigate();
  const loc = useLocation() as { state?: { from?: string } };
  const { session, login, requestOtp, verifyOtp, loginWithOtp } = useAuth();

  const [tab, setTab] = useState<'otp' | 'email'>('otp');

  // Email tab state
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [remember, setRemember] = useState(true);
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});
  const [showForgot, setShowForgot] = useState(false);

  // OTP tab state
  const [phone, setPhone] = useState('');
  const [phoneError, setPhoneError] = useState('');
  const [challenge, setChallenge] = useState<OtpChallenge | null>(null);
  const [code, setCode] = useState('');
  const [cooldownUntil, setCooldownUntil] = useState(0);

  const [serverError, setServerError] = useState('');
  const [pending, setPending] = useState(false);

  if (session) {
    nav(dashboardPathFor(session), { replace: true });
    return null;
  }

  const done = (s: { email: string; userType: string; roles: string[] }) =>
    nav(loc.state?.from ?? dashboardPathFor(s), { replace: true });

  const submitEmail = async (e: FormEvent) => {
    e.preventDefault();
    if (pending) return;
    const errs: typeof errors = {};
    if (!isEmail(email)) errs.email = 'Enter a valid email address.';
    if (!password) errs.password = 'Enter your password.';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    setPending(true);
    setServerError('');
    try {
      done(await login(email, password, remember));
    } catch (err) {
      setServerError(apiErrorMessage(err, 'Login failed. Please try again.'));
    } finally {
      setPending(false);
    }
  };

  const sendOtp = async () => {
    if (pending) return;
    if (!isValidMobile(phone)) {
      setPhoneError('Enter a valid 8–15 digit mobile number (e.g. +91 98765 43210).');
      return;
    }
    setPhoneError('');
    setPending(true);
    setServerError('');
    try {
      const c = await requestOtp(phone);
      setChallenge(c);
      setCode('');
      setCooldownUntil(Date.now() + 60_000);
    } catch (err) {
      setServerError(apiErrorMessage(err, 'Could not send the code. Please try again.'));
    } finally {
      setPending(false);
    }
  };

  const submitOtp = async (e: FormEvent) => {
    e.preventDefault();
    if (pending || !challenge) return;
    if (code.length !== 6) {
      setServerError('Enter the 6-digit code sent to your mobile.');
      return;
    }
    setPending(true);
    setServerError('');
    try {
      const v = await verifyOtp(challenge.phone, code);
      if (v.isNewUser) {
        nav('/register', { state: { phone: challenge.phone, otpToken: v.otpToken } });
        return;
      }
      done(await loginWithOtp(v.otpToken, remember));
    } catch (err) {
      setServerError(apiErrorMessage(err, 'Verification failed. Please try again.'));
    } finally {
      setPending(false);
    }
  };

  return (
    <div className="mx-auto max-w-md px-4 py-10 sm:px-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 sm:p-8">
        <h1 className="text-2xl font-extrabold">Welcome back</h1>
        <p className="mt-1 text-sm text-slate-500">Log in to search, save and manage properties.</p>

        <div className="mt-5 grid grid-cols-2 gap-1 rounded-xl bg-slate-100 p-1 dark:bg-slate-800" role="tablist" aria-label="Login method">
          {(['otp', 'email'] as const).map((t) => (
            <button
              key={t} type="button" role="tab" aria-selected={tab === t}
              onClick={() => { setTab(t); setServerError(''); }}
              className={`rounded-lg px-3 py-2 text-sm font-semibold ${tab === t ? 'bg-white shadow dark:bg-slate-900' : 'text-slate-500'}`}
            >
              {t === 'otp' ? 'Mobile OTP' : 'Email'}
            </button>
          ))}
        </div>

        {tab === 'otp' ? (
          challenge ? (
            <form onSubmit={submitOtp} className="mt-6 space-y-4">
              {serverError && <ErrorAlert message={serverError} />}
              <p className="text-sm text-slate-600 dark:text-slate-300">
                Code sent to <span className="font-bold">{challenge.maskedPhone}</span>{' '}
                <button type="button" onClick={() => { setChallenge(null); setCode(''); }} className="font-semibold text-brand-700 hover:underline">Change</button>
              </p>
              <OtpBoxes value={code} onChange={setCode} disabled={pending} />
              {challenge.devCode && (
                <p className="rounded-lg bg-amber-50 p-2 text-center text-sm text-amber-800 dark:bg-amber-950 dark:text-amber-200">
                  Dev mode — your code is <span className="font-mono font-bold">{challenge.devCode}</span>
                </p>
              )}
              <div className="flex items-center justify-between">
                <ResendTimer cooldownUntil={cooldownUntil} pending={pending} onResend={sendOtp} />
                <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-600 dark:text-slate-300">
                  <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} className="h-4 w-4 accent-emerald-700" />
                  Remember me
                </label>
              </div>
              <Button type="submit" loading={pending} className="w-full">Verify & log in</Button>
            </form>
          ) : (
            <form onSubmit={(e) => { e.preventDefault(); void sendOtp(); }} noValidate className="mt-6 space-y-4">
              {serverError && <ErrorAlert message={serverError} />}
              <TextField label="Mobile number" type="tel" autoComplete="tel" placeholder="+91 98765 43210" value={phone} onChange={(e) => setPhone(e.target.value)} error={phoneError} />
              <Button type="submit" loading={pending} className="w-full">Send OTP</Button>
              <p className="text-center text-xs text-slate-500">New number? We'll create your account after verification.</p>
            </form>
          )
        ) : (
          <form onSubmit={submitEmail} noValidate className="mt-6 space-y-4">
            {serverError && <ErrorAlert message={serverError} />}
            <TextField label="Email" type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} error={errors.email} />
            <PasswordField label="Password" autoComplete="current-password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} error={errors.password} />
            <div className="flex items-center justify-between text-sm">
              <label className="flex cursor-pointer items-center gap-2 text-slate-600 dark:text-slate-300">
                <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} className="h-4 w-4 accent-emerald-700" />
                Remember me
              </label>
              <button type="button" onClick={() => setShowForgot(true)} className="font-semibold text-brand-700 hover:underline dark:text-brand-300">Forgot password?</button>
            </div>
            <Button type="submit" loading={pending} className="w-full">Log in</Button>
          </form>
        )}

        <p className="mt-5 text-center text-sm text-slate-500">
          New here? <Link to="/register" className="font-semibold text-brand-700 hover:underline dark:text-brand-300">Create an account</Link>
        </p>
      </div>

      {showForgot && (
        <div role="dialog" aria-modal aria-label="Forgot password" className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" onClick={() => setShowForgot(false)}>
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 dark:bg-slate-900" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-bold">Reset your password</h2>
            <p className="mt-2 text-sm text-slate-500">
              Self-service password reset isn't available in this release. Please email{' '}
              <a href="mailto:support@buysellproperty.local" className="font-semibold text-brand-700">support@buysellproperty.local</a>{' '}
              from your registered email address and we'll help you recover your account.
            </p>
            <Button className="mt-4 w-full" onClick={() => setShowForgot(false)}>Got it</Button>
          </div>
        </div>
      )}
    </div>
  );
}
