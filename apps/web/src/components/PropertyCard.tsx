import { useState } from 'react';
import { Link } from 'react-router-dom';
import { formatINR } from '../lib/validation';
import { Badge } from './ui';
import { useAuth } from '../lib/auth';
import { useFavorites, useToggleFavorite } from '../features/properties/hooks';

export type Property = {
  id: string; title: string; price: number; propertyType: string; listingType: string;
  areaSqft: number; bedrooms?: number | null; bathrooms?: number | null;
  status?: string; addressLine?: string; imageUrls?: string[]; amenities?: string[];
};

const GRADS = [
  'from-emerald-600 to-teal-800', 'from-sky-600 to-indigo-800',
  'from-amber-500 to-orange-700', 'from-rose-500 to-pink-700',
  'from-violet-600 to-purple-800', 'from-cyan-600 to-blue-800',
];

function artFor(id: string): string {
  let h = 0;
  for (const c of id) h = (h * 31 + c.charCodeAt(0)) % 997;
  return GRADS[h % GRADS.length];
}

export function PropertyArt({ id, title, imageUrl, className = 'h-44' }: { id: string; title: string; imageUrl?: string; className?: string }) {
  const [imgErr, setImgErr] = useState(false);
  const initial = (title.trim()[0] ?? 'B').toUpperCase();

  if (imageUrl && !imgErr) {
    return (
      <div className={`relative overflow-hidden bg-slate-100 ${className}`}>
        <img
          src={imageUrl}
          alt={title}
          onError={() => setImgErr(true)}
          className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
        />
      </div>
    );
  }

  return (
    <div className={`flex items-center justify-center bg-gradient-to-br ${artFor(id)} ${className}`} role="img" aria-label={title}>
      <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-white/20 text-2xl font-extrabold text-white backdrop-blur">{initial}</span>
    </div>
  );
}

export function PropertyCard({ p }: { p: Property }) {
  const { session } = useAuth();
  const { data: favorites } = useFavorites();
  const toggleFav = useToggleFavorite();

  const isFav = !!favorites?.some((f) => f.id === p.id);
  const mainImage = p.imageUrls && p.imageUrls.length > 0 ? p.imageUrls[0] : undefined;

  const handleFavClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (!session) return;
    toggleFav.mutate({ propertyId: p.id, isFav });
  };

  return (
    <Link to={`/p/${p.id}`} className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white transition hover:-translate-y-0.5 hover:shadow-lg dark:border-slate-800 dark:bg-slate-900">
      <PropertyArt id={p.id} title={p.title} imageUrl={mainImage} />
      {session && (
        <button
          onClick={handleFavClick}
          aria-label={isFav ? 'Remove from saved' : 'Save property'}
          className="absolute right-3 top-3 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-white/80 text-lg shadow-sm backdrop-blur transition hover:bg-white dark:bg-slate-900/80 dark:hover:bg-slate-900"
        >
          {isFav ? '❤️' : '🤍'}
        </button>
      )}
      <div className="p-4">
        <div className="flex items-center justify-between gap-2">
          <p className="text-lg font-extrabold text-brand-700 dark:text-brand-300">{formatINR(p.price)}</p>
          <Badge tone={p.listingType === 'Rent' ? 'blue' : 'green'}>{p.listingType}</Badge>
        </div>
        <h3 className="mt-1 line-clamp-1 font-semibold group-hover:text-brand-700 dark:group-hover:text-brand-300">{p.title}</h3>
        <p className="mt-1 line-clamp-1 text-sm text-slate-500">{p.propertyType}{p.bedrooms ? ` • ${p.bedrooms} BHK` : ''} • {p.areaSqft} sqft</p>
        {p.addressLine && <p className="mt-1 line-clamp-1 text-xs text-slate-400">📍 {p.addressLine}</p>}
        {p.status && p.status !== 'Active' && <div className="mt-2"><Badge tone="amber">{p.status}</Badge></div>}
      </div>
    </Link>
  );
}
