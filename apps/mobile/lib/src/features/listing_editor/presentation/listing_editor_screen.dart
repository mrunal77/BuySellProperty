import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';

class ListingEditorScreen extends ConsumerStatefulWidget {
  const ListingEditorScreen({super.key});
  @override
  ConsumerState<ListingEditorScreen> createState() => _S();
}

class _S extends ConsumerState<ListingEditorScreen> {
  final _title = TextEditingController(), _desc = TextEditingController(),
      _price = TextEditingController(text: '5000000'), _area = TextEditingController(text: '1000'),
      _addr = TextEditingController(text: 'Bandra West');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Listing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
          TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
          TextField(controller: _area, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Area sqft')),
          TextField(controller: _addr, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await createProperty(ref, {
                'title': _title.text.isEmpty ? '2BHK Apartment' : _title.text,
                'description': _desc.text, 'propertyType': 0, 'listingType': 0,
                'price': double.parse(_price.text), 'areaSqft': double.parse(_area.text),
                'addressLine': _addr.text, 'cityId': '22222222-2222-2222-2222-222222222222',
                'latitude': 18.5204, 'longitude': 73.8567, 'bedrooms': 2, 'bathrooms': 2, 'furnishing': 1,
              });
              if (context.mounted) context.go('/owner');
            },
            child: const Text('Create (Draft)'),
          ),
        ]),
      ),
    );
  }
}
