import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../search/data/properties_api.dart';
import '../../../core/browse_widgets.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final String id;
  const PropertyDetailScreen({super.key, required this.id});

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enquiries & site visits arrive with the engagement milestone.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(propertyDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Property')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => BrowseError(error: e, onRetry: () => ref.invalidate(propertyDetailProvider(id))),
        data: (p) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
            Text('₹${p.price} • ${p.propertyType} • ${p.listingType}'),
            Text('${p.areaSqft} sqft • ${p.bedrooms ?? '-'} bed • ${p.bathrooms ?? '-'} bath'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => _soon(context), child: const Text('Enquire / Contact Owner')),
            ElevatedButton(onPressed: () => _soon(context), child: const Text('Book Site Visit')),
          ]),
        ),
      ),
    );
  }
}
