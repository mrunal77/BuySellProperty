import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_store.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/property_detail/presentation/property_detail_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/owner_dashboard/presentation/owner_dashboard_screen.dart';
import '../features/listing_editor/presentation/listing_editor_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

const _authRoutes = ['/login', '/register'];
const _listerRoutes = ['/owner', '/owner/new'];

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStoreProvider);
  return GoRouter(
    initialLocation: '/home',
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final goingAuth = _authRoutes.contains(loc);
      final needsLister = _listerRoutes.any(loc.startsWith);

      if (!auth.isLoggedIn) {
        // Deep-linking into owner areas requires login; remember where to go.
        if (needsLister) return '/login?next=${Uri.encodeComponent(loc)}';
        return goingAuth ? null : null;
      }
      if (goingAuth) return auth.homeRoute;
      if (needsLister && !auth.isLister) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, s) => LoginScreen(next: s.uri.queryParameters['next'])),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/search',
        builder: (_, s) => SearchScreen(
          initialListingType: s.uri.queryParameters['listingType'],
          initialType: s.uri.queryParameters['type'],
        ),
      ),
      GoRoute(path: '/p/:id', builder: (_, s) => PropertyDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/saved', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/owner', builder: (_, __) => const OwnerDashboardScreen()),
      GoRoute(path: '/owner/new', builder: (_, __) => const ListingEditorScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
