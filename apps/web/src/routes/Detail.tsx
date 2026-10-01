import { Link, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import { formatINR } from '../lib/validation';
import { Badge, Spinner } from '../components/ui';
import { PropertyArt } from '../components/PropertyCard';

export function DetailPage() {
  const { id } = useParams();
  const { data, isLoading, isError } = useQuery({
    queryKey: ['p', id],
    queryFn: async () => (await api.get(`/api/v1/properties/${id}`)).data,
  });

  if (isLoading) return <div className="flex justify-center p-12"><Spinner /></div>;
  if (isError || !data) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-12 text-center">
        <p className="text-xl font-bold">Property not found</p>
        <p className="mt-1 text-sm text-slate-500">It may have been sold or removed.</p>
        <Link to="/search" className="mt-4 inline-block rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white">Back to search</Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6">
      <Link to="/search" className="text-sm font-semibold text-brand-700 hover:underline">← Back to results</Link>
      <div className="mt-3 overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-800">
        <PropertyArt id={data.id} title={data.title} className="h-64 sm:h-80" />
      </div>
      <div className="mt-5 grid gap-6 lg:grid-cols-[1fr_320px]">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone={data.listingType === 'Rent' ? 'blue' : 'green'}>{data.listingType}</Badge>
            <Badge tone="slate">{data.propertyType}</Badge>
            <Badge tone="slate">{data.status}</Badge>
          </div>
          <h1 className="mt-2 text-2xl font-extrabold sm:text-3xl">{data.title}</h1>
          <p className="mt-1 text-sm text-slate-500">{data.addressLine}</p>
          <dl className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[['Area', `${data.areaSqft} sqft`], ['Bedrooms', data.bedrooms ?? '—'], ['Bathrooms', data.bathrooms ?? '—'], ['Furnishing', data.furnishing ?? '—']].map(([k, v]) => (
              <div key={k} className="rounded-xl border border-slate-200 p-3 dark:border-slate-800">
                <dt className="text-xs text-slate-500">{k}</dt>
                <dd className="font-bold">{v}</dd>
              </div>
            ))}
          </dl>
          <h2 className="mt-6 font-bold">Description</h2>
          <p className="mt-1 whitespace-pre-wrap text-sm text-slate-600 dark:text-slate-300">{data.description || 'No description provided.'}</p>
        </div>
        <aside className="h-fit rounded-2xl border border-slate-200 p-5 dark:border-slate-800 dark:bg-slate-900">
          <p className="text-2xl font-extrabold text-brand-700 dark:text-brand-300">{formatINR(data.price)}</p>
          <button className="mt-4 w-full rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-700">Contact owner</button>
          <button className="mt-2 w-full rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800">Book site visit</button>
          <p className="mt-3 text-xs text-slate-500">Enquiries & visits go live with the engagement milestone.</p>
        </aside>
      </div>
    </div>
  );
}
