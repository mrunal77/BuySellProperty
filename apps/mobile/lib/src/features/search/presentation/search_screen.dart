import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/properties_api.dart';
import '../../../core/browse_widgets.dart';

import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialListingType;
  final String? initialType;
  const SearchScreen({super.key, this.initialListingType, this.initialType});
  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  late String? listingType = widget.initialListingType;
  late String? type = widget.initialType;
  int? beds;

  @override
  Widget build(BuildContext context) {
    final q = PropertyQuery(listingType: listingType, type: type, beds: beds);
    final props = ref.watch(propertySearchProvider(q));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search properties'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _chip('Buy', listingType == 'Sale', () => setState(() => listingType = listingType == 'Sale' ? null : 'Sale')),
              _chip('Rent', listingType == 'Rent', () => setState(() => listingType = listingType == 'Rent' ? null : 'Rent')),
              _chip('2+ BHK', beds == 2, () => setState(() => beds = beds == 2 ? null : 2)),
              _chip('3+ BHK', beds == 3, () => setState(() => beds = beds == 3 ? null : 3)),
              TextButton(
                onPressed: () => setState(() { listingType = null; type = null; beds = null; }),
                child: const Text('Clear'),
              ),
            ]),
          ),
          Expanded(
            child: props.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => BrowseError(error: e, onRetry: () => ref.invalidate(propertySearchProvider)),
              data: (json) {
                final items = (json['data'] as List).cast<Map<String, dynamic>>();
                if (items.isEmpty) {
                  return const Center(child: Text('No properties match. Try clearing a filter.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(propertySearchProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PropertyCard(p: items[i], width: double.infinity),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
