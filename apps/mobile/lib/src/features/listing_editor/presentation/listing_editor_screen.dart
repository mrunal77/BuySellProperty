import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../search/data/properties_api.dart';
import '../../../core/network.dart';

class ListingEditorScreen extends ConsumerStatefulWidget {
  const ListingEditorScreen({super.key});
  @override
  ConsumerState<ListingEditorScreen> createState() => _ListingEditorScreenState();
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Modern 2 BHK Apartment');
  final _desc = TextEditingController(text: 'Sunlit apartment with spacious rooms, modern kitchen, and balcony view.');
  final _price = TextEditingController(text: '6500000');
  final _area = TextEditingController(text: '1150');
  final _addr = TextEditingController(text: 'Koregaon Park, Lane 5');

  String _propType = 'Apartment';
  String _listingType = 'Sale';
  String _furnishing = 'SemiFurnished';
  int _beds = 2;
  int _baths = 2;
  bool _submitting = false;
  bool _uploading = false;

  final List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _selectedAmenities = ['24x7 Security', 'Power Backup'];
  final List<String> _availableAmenities = [
    'Swimming Pool', 'Gymnasium', '24x7 Security', 'Power Backup', 'Reserved Parking', 'Clubhouse'
  ];

  Future<void> _pickAndUploadImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      setState(() => _uploading = true);

      for (final img in images) {
        final url = await uploadImage(ref, img.path);
        setState(() {
          _uploadedImageUrls.add(url);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post New Property'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/owner'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Property Title *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _propType,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: ['Apartment', 'Villa', 'IndependentHouse', 'Plot', 'Commercial', 'PG']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _propType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _listingType,
                      decoration: const InputDecoration(labelText: 'Listing', border: OutlineInputBorder()),
                      items: ['Sale', 'Rent', 'Lease']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _listingType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (₹) *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Price is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _area,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Area (sqft) *', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Area is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _beds,
                      decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()),
                      items: [1, 2, 3, 4, 5].map((b) => DropdownMenuItem(value: b, child: Text('$b BHK'))).toList(),
                      onChanged: (v) => setState(() => _beds = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _baths,
                      decoration: const InputDecoration(labelText: 'Bathrooms', border: OutlineInputBorder()),
                      items: [1, 2, 3, 4].map((b) => DropdownMenuItem(value: b, child: Text('$b Baths'))).toList(),
                      onChanged: (v) => setState(() => _baths = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addr,
                decoration: const InputDecoration(labelText: 'Address Line / Locality *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              // Image Upload Section
              const Text('Property Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickAndUploadImages,
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_a_photo),
                label: Text(_uploading ? 'Uploading image...' : 'Pick & Upload Photos from Gallery'),
              ),

              if (_uploadedImageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _uploadedImageUrls.length,
                    itemBuilder: (ctx, i) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100, height: 90,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: Image.network(
                            normalizeImageUrl(_uploadedImageUrls[i]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => _uploadedImageUrls.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              const Text('Select Amenities:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _availableAmenities.map((am) {
                  final sel = _selectedAmenities.contains(am);
                  return FilterChip(
                    label: Text(am),
                    selected: sel,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAmenities.add(am);
                        } else {
                          _selectedAmenities.remove(am);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Property Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_submitting || _uploading)
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _submitting = true);

                          try {
                            await createProperty(ref, {
                              'title': _title.text.trim(),
                              'description': _desc.text.trim(),
                              'propertyType': _propType,
                              'listingType': _listingType,
                              'price': double.parse(_price.text),
                              'areaSqft': double.parse(_area.text),
                              'bedrooms': _beds,
                              'bathrooms': _baths,
                              'furnishing': _furnishing,
                              'addressLine': _addr.text.trim(),
                              'cityId': '22222222-2222-2222-2222-222222222222', // Pune default
                              'latitude': 18.5204,
                              'longitude': 73.8567,
                              'imageUrls': _uploadedImageUrls,
                              'amenities': _selectedAmenities,
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Listing created and published!')),
                              );
                              context.go('/owner');
                            }
                          } catch (e) {
                            setState(() => _submitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to create listing: $e')),
                            );
                          }
                        },
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publish Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
