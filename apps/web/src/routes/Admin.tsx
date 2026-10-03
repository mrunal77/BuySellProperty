import { useState } from 'react';
import { SectionHeading, Button, Badge, Spinner, EmptyState } from '../components/ui';
import { useAdminUsers, useAdminPendingListings, useModerateListing } from '../features/properties/hooks';
import { api } from '../lib/api';

export function AdminPage() {
  const [tab, setTab] = useState<'pending' | 'users'>('pending');

  const { data: pendingListings, isLoading: pendingLoading, refetch: refetchPending } = useAdminPendingListings();
  const { data: usersData, isLoading: usersLoading, refetch: refetchUsers } = useAdminUsers();
  const moderate = useModerateListing();

  const handleModerate = (id: string, approve: boolean) => {
    moderate.mutate({ id, approve }, { onSuccess: () => refetchPending() });
  };

  const handleToggleUserStatus = async (userId: string, currentActive: boolean) => {
    await api.patch(`/api/v1/admin/users/${userId}/status`, { isActive: !currentActive });
    refetchUsers();
  };

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <SectionHeading
        kicker="Administration & Governance"
        title="Admin Control Panel"
        sub="Moderate properties, manage users, and review platform metrics."
      />

      <div className="mt-6 flex border-b border-slate-200 dark:border-slate-800">
        <button
          onClick={() => setTab('pending')}
          className={`border-b-2 px-4 py-2.5 text-sm font-semibold transition ${tab === 'pending' ? 'border-brand-600 text-brand-600 dark:text-brand-400' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          🛡️ Pending Moderation ({pendingListings?.length ?? 0})
        </button>
        <button
          onClick={() => setTab('users')}
          className={`border-b-2 px-4 py-2.5 text-sm font-semibold transition ${tab === 'users' ? 'border-brand-600 text-brand-600 dark:text-brand-400' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          👥 User Directory ({usersData?.total ?? 0})
        </button>
      </div>

      {tab === 'pending' && (
        <div className="mt-6">
          {pendingLoading ? (
            <div className="flex justify-center p-8"><Spinner /></div>
          ) : !pendingListings || pendingListings.length === 0 ? (
            <EmptyState title="No pending property listings." sub="All posted listings have been moderated." />
          ) : (
            <div className="space-y-4">
              {pendingListings.map((p) => (
                <div key={p.id} className="flex flex-col justify-between gap-4 rounded-xl border border-slate-200 bg-white p-5 shadow-sm sm:flex-row sm:items-center dark:border-slate-800 dark:bg-slate-900">
                  <div>
                    <div className="flex items-center gap-2">
                      <h3 className="font-bold text-lg">{p.title}</h3>
                      <Badge tone="amber">{p.status}</Badge>
                      <Badge tone="blue">{p.propertyType}</Badge>
                    </div>
                    <p className="mt-1 text-sm text-slate-500">📍 {p.addressLine} • ₹{p.price.toLocaleString('en-IN')} • {p.areaSqft} sqft</p>
                    <p className="mt-1 text-xs text-slate-400">Owner ID: {p.ownerId} • Created: {new Date(p.createdAt).toLocaleDateString()}</p>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      onClick={() => handleModerate(p.id, true)}
                      disabled={moderate.isPending}
                      className="bg-emerald-600 hover:bg-emerald-700 text-white"
                    >
                      Approve Listing
                    </Button>
                    <Button
                      variant="secondary"
                      onClick={() => handleModerate(p.id, false)}
                      disabled={moderate.isPending}
                      className="text-rose-600 border-rose-300 hover:bg-rose-50"
                    >
                      Reject
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {tab === 'users' && (
        <div className="mt-6">
          {usersLoading ? (
            <div className="flex justify-center p-8"><Spinner /></div>
          ) : !usersData?.data || usersData.data.length === 0 ? (
            <EmptyState title="No registered users found." />
          ) : (
            <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800 dark:text-slate-400">
                  <tr>
                    <th className="px-4 py-3">Email / Phone</th>
                    <th className="px-4 py-3">User Type</th>
                    <th className="px-4 py-3">Roles</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Joined</th>
                    <th className="px-4 py-3">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                  {usersData.data.map((u: any) => (
                    <tr key={u.id}>
                      <td className="px-4 py-3 font-semibold">
                        <div>{u.email}</div>
                        {u.phone && <div className="text-xs font-normal text-slate-400">📞 {u.phone}</div>}
                      </td>
                      <td className="px-4 py-3">{u.userType}</td>
                      <td className="px-4 py-3">
                        <div className="flex gap-1">{u.roles?.map((r: string) => <Badge key={r} tone="slate">{r}</Badge>)}</div>
                      </td>
                      <td className="px-4 py-3">
                        <Badge tone={u.isActive ? 'green' : 'amber'}>{u.isActive ? 'Active' : 'Disabled'}</Badge>
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-500">{new Date(u.createdAt).toLocaleDateString()}</td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => handleToggleUserStatus(u.id, u.isActive)}
                          className={`rounded px-2.5 py-1 text-xs font-semibold ${u.isActive ? 'bg-rose-50 text-rose-700 hover:bg-rose-100 dark:bg-rose-950 dark:text-rose-300' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-950 dark:text-emerald-300'}`}
                        >
                          {u.isActive ? 'Disable' : 'Activate'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
