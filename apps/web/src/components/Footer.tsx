import { Link } from 'react-router-dom';

const cols: { head: string; links: { to: string; label: string }[] }[] = [
  { head: 'Buy', links: [{ to: '/search', label: 'Apartments' }, { to: '/search', label: 'Villas' }, { to: '/search', label: 'Plots' }, { to: '/search?listingType=Rent', label: 'Rentals' }] },
  { head: 'Sell', links: [{ to: '/register', label: 'Post property' }, { to: '/dashboard', label: 'Owner dashboard' }, { to: '/login', label: 'Agent login' }] },
  { head: 'Company', links: [{ to: '/admin', label: 'Admin' }, { to: '/', label: 'About' }, { to: '/', label: 'Contact' }] },
];

export function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-slate-50 dark:border-slate-800 dark:bg-slate-900/50">
      <div className="mx-auto grid max-w-7xl gap-8 px-4 py-10 sm:grid-cols-2 sm:px-6 lg:grid-cols-4">
        <div>
          <p className="text-lg font-extrabold">BuySell<span className="text-brand-600">Property</span></p>
          <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">India's friendly property marketplace. Buy, rent, sell and manage listings in one place.</p>
        </div>
        {cols.map((c) => (
          <nav key={c.head} aria-label={c.head}>
            <p className="text-sm font-bold uppercase tracking-wider text-slate-500">{c.head}</p>
            <ul className="mt-3 space-y-2">
              {c.links.map((l) => (
                <li key={l.label}><Link to={l.to} className="text-sm text-slate-600 hover:text-brand-600 dark:text-slate-300">{l.label}</Link></li>
              ))}
            </ul>
          </nav>
        ))}
      </div>
      <div className="border-t border-slate-200 py-4 text-center text-xs text-slate-500 dark:border-slate-800">© 2026 BuySellProperty • Terms • Privacy</div>
    </footer>
  );
}
