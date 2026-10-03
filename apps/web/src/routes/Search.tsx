import { useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useProperties, useCities } from '../features/properties/hooks';
import { PropertyCard } from '../components/PropertyCard';
import { SectionHeading, Button, Spinner, EmptyState } from '../components/ui';

export function SearchPage() {
  const [params, setParams] = useSearchParams();
  const { data: cities = [] } = useCities();

  const [listingType, setListingType] = useState(params.get('listingType') ?? '');
  const [cityId, setCityId] = useState(params.get('cityId') ?? '');
  const [city, setCity] = useState(params.get('city') ?? '');
  const [type, setType] = useState(params.get('type') ?? '');
  const [beds, setBeds] = useState(params.get('beds') ?? '');
  const [maxPrice, setMaxPrice] = useState(params.get('maxPrice') ?? '');
  const [sort, setSort] = useState('newest');

  const selectedCityId = cityId || (cities.find(c => c.name.toLowerCase() === city.toLowerCase())?.id ?? '');

  const filters = useMemo(() => ({
    listingType: listingType || undefined,
    cityId: selectedCityId || undefined,
    city: !selectedCityId && city ? city : undefined,
    type: type || undefined,
    beds: beds ? Number(beds) : undefined,
    maxPrice: maxPrice ? Number(maxPrice) : undefined,
    sort, pageSize: 24,
  }), [listingType, selectedCityId, city, type, beds, maxPrice, sort]);

  const { data, isLoading, isError, refetch } = useProperties(filters);
  const items = data?.data ?? [];

  const syncUrl = (patch: Record<string, string>) => {
    const next = new URLSearchParams(params);
    for (const [k, v] of Object.entries(patch)) {
      if (v) next.set(k, v); else next.delete(k);
    }
    setParams(next, { replace: true });
  };

  const sel = 'rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900';

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <SectionHeading title={listingType === 'Rent' ? 'Properties for rent' : 'Properties for sale'} sub={`${data?.total ?? 0} results`} />

      <div className="mb-6 flex flex-wrap gap-2">
        <select aria-label="Purpose" value={listingType} onChange={(e) => { setListingType(e.target.value); syncUrl({ listingType: e.target.value }); }} className={sel}>
          <option value="">Buy + Rent</option><option value="Sale">Buy</option><option value="Rent">Rent</option><option value="Lease">Lease</option>
        </select>
        <select aria-label="City" value={selectedCityId} onChange={(e) => { 
          const val = e.target.value; 
          setCityId(val); 
          setCity(''); 
          syncUrl({ cityId: val, city: '' }); 
        }} className={sel}>
          <option value="">All cities</option>
          {cities.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name} ({c.propertyCount ?? 0})
            </option>
          ))}
        </select>
        <select aria-label="Type" value={type} onChange={(e) => { setType(e.target.value); syncUrl({ type: e.target.value }); }} className={sel}>
          <option value="">All types</option>
          {['Apartment', 'Villa', 'IndependentHouse', 'Plot', 'Commercial', 'PG'].map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
        <select aria-label="BHK" value={beds} onChange={(e) => { setBeds(e.target.value); syncUrl({ beds: e.target.value }); }} className={sel}>
          <option value="">Any BHK</option>
          {[1, 2, 3, 4, 5].map((b) => <option key={b} value={b}>{b}+ BHK</option>)}
        </select>
        <select aria-label="Budget" value={maxPrice} onChange={(e) => { setMaxPrice(e.target.value); syncUrl({ maxPrice: e.target.value }); }} className={sel}>
          <option value="">Any budget</option>
          <option value="5000000">Under ₹50 L</option><option value="10000000">Under ₹1 Cr</option><option value="20000000">Under ₹2 Cr</option>
        </select>
        <select aria-label="Sort" value={sort} onChange={(e) => setSort(e.target.value)} className={sel}>
          <option value="newest">Newest</option><option value="price_asc">Price ↑</option><option value="price_desc">Price ↓</option><option value="area_desc">Area ↓</option>
        </select>
        {(listingType || selectedCityId || city || type || beds || maxPrice) && (
          <Button variant="ghost" onClick={() => { setListingType(''); setCityId(''); setCity(''); setType(''); setBeds(''); setMaxPrice(''); setParams({}, { replace: true }); }}>Clear</Button>
        )}
      </div>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => <div key={i} className="h-64 animate-pulse rounded-xl bg-slate-200 dark:bg-slate-800" />)}
        </div>
      ) : isError ? (
        <div className="rounded-xl border border-red-200 bg-red-50 p-6 text-center dark:border-red-900 dark:bg-red-950">
          <p className="font-semibold">Couldn't load properties.</p>
          <Button variant="secondary" className="mt-3" onClick={() => refetch()}>Retry</Button>
        </div>
      ) : items.length === 0 ? (
        <EmptyState title="No properties match your filters." sub="Try widening the budget or clearing a filter." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {items.map((p: Parameters<typeof PropertyCard>[0]['p']) => <PropertyCard key={p.id} p={p} />)}
        </div>
      )}
      {isLoading && <div className="mt-6 flex justify-center"><Spinner /></div>}
    </div>
  );
}
