import { Link } from 'react-router-dom';
import { useCities, useProperties } from '../features/properties/hooks';
import { SearchBar } from '../components/SearchBar';
import { PropertyCard } from '../components/PropertyCard';
import { SectionHeading, Button } from '../components/ui';

const POPULAR = [
  { name: 'Mumbai', note: 'Finance capital', grad: 'from-sky-600 to-indigo-800' },
  { name: 'Pune', note: 'IT & education hub', grad: 'from-emerald-600 to-teal-800' },
  { name: 'Bengaluru', note: 'Startup capital', grad: 'from-violet-600 to-purple-800' },
  { name: 'Delhi NCR', note: 'Coming soon', grad: 'from-amber-500 to-orange-700' },
];

const STEPS = [
  { t: 'Search & shortlist', d: 'Filter by city, budget, BHK and more across verified listings.' },
  { t: 'Visit & verify', d: 'Book site visits and chat directly with owners and agents.' },
  { t: 'Close with confidence', d: 'Clear pricing, documents and support till registration.' },
];

export function LandingPage() {
  const { data: cities = [] } = useCities();
  const featured = useProperties({ pageSize: 8 });

  return (
    <div>
      {/* HERO */}
      <section className="hero-grid-light text-white">
        <div className="mx-auto max-w-7xl px-4 pb-12 pt-12 sm:px-6 sm:pt-16">
          <p className="text-xs font-bold uppercase tracking-widest text-emerald-200">Buy • Rent • Commercial</p>
          <h1 className="mt-2 max-w-2xl text-3xl font-extrabold leading-tight sm:text-5xl">
            Find a place you'll love to live
          </h1>
          <p className="mt-3 max-w-xl text-sm text-emerald-50/90 sm:text-base">
            Search thousands of homes, plots and commercial spaces. Contact owners directly — no spam, no hassle.
          </p>
          <div className="mt-6 max-w-4xl text-slate-900 dark:text-slate-100">
            <SearchBar cities={cities} />
          </div>
          <div className="mt-4 flex flex-wrap gap-2 text-xs">
            {['2 BHK in Pune', 'Plots in Bengaluru', 'Rent in Mumbai'].map((s) => (
              <Link key={s} to="/search" className="rounded-full border border-white/30 px-3 py-1.5 text-white/90 hover:bg-white/10">{s}</Link>
            ))}
          </div>
        </div>
      </section>

      {/* FEATURED */}
      <section className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
        <SectionHeading
          kicker="Handpicked" title="Featured properties" sub="Fresh, owner-listed homes near you"
          action={<Link to="/search"><Button variant="secondary">View all</Button></Link>}
        />
        {featured.isLoading ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{[0, 1, 2, 3].map((i) => <div key={i} className="h-64 animate-pulse rounded-xl bg-slate-200 dark:bg-slate-800" />)}</div>
        ) : (featured.data?.data?.length ?? 0) === 0 ? (
          <div className="rounded-xl border border-dashed border-slate-300 p-10 text-center text-sm text-slate-500 dark:border-slate-700">
            No featured listings yet. <Link to="/register" className="font-semibold text-brand-600">Be the first to post yours — it's free.</Link>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {featured.data.data.slice(0, 8).map((p: Parameters<typeof PropertyCard>[0]['p']) => <PropertyCard key={p.id} p={p} />)}
          </div>
        )}
      </section>

      {/* POPULAR LOCATIONS */}
      <section className="border-y border-slate-200 bg-slate-50 py-12 dark:border-slate-800 dark:bg-slate-900/40">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <SectionHeading kicker="Explore" title="Popular locations" sub="High-demand neighbourhoods across India" />
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {POPULAR.map((l) => (
              <Link key={l.name} to="/search" className={`group overflow-hidden rounded-xl bg-gradient-to-br ${l.grad} p-5 text-white transition hover:-translate-y-0.5 hover:shadow-lg`}>
                <p className="text-xl font-extrabold">{l.name}</p>
                <p className="text-sm text-white/80">{l.note}</p>
                <p className="mt-4 text-sm font-semibold opacity-0 transition group-hover:opacity-100">Explore →</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
        <SectionHeading kicker="Simple" title="How it works" />
        <div className="grid gap-4 md:grid-cols-3">
          {STEPS.map((s, i) => (
            <div key={s.t} className="rounded-xl border border-slate-200 p-5 dark:border-slate-800 dark:bg-slate-900">
              <p className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-600 text-sm font-extrabold text-white">{i + 1}</p>
              <p className="mt-3 font-bold">{s.t}</p>
              <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{s.d}</p>
            </div>
          ))}
        </div>
      </section>

      {/* POST CTA */}
      <section className="mx-auto max-w-7xl px-4 pb-14 sm:px-6">
        <div className="hero-grid overflow-hidden rounded-2xl p-8 text-white sm:p-12">
          <div className="flex flex-col items-start justify-between gap-6 lg:flex-row lg:items-center">
            <div>
              <h2 className="text-2xl font-extrabold sm:text-3xl">Own a property? List it for FREE.</h2>
              <p className="mt-2 max-w-xl text-sm text-white/85">Reach thousands of genuine buyers and tenants. Owners, agents and builders welcome.</p>
            </div>
            <Link to="/register" className="shrink-0 rounded-xl bg-white px-6 py-3 text-sm font-bold text-brand-800 hover:bg-emerald-50">Post your property</Link>
          </div>
        </div>
      </section>
    </div>
  );
}
