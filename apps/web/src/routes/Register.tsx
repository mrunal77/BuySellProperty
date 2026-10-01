import { FormEvent, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth, dashboardPathFor } from '../lib/auth';
import { isEmail, isPhone, isValidMobile, passwordStrength, apiErrorMessage } from '../lib/validation';
import { Button, TextField, PasswordField, PasswordStrength, Select, ErrorAlert, Badge } from '../components/ui';

const TYPES = ['Customer', 'Owner', 'Agent', 'Builder'];

type OtpState = { phone?: string; otpToken?: string };

export function RegisterPage() {
  const nav = useNavigate();
  const loc = useLocation() as { state?: OtpState };
  const { session, register, registerWithOtp, requestOtp, verifyOtp } = useAuth();

  // 99acres-style: arriving from OTP login with an unverified number carries a token.
  const [verifiedPhone, setVerifiedPhone] = useState(loc.state?.phone ?? '');
  const [otpToken, setOtpToken] = useState(loc.state?.otpToken ?? '');

  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState(loc.state?.phone ?? '');
  const [userType, setUserType] = useState('Customer');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [terms, setTerms] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [serverError, setServerError] = useState('');
  const [pending, setPending] = useState(false);

  // Inline phone verification for direct (non-OTP) arrivals.
  const [code, setCode] = useState('');
  const [codeSent, setCodeSent] = useState(false);
  const [devCode, setDevCode] = useState<string | undefined>();

  if (session) {
    nav(dashboardPathFor(session), { replace: true });
    return null;
  }

  const phoneVerified = verifiedPhone !== '' && verifiedPhone === phone;

  const sendCode = async () => {
    if (pending || !isValidMobile(phone)) {
      setErrors((e) => ({ ...e, phone: 'Enter a valid mobile number first.' }));
      return;
    }
    setPending(true);
    setServerError('');
    try {
      const c = await requestOtp(phone);
      setCodeSent(true);
      setDevCode(c.devCode);
    } catch (err) {
      setServerError(apiErrorMessage(err, 'Could not send the code.'));
    } finally {
      setPending(false);
    }
  };

  const verifyCode = async () => {
    if (pending || code.length !== 6) return;
    setPending(true);
    setServerError('');
    try {
      const v = await verifyOtp(phone, code);
      if (v.isNewUser) {
        setVerifiedPhone(phone);
        setOtpToken(v.otpToken);
      } else {
        setServerError('This number is already registered. Please log in with OTP instead.');
      }
    } catch (err) {
      setServerError(apiErrorMessage(err, 'Verification failed.'));
    } finally {
      setPending(false);
    }
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (pending) return;
    const errs: Record<string, string> = {};
    if (!isEmail(email)) errs.email = 'Enter a valid email address.';
    if (phone && !isPhone(phone)) errs.phone = 'Enter a valid phone number (digits, +, spaces).';
    if (passwordStrength(password).score < 2) errs.password = 'Choose a stronger password (8+ chars, mixed case, number, symbol).';
    if (confirm !== password) errs.confirm = 'Passwords do not match.';
    if (!terms) errs.terms = 'Please accept the Terms & Privacy Policy.';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    setPending(true);
    setServerError('');
    try {
      const s = phoneVerified
        ? await registerWithOtp({ otpToken, phone, email, password, userType })
        : await register({ email, password, userType, phone: phone || undefined });
      nav(dashboardPathFor(s), { replace: true });
    } catch (err) {
      setServerError(apiErrorMessage(err, 'Registration failed. Please try again.'));
    } finally {
      setPending(false);
    }
  };

  return (
    <div className="mx-auto max-w-md px-4 py-10 sm:px-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900 sm:p-8">
        <h1 className="text-2xl font-extrabold">Create your account</h1>
        <p className="mt-1 text-sm text-slate-500">Buy, sell, rent — or list your property for free.</p>

        <form onSubmit={submit} noValidate className="mt-6 space-y-4">
          {serverError && <ErrorAlert message={serverError} />}
          <TextField label="Email" type="email" autoComplete="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} error={errors.email} />

          <div>
            <TextField
              label="Mobile" type="tel" autoComplete="tel" placeholder="+91 98765 43210"
              value={phone} onChange={(e) => { setPhone(e.target.value); setCodeSent(false); }}
              error={errors.phone}
              hint={phoneVerified ? undefined : 'Verify your number with OTP — like 99acres, it keeps enquiries genuine.'}
            />
            {phoneVerified ? (
              <p className="mt-2"><Badge tone="green">✓ Mobile verified</Badge></p>
            ) : (
              <div className="mt-2">
                {!codeSent ? (
                  <button type="button" disabled={pending} onClick={sendCode} className="text-sm font-semibold text-brand-700 hover:underline disabled:opacity-60">Verify via OTP</button>
                ) : (
                  <div className="flex gap-2">
                    <input
                      value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                      inputMode="numeric" placeholder="6-digit code" aria-label="6-digit code"
                      className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm tracking-widest dark:border-slate-700 dark:bg-slate-900"
                    />
                    <Button type="button" loading={pending} onClick={verifyCode}>Verify</Button>
                  </div>
                )}
                {devCode && <p className="mt-1 text-xs text-amber-700">Dev mode — your code is <span className="font-mono font-bold">{devCode}</span></p>}
              </div>
            )}
          </div>

          <Select label="I am a" value={userType} onChange={(e) => setUserType(e.target.value)}>
            {TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </Select>
          <div>
            <PasswordField label="Password" autoComplete="new-password" placeholder="Min. 8 characters" value={password} onChange={(e) => setPassword(e.target.value)} error={errors.password} />
            <PasswordStrength password={password} />
          </div>
          <PasswordField label="Confirm password" autoComplete="new-password" placeholder="Repeat your password" value={confirm} onChange={(e) => setConfirm(e.target.value)} error={errors.confirm} />

          <label className="flex cursor-pointer items-start gap-2 text-sm text-slate-600 dark:text-slate-300">
            <input type="checkbox" checked={terms} onChange={(e) => setTerms(e.target.checked)} className="mt-0.5 h-4 w-4 accent-emerald-700" />
            <span>I accept the <span className="font-semibold">Terms of Use</span> and <span className="font-semibold">Privacy Policy</span>.</span>
          </label>
          {errors.terms && <p role="alert" className="-mt-2 text-xs text-red-600">{errors.terms}</p>}

          <Button type="submit" loading={pending} className="w-full">Create account</Button>
        </form>

        <p className="mt-5 text-center text-sm text-slate-500">
          Already registered? <Link to="/login" className="font-semibold text-brand-700 hover:underline dark:text-brand-300">Log in</Link>
        </p>
      </div>
    </div>
  );
}
