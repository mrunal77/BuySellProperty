import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';
import '../../../core/auth_store.dart';
import '../../../core/browse_widgets.dart';

const _locations = [
  ('Mumbai', 'Finance capital', [Color(0xFF0369A1), Color(0xFF312E81)]),
  ('Pune', 'IT & education hub', [Color(0xFF006244), Color(0xFF014434)]),
  ('Bengaluru', 'Startup capital', [Color(0xFF7C3AED), Color(0xFF4C1D95)]),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStoreProvider);
    final featured = ref.watch(propertySearchProvider(const PropertyQuery(pageSize: 8)));
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BuySellProperty'),
        actions: [
          IconButton(tooltip: 'Search', icon: const Icon(Icons.search), onPressed: () => context.go('/search')),
          IconButton(tooltip: 'Profile', icon: const Icon(Icons.person), onPressed: () => context.go('/profile')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(propertySearchProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // HERO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.isLoggedIn ? 'Hello, ${auth.email}' : 'Find a place you’ll love',
                    style: TextStyle(color: cs.onPrimary, fontSize: wide ? 28 : 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Buy, rent or list — thousands of verified homes.',
                      style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _heroBtn(context, 'Buy', () => context.go('/search?listingType=Sale')),
                      _heroBtn(context, 'Rent', () => context.go('/search?listingType=Rent')),
                      _heroBtn(context, 'Commercial', () => context.go('/search?type=Commercial')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(
              title: 'Featured properties',
              actionLabel: 'View all',
              onAction: () => context.go('/search'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: featured.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => BrowseError(error: e, onRetry: () => ref.invalidate(propertySearchProvider)),
                data: (json) {
                  final items = (json['data'] as List).cast<Map<String, dynamic>>();
                  if (items.isEmpty) {
                    return const Center(child: Text('No listings yet — be the first to post!'));
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => PropertyCard(p: items[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Popular locations'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: wide ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                for (final (name, note, colors) in _locations)
                  InkWell(
                    onTap: () => context.go('/search'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(note, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // POST CTA
            Card(
              color: cs.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Own a property? List it for FREE.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSecondaryContainer)),
                    const SizedBox(height: 4),
                    Text('Reach thousands of genuine buyers and tenants.',
                        style: TextStyle(color: cs.onSecondaryContainer)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push(auth.isLister ? '/owner/new' : '/register'),
                      child: const Text('Post your property'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: 0),
    );
  }

  Widget _heroBtn(BuildContext context, String label, VoidCallback onTap) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
