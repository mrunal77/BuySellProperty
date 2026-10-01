import { FormEvent, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from './ui';

export type SearchFilters = {
  listingType: string; cityId: string; type: string; beds: string; maxPrice: string;
};

const BUDGETS = [
  { label: 'Any budget', value: '' },
  { label: 'Under ₹50 L', value: '5000000' },
  { label: 'Under ₹1 Cr', value: '10000000' },
  { label: 'Under ₹2 Cr', value: '20000000' },
  { label: '₹2 Cr+', value: '20000000-min' },
];

export function SearchBar({ cities, initial }: { cities: { id: string; name: string }[]; initial?: Partial<SearchFilters> }) {
  const nav = useNavigate();
  const [tab, setTab] = useState(initial?.listingType || 'Sale');
  const [cityId, setCityId] = useState(initial?.cityId ?? '');
  const [type, setType] = useState(initial?.type ?? '');
  const [beds, setBeds] = useState(initial?.beds ?? '');
  const [budget, setBudget] = useState(initial?.maxPrice ?? '');

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const q = new URLSearchParams();
    if (tab === 'Commercial') {
      q.set('type', 'Commercial'); // "Commercial" is a property type, not a listing type
    } else {
      q.set('listingType', tab);
    }
    if (cityId) q.set('cityId', cityId);
    if (type) q.set('type', type);
    if (beds) q.set('beds', beds);
    if (budget && !budget.endsWith('-min')) q.set('maxPrice', budget);
    if (budget.endsWith('-min')) q.set('minPrice', budget.replace('-min', ''));
    nav(`/search?${q.toString()}`);
  };

  const tabs = ['Sale', 'Rent', 'Commercial'];
  const sel = 'w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm dark:border-slate-700 dark:bg-slate-900';

  return (
    <form onSubmit={submit} className="w-full rounded-2xl bg-white p-3 shadow-xl dark:bg-slate-900 sm:p-4">
      <div className="flex gap-1 border-b border-slate-200 pb-3 dark:border-slate-700" role="tablist" aria-label="Listing purpose">
        {tabs.map((t) => (
          <button
            key={t} type="button" role="tab" aria-selected={tab === t}
            onClick={() => setTab(t)}
            className={`rounded-lg px-4 py-2 text-sm font-semibold ${tab === t ? 'bg-brand-600 text-white' : 'text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800'}`}
          >{t === 'Sale' ? 'Buy' : t}</button>
        ))}
      </div>
      <div className="grid gap-2 pt-3 sm:grid-cols-2 lg:grid-cols-[1fr_1fr_1fr_1fr_auto]">
        <label className="block">
          <span className="sr-only">Location</span>
          <select value={cityId} onChange={(e) => setCityId(e.target.value)} className={sel} aria-label="Location">
            <option value="">All locations</option>
            {cities.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </label>
        <label className="block">
          <span className="sr-only">Property type</span>
          <select value={type} onChange={(e) => setType(e.target.value)} className={sel} aria-label="Property type">
            <option value="">All types</option>
            {['Apartment', 'Villa', 'IndependentHouse', 'Plot', 'Commercial', 'Office', 'Shop', 'PG', 'Studio'].map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </label>
        <label className="block">
          <span className="sr-only">Budget</span>
          <select value={budget} onChange={(e) => setBudget(e.target.value)} className={sel} aria-label="Budget">
            {BUDGETS.map((b) => <option key={b.label} value={b.value}>{b.label}</option>)}
          </select>
        </label>
        <label className="block">
          <span className="sr-only">BHK</span>
          <select value={beds} onChange={(e) => setBeds(e.target.value)} className={sel} aria-label="Bedrooms">
            <option value="">Any BHK</option>
            {[1, 2, 3, 4, 5].map((b) => <option key={b} value={b}>{b} BHK</option>)}
          </select>
        </label>
        <Button type="submit" className="lg:px-8">Search</Button>
      </div>
    </form>
  );
}
