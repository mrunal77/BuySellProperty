import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';
import '../../../core/auth_store.dart';
import '../../../core/browse_widgets.dart';

class _CityItem {
  final String name, image;
  const _CityItem(this.name, this.image);
}

const _popularCities = [
  _CityItem('Delhi / NCR', 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Mumbai', 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Bangalore', 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Hyderabad', 'https://images.unsplash.com/photo-1605007493699-af65834f8a00?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Pune', 'https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Kolkata', 'https://images.unsplash.com/photo-1558431382-27e303142255?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Chennai', 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=500&auto=format&fit=crop&q=80'),
  _CityItem('Ahmedabad', 'https://images.unsplash.com/photo-1609766857041-ed402ea8069a?w=500&auto=format&fit=crop&q=80'),
];

CityDto? _findCity(List<CityDto> cities, String popularName) {
  final key = popularName.split('/').first.trim().toLowerCase();
  for (final c in cities) {
    final n = c.name.toLowerCase();
    if (n == key || n.startsWith(key) || key.startsWith(n)) return c;
  }
  return null;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildCityCard(BuildContext context, _CityItem c, List<CityDto> cities) {
    final matchedCity = _findCity(cities, c.name);
    final count = matchedCity?.propertyCount ?? 0;
    return InkWell(
      onTap: () {
        final queryParams = <String, String>{};
        if (matchedCity != null) {
          queryParams['cityId'] = matchedCity.id;
          queryParams['cityName'] = matchedCity.name;
        } else {
          final cleanName = c.name.split('/').first.trim();
          queryParams['cityName'] = cleanName;
        }
        final uri = Uri(path: '/search', queryParameters: queryParams);
        context.go(uri.toString());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                c.image,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.location_city, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'Property' : 'Properties'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStoreProvider);
    final featured = ref.watch(propertySearchProvider(const PropertyQuery(pageSize: 8)));
    final cities = ref.watch(citiesProvider).valueOrNull ?? const [];
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
            // HERO SEARCH CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.isLoggedIn ? 'Hello, ${auth.email}' : 'Find a place you’ll love',
                    style: TextStyle(color: cs.onPrimary, fontSize: wide ? 26 : 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buy, rent or list — thousands of verified homes.',
                    style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Search Input Trigger
                  InkWell(
                    onTap: () => context.go('/search'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: cs.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search locality, city or keyword...',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.tune, size: 18, color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Mode Buttons
                  Row(
                    children: [
                      _heroBtn(context, 'Buy', () => context.go('/search?listingType=Sale')),
                      const SizedBox(width: 8),
                      _heroBtn(context, 'Rent', () => context.go('/search?listingType=Rent')),
                      const SizedBox(width: 8),
                      _heroBtn(context, 'Commercial', () => context.go('/search?type=Commercial')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Property Type Quick Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _typeChip(context, 'Apartment', 'Apartment'),
                        _typeChip(context, 'House', 'IndependentHouse'),
                        _typeChip(context, 'Villa', 'Villa'),
                        _typeChip(context, 'Plot', 'Plot'),
                        _typeChip(context, 'Shop', 'Shop'),
                        _typeChip(context, 'Office', 'Office'),
                      ],
                    ),
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
            const Text(
              'Explore Real Estate in Popular Indian Cities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (_popularCities.length / 2).ceil(),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, colIndex) {
                  final item1 = _popularCities[colIndex * 2];
                  final item2 = colIndex * 2 + 1 < _popularCities.length
                      ? _popularCities[colIndex * 2 + 1]
                      : null;
                  return Column(
                    children: [
                      _buildCityCard(context, item1, cities),
                      if (item2 != null) ...[
                        const SizedBox(height: 10),
                        _buildCityCard(context, item2, cities),
                      ],
                    ],
                  );
                },
              ),
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
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _typeChip(BuildContext context, String label, String apiType) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => context.go('/search?type=$apiType'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
