import { Link } from 'react-router-dom';
import { SectionHeading, Spinner, EmptyState, Button } from '../components/ui';
import { PropertyCard } from '../components/PropertyCard';
import { useFavorites } from '../features/properties/hooks';

export function FavoritesPage() {
  const { data: favorites, isLoading, isError, refetch } = useFavorites();

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <SectionHeading
        kicker="Saved Properties"
        title="Your Favorites"
        sub="Easily view and compare properties you have bookmarked."
        action={<Link to="/search"><Button variant="secondary">Explore Marketplace</Button></Link>}
      />

      {isLoading ? (
        <div className="flex justify-center p-12"><Spinner /></div>
      ) : isError ? (
        <div className="rounded-xl border border-red-200 bg-red-50 p-6 text-center dark:border-red-900 dark:bg-red-950">
          <p className="font-semibold">Couldn't load saved properties.</p>
          <Button variant="secondary" className="mt-3" onClick={() => refetch()}>Retry</Button>
        </div>
      ) : !favorites || favorites.length === 0 ? (
        <EmptyState
          title="No saved properties yet."
          sub="Click the heart icon on any property card or detail page to bookmark it."
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {favorites.map((p) => (
            <PropertyCard key={p.id} p={p} />
          ))}
        </div>
      )}
    </div>
  );
}
