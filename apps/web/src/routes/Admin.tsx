import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';

export function AdminPage() {
  const { data } = useQuery({ queryKey: ['admin'], queryFn: async () => (await api.get('/api/v1/cities')).data });
  return (
    <div className="p-6">
      <h1 className="text-xl font-bold">Admin — moderation queue (MVP stub)</h1>
      <p>Cities seeded: {(data ?? []).length}. Pending listings endpoint: GET /api/v1/admin/listings/pending (next milestone).</p>
    </div>
  );
}
