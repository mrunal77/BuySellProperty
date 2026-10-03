import 'package:buysell_mobile/src/core/browse_widgets.dart';
import 'package:buysell_mobile/src/core/network.dart';
import 'package:buysell_mobile/src/features/favorites/presentation/favorites_screen.dart';
import 'package:buysell_mobile/src/features/profile/presentation/profile_screen.dart';
import 'package:buysell_mobile/src/features/search/data/properties_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _sampleProperty = {
  'id': 'prop-101',
  'title': 'Luxury Sea View Villa',
  'price': 15000000,
  'propertyType': 'Villa',
  'listingType': 'Sale',
  'areaSqft': 2500,
  'bedrooms': 3,
  'imageUrls': [
    'http://localhost:5000/uploads/test_villa.jpg',
    'http://localhost:5000/uploads/test_villa_2.jpg'
  ],
};

GoRouter _createTestRouter() => GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: Text('Home Screen'),
            bottomNavigationBar: AppBottomNav(current: 0),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const Scaffold(
            body: Column(
              children: [
                PropertyCard(p: _sampleProperty),
              ],
            ),
            bottomNavigationBar: AppBottomNav(current: 1),
          ),
        ),
        GoRoute(
          path: '/saved',
          builder: (_, __) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/p/:id',
          builder: (_, s) => Scaffold(
            appBar: AppBar(),
            body: Text('Property Detail: ${s.pathParameters['id']}'),
          ),
        ),
      ],
    );

void main() {
  group('Manual & Integration Flow Verification', () {
    test('normalizeImageUrl helper handles relative and absolute URLs', () {
      expect(normalizeImageUrl(null), '');
      expect(normalizeImageUrl(''), '');
      expect(normalizeImageUrl('https://images.unsplash.com/photo-1'), 'https://images.unsplash.com/photo-1');
      expect(normalizeImageUrl('http://localhost:5000/uploads/img.jpg'), 'http://localhost:5000/uploads/img.jpg');
      expect(normalizeImageUrl('/uploads/img.jpg'), 'http://localhost:5000/uploads/img.jpg');
      expect(normalizeImageUrl('uploads/img.jpg'), 'http://localhost:5000/uploads/img.jpg');
    });

    testWidgets('PropertyCard renders title, price, BHK, and photo count badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: _createTestRouter(),
          ),
        ),
      );

      expect(find.text('Luxury Sea View Villa'), findsOneWidget);
      expect(find.text('₹1.50 Cr'), findsOneWidget);
      expect(find.text('Villa • 3 BHK • 2500 sqft'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 photos badge
    });

    testWidgets('Bottom navigation switches between tabs cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: _createTestRouter(),
          ),
        ),
      );

      // Verify on Search screen
      expect(find.text('Luxury Sea View Villa'), findsOneWidget);

      // Tap Home destination
      await tester.tap(find.byIcon(Icons.home_outlined).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Home Screen'), findsOneWidget);

      // Tap Profile destination
      await tester.tap(find.byIcon(Icons.person_outline).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('Tapping property card opens Detail view and back button pops back', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: _createTestRouter(),
          ),
        ),
      );

      await tester.tap(find.text('Luxury Sea View Villa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Property Detail: prop-101'), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Luxury Sea View Villa'), findsOneWidget);
    });
  });
}
