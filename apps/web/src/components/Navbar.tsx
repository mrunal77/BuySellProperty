import { useState } from 'react';
import { Link, NavLink, useNavigate } from 'react-router-dom';
import { useAuth, LISTER_TYPES } from '../lib/auth';
import { ThemeToggle } from './ThemeToggle';

function linkCls(active: boolean) {
  return `rounded-lg px-3 py-2 text-sm font-medium ${active ? 'bg-brand-50 text-brand-700 dark:bg-slate-800 dark:text-brand-300' : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800'}`;
}

export function Navbar() {
  const { session, logout } = useAuth();
  const nav = useNavigate();
  const [open, setOpen] = useState(false);
  const isLister = !!session && (LISTER_TYPES.includes(session.userType) || session.roles.some((r) => LISTER_TYPES.includes(r)));

  const goLogin = () => { setOpen(false); nav('/login'); };

  return (
    <header className="sticky top-0 z-40 border-b border-slate-200 bg-white/90 backdrop-blur dark:border-slate-800 dark:bg-slate-950/90">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-2 px-4 sm:px-6">
        <Link to="/" className="flex items-center gap-2 text-lg font-extrabold tracking-tight">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-600 text-white">B</span>
          <span>BuySell<span className="text-brand-600 dark:text-brand-400">Property</span></span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex" aria-label="Primary">
          <NavLink to="/" className={({ isActive }) => linkCls(isActive)}>Home</NavLink>
          <NavLink to="/search" className={({ isActive }) => linkCls(isActive)}>Buy</NavLink>
          <NavLink to="/search?listingType=Rent" className={() => linkCls(false)}>Rent</NavLink>
          {isLister && <NavLink to="/dashboard" className={({ isActive }) => linkCls(isActive)}>Dashboard</NavLink>}
          {session?.roles.includes('Admin') && <NavLink to="/admin" className={({ isActive }) => linkCls(isActive)}>Admin</NavLink>}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          <ThemeToggle />
          {session ? (
            <>
              <span className="max-w-[140px] truncate text-sm text-slate-500" title={session.email}>{session.email}</span>
              <button onClick={() => { void logout().then(() => nav('/')); }} className="rounded-lg border border-slate-300 px-3 py-2 text-sm font-semibold hover:bg-slate-100 dark:border-slate-700 dark:hover:bg-slate-800">Logout</button>
            </>
          ) : (
            <>
              <button onClick={goLogin} className="rounded-lg px-3 py-2 text-sm font-semibold text-brand-700 hover:bg-brand-50 dark:text-brand-300 dark:hover:bg-slate-800">Log in</button>
              <Link to="/register" className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700">Post property <span className="font-normal opacity-80">FREE</span></Link>
            </>
          )}
        </div>

        <div className="flex items-center gap-2 md:hidden">
          <ThemeToggle />
          <button onClick={() => setOpen((o) => !o)} aria-label="Toggle menu" aria-expanded={open} className="rounded-lg border border-slate-300 p-2 dark:border-slate-700">☰</button>
        </div>
      </div>

      {open && (
        <nav className="border-t border-slate-200 px-4 py-3 dark:border-slate-800 md:hidden" aria-label="Mobile">
          <div className="flex flex-col gap-1">
            {[
              { to: '/', label: 'Home' },
              { to: '/search', label: 'Buy' },
              { to: '/search?listingType=Rent', label: 'Rent' },
              ...(isLister ? [{ to: '/dashboard', label: 'Dashboard' }] : []),
            ].map((l) => (
              <Link key={l.to + l.label} to={l.to} onClick={() => setOpen(false)} className="rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-slate-100 dark:hover:bg-slate-800">{l.label}</Link>
            ))}
            <Link to="/register" onClick={() => setOpen(false)} className="mt-1 rounded-lg bg-brand-600 px-3 py-2.5 text-center text-sm font-semibold text-white">Post property FREE</Link>
            {session ? (
              <button onClick={() => { setOpen(false); void logout().then(() => nav('/')); }} className="rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-semibold dark:border-slate-700">Logout ({session.email})</button>
            ) : (
              <button onClick={goLogin} className="rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-semibold dark:border-slate-700">Log in</button>
            )}
          </div>
        </nav>
      )}
    </header>
  );
}
