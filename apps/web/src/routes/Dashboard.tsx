import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { PropertyCard } from '../components/PropertyCard';
import { SectionHeading, Button, EmptyState } from '../components/ui';

export function DashboardPage() {
  const { session } = useAuth();
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['mine'],
    queryFn: async () => (await api.get('/api/v1/properties', { params: { mine: true, pageSize: 50 } })).data,
  });
  const items = data?.data ?? [];

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <SectionHeading
        kicker="Owner studio" title={`Welcome, ${session?.email}`}
        sub={`${data?.total ?? 0} listings • ${session?.userType}`}
        action={<Link to="/search"><Button variant="secondary">Browse marketplace</Button></Link>}
      />

      <div className="mb-8 rounded-2xl border border-brand-200 bg-brand-50 p-6 dark:border-brand-900 dark:bg-brand-950/40">
        <h2 className="font-bold">Have another property to list?</h2>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">Posting from the mobile app takes under a minute — photos, location and pricing included.</p>
      </div>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{[0, 1, 2, 3].map((i) => <div key={i} className="h-64 animate-pulse rounded-xl bg-slate-200 dark:bg-slate-800" />)}</div>
      ) : isError ? (
        <div className="rounded-xl border border-red-200 bg-red-50 p-6 text-center dark:border-red-900 dark:bg-red-950">
          <p className="font-semibold">Couldn't load your listings.</p>
          <Button variant="secondary" className="mt-3" onClick={() => refetch()}>Retry</Button>
        </div>
      ) : items.length === 0 ? (
        <EmptyState title="You haven't posted any listings yet." sub="Post your first property from the mobile app — it's free." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {items.map((p: Parameters<typeof PropertyCard>[0]['p']) => <PropertyCard key={p.id} p={p} />)}
        </div>
      )}
    </div>
  );
}
