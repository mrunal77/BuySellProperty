import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../search/data/properties_api.dart';
import '../../../core/network.dart';
import '../../../core/validators.dart';
import '../../listing_editor/domain/property_type_config.dart';
import 'widgets/dynamic_property_form.dart';

class ListingEditorScreen extends ConsumerStatefulWidget {
  final String? editId;
  const ListingEditorScreen({super.key, this.editId});
  @override
  ConsumerState<ListingEditorScreen> createState() => _ListingEditorScreenState();
}

class _StepTitles {
  static const names = [
    'Basic Information',
    'Property Details',
    'Location',
    'Photos',
    'Contact Details',
    'Preview',
    'Submit',
  ];
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  int _step = 0;

  // Common fields (steps 1, 3, 5)
  late final _title = TextEditingController();
  late final _desc = TextEditingController();
  late final _price = TextEditingController();
  late final _addr = TextEditingController();
  late final _contactName = TextEditingController();
  late final _contactPhone = TextEditingController();
  late final _whatsapp = TextEditingController();

  // Dynamic per-type fields (step 2)
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, dynamic> _values = {};
  final Map<String, String> _errors = {};

  PropertyType? _propertyType;
  String _listingType = 'Sale';
  String? _cityId;
  String? _localityId;

  bool _submitting = false;
  bool _uploading = false;
  bool _loading = false;

  final List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title, _desc, _price, _addr, _contactName, _contactPhone, _whatsapp,
      ..._fieldControllers.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) =>
      _fieldControllers.putIfAbsent(key, () => TextEditingController());

  String? _textOf(String key) => _fieldControllers[key]?.text.trim();

  dynamic _fieldValue(FieldDef f) {
    if (f.type == FieldType.number || f.type == FieldType.text) return _textOf(f.key);
    return _values[f.key];
  }

  void _setValue(String key, dynamic v) {
    final def = _definitionFor(key);
    if (def != null && def.type == FieldType.boolean) {
      _values[key] = v == true || v == 'true';
    } else if (def != null && def.type == FieldType.number && v != null) {
      _controllerFor(key).text = _numText(v);
    } else {
      _values[key] = v;
    }
    if (mounted) setState(() => _errors.remove(key));
  }

  FieldDef? _definitionFor(String key) {
    for (final list in propertyTypeFields().values) {
      for (final f in list) {
        if (f.key == key) return f;
      }
    }
    return null;
  }

  static String _numText(Object v) {
    if (v is num) {
      return v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
    }
    return '$v';
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final p = await ref.read(propertyDetailProvider(widget.editId!).future);
      _title.text = p.title;
      _desc.text = p.description ?? '';
      _price.text = p.price.toStringAsFixed(0);
      _addr.text = p.addressLine ?? '';
      _cityId = p.cityId;
      _localityId = p.localityId;
      _contactName.text = p.contactName ?? '';
      _contactPhone.text = p.contactPhone ?? '';
      _whatsapp.text = p.whatsApp ?? '';
      _listingType = p.listingType;
      _propertyType = PropertyType.tryFromApi(p.propertyType) ?? PropertyType.apartment;
      _uploadedImageUrls.addAll(p.imageUrls);
      _selectedAmenities.addAll(p.amenities);

      final fields = fieldsFor(_propertyType!);
      final details = p.details;
      for (final f in fields) {
        if (f.type == FieldType.amenities) continue;
        var v = details?[f.key];
        if (v == null) {
          // Backfill legacy listings that predate the details column.
          if (f.key == 'bhk' && p.bedrooms != null) {
            v = '${p.bedrooms}';
          }
          if (f.key == 'bathrooms' && p.bathrooms != null) {
            v = '${p.bathrooms}';
          }
          if (f.key == 'furnishing') {
            v = furnishingToDisplay(p.furnishing);
          }
          if (primaryAreaKeys(_propertyType!).first == f.key) {
            v = _numText(p.areaSqft);
          }
        }
        if (v == null) continue;
        if (f.type == FieldType.number) {
          _controllerFor(f.key).text = _numText(v);
        } else if (f.type == FieldType.dropdown && f.key == 'furnishing' && v is String) {
          _values[f.key] = furnishingToDisplay(v);
        } else if (f.type == FieldType.boolean) {
          _values[f.key] = v == true || v == 'true';
        } else if (v is String) {
          _values[f.key] = v;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load property: $e')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      setState(() => _uploading = true);
      for (final img in images) {
        final url = await uploadImage(ref, img.path);
        if (mounted) setState(() => _uploadedImageUrls.add(url));
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

  // ---------------------------------------------------------------- validation

  bool _validateCurrentStep() {
    setState(() => _errors.clear());
    switch (_step) {
      case 0:
        if (_propertyType == null) _errors['propertyType'] = 'Select a property type';
        if (_title.text.trim().isEmpty) _errors['title'] = 'Title is required';
        final price = double.tryParse(_price.text.trim());
        if (price == null || price <= 0) _errors['price'] = 'Enter a valid price';
        break;
      case 1:
        final type = _propertyType;
        if (type != null) {
          for (final f in fieldsFor(type)) {
            if (f.type == FieldType.amenities || f.type == FieldType.boolean) continue;
            final v = _fieldValue(f);
            final s = v?.toString().trim() ?? '';
            if (f.required && s.isEmpty) {
              _errors[f.key] = '${f.label} is required';
            } else if (s.isNotEmpty && f.type == FieldType.number && double.tryParse(s) == null) {
              _errors[f.key] = 'Enter a valid number';
            }
          }
        }
        break;
      case 2:
        if (_cityId == null) _errors['city'] = 'Select a city';
        if (_addr.text.trim().isEmpty) _errors['address'] = 'Address is required';
        break;
      case 4:
        if (_contactName.text.trim().isEmpty) _errors['contactName'] = 'Name is required';
        final phone = _contactPhone.text.trim();
        if (phone.isEmpty) {
          _errors['contactPhone'] = 'Phone number is required';
        } else if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
          _errors['contactPhone'] = 'Enter a valid phone number';
        }
        break;
    }
    if (_errors.isNotEmpty) setState(() {});
    return _errors.isEmpty;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/owner');
    }
  }

  // ---------------------------------------------------------------- payload

  double? _computeAreaSqft() {
    final type = _propertyType;
    if (type == null) return null;
    final unit = _values['areaUnit'] as String?;
    for (final key in primaryAreaKeys(type)) {
      final raw = _textOf(key);
      if (raw == null || raw.isEmpty) continue;
      final v = double.tryParse(raw);
      if (v != null && v > 0) return areaToSqft(v, unit);
    }
    return null;
  }

  int? _intFromDetails(String key) {
    final raw = _textOf(key) ?? _values[key]?.toString();
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw)?.round();
  }

  Map<String, dynamic> _buildDetails() {
    final type = _propertyType;
    final out = <String, dynamic>{};
    if (type == null) return out;
    for (final f in fieldsFor(type)) {
      if (f.type == FieldType.amenities) continue;
      if (f.type == FieldType.number || f.type == FieldType.text) {
        final raw = _textOf(f.key);
        if (raw == null || raw.isEmpty) continue;
        out[f.key] = f.type == FieldType.number ? (double.tryParse(raw) ?? raw) : raw;
      } else {
        final v = _values[f.key];
        if (v == null) continue;
        if (v is String && v.isEmpty) continue;
        out[f.key] = v;
      }
    }
    return out;
  }

  Map<String, dynamic> _payload() {
    final cities = ref.read(citiesProvider).valueOrNull;
    final city = cities?.where((c) => c.id == _cityId).firstOrNull;
    final details = _buildDetails();
    final type = _propertyType!;

    final furnishingField = fieldsFor(type).where((f) => f.key == 'furnishing').firstOrNull;
    final furnishing = furnishingField != null
        ? furnishingToApi('${_values['furnishing'] ?? 'Semi Furnished'}')
        : 'SemiFurnished';

    return {
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'propertyType': type.apiValue,
      'listingType': _listingType,
      'price': double.parse(_price.text.trim()),
      'areaSqft': _computeAreaSqft(),
      'bedrooms': _intFromDetails('bhk'),
      'bathrooms': _intFromDetails('bathrooms'),
      'furnishing': furnishing,
      'addressLine': _addr.text.trim(),
      'cityId': _cityId,
      'localityId': _localityId,
      'latitude': city?.latitude ?? 18.5204,
      'longitude': city?.longitude ?? 73.8567,
      'imageUrls': _uploadedImageUrls,
      'amenities': _selectedAmenities,
      'details': details,
      'contactName': _contactName.text.trim(),
      'contactPhone': _contactPhone.text.trim(),
      'whatsApp': _whatsapp.text.trim().isEmpty
          ? _contactPhone.text.trim()
          : _whatsapp.text.trim(),
    };
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;
    final area = _computeAreaSqft();
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A valid area is required for the primary area field.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = _payload();
      if (widget.editId != null) {
        await updateProperty(ref, widget.editId!, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing updated successfully!')),
          );
          context.go('/owner');
        }
      } else {
        await createProperty(ref, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property submitted for admin approval!')),
          );
          context.go('/owner');
        }
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed ${widget.editId != null ? 'updating' : 'creating'} listing: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId != null ? 'Edit Property' : 'Post New Property'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _stepHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildStep(),
                  ),
                ),
                _bottomBar(context),
              ],
            ),
    );
  }

  Widget _stepHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step ${_step + 1} of 7',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _StepTitles.names[_step],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: (_step + 1) / 7, minHeight: 6),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final isLast = _step == 6;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: _submitting ? null : _back,
              icon: const Icon(Icons.arrow_back),
              label: Text(_step == 0 ? 'Cancel' : 'Back'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _submitting
                  ? null
                  : isLast
                      ? _submit
                      : _next,
              icon: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.check : Icons.arrow_forward),
              label: Text(isLast
                  ? (widget.editId != null ? 'Save Changes' : 'Submit for Approval')
                  : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
        0 => _basicStep(),
        1 => _detailsStep(),
        2 => _locationStep(),
        3 => _photosStep(),
        4 => _contactStep(),
        5 => _previewStep(),
        _ => _submitStep(),
      };

  // ------------------------------------------------------------ step 1: basic

  Widget _basicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertySection(
          title: 'Listing Type',
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Sale', label: Text('Sell'), icon: Icon(Icons.sell)),
                ButtonSegment(value: 'Rent', label: Text('Rent'), icon: Icon(Icons.key)),
              ],
              selected: {_listingType == 'Rent' ? 'Rent' : 'Sale'},
              onSelectionChanged: (s) => setState(() => _listingType = s.first),
            ),
          ],
        ),
        PropertySection(
          title: 'Property Type',
          children: [
            DropdownButtonFormField<PropertyType>(
              isExpanded: true,
              value: _propertyType,
              decoration: InputDecoration(
                labelText: 'Property Type *',
                errorText: _errors['propertyType'],
                border: const OutlineInputBorder(),
              ),
              items: PropertyType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _propertyType = v;
                _errors.remove('propertyType');
              }),
            ),
          ],
        ),
        PropertySection(
          title: 'Basic Information',
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Property Title *',
                errorText: _errors['title'],
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (₹) *',
                hintText: 'e.g. 6500000',
                errorText: _errors['price'],
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------- step 2: details

  Widget _detailsStep() {
    final type = _propertyType;
    if (type == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select a property type in Step 1 to see its fields.'),
        ),
      );
    }
    final fields = fieldsFor(type);
    // Ensure text/number controllers exist before the form builds (values are
    // bound to controllers, not the values map).
    for (final f in fields) {
      if (f.type == FieldType.number || f.type == FieldType.text) _controllerFor(f.key);
    }
    return PropertySection(
      title: '${type.label} Details',
      children: [
        DynamicPropertyForm(
          fields: fields,
          controllers: _fieldControllers,
          values: _values,
          errors: _errors,
          onValueChanged: _setValue,
          selectedAmenities: _selectedAmenities,
          onToggleAmenity: (a, sel) => setState(() {
            if (sel) {
              if (!_selectedAmenities.contains(a)) _selectedAmenities.add(a);
            } else {
              _selectedAmenities.remove(a);
            }
          }),
        ),
      ],
    );
  }

  // --------------------------------------------------------- step 3: location

  Widget _locationStep() {
    final citiesAsync = ref.watch(citiesProvider);
    return PropertySection(
      title: 'Location',
      children: [
        citiesAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
          error: (e, _) => Text('Failed to load cities: $e'),
          data: (cities) => DropdownButtonFormField<String>(
            isExpanded: true,
            value: _cityId != null && cities.any((c) => c.id == _cityId) ? _cityId : null,
            decoration: InputDecoration(
              labelText: 'City *',
              errorText: _errors['city'],
              border: const OutlineInputBorder(),
            ),
            items: cities
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name}, ${c.state}', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _cityId = v;
              _localityId = null;
              _errors.remove('city');
            }),
          ),
        ),
        const SizedBox(height: 12),
        if (_cityId != null) _localityDropdown(),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addr,
          decoration: InputDecoration(
            labelText: 'Address / Landmark *',
            errorText: _errors['address'],
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _localityDropdown() {
    final async = ref.watch(localitiesProvider(_cityId!));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (localities) => localities.isEmpty
          ? const SizedBox.shrink()
          : DropdownButtonFormField<String>(
              isExpanded: true,
              value: _localityId != null && localities.any((l) => l.id == _localityId)
                  ? _localityId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Locality',
                border: OutlineInputBorder(),
              ),
              items: localities
                  .map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _localityId = v),
            ),
    );
  }

  // ------------------------------------------------------------ step 4: photos

  Widget _photosStep() {
    return PropertySection(
      title: 'Property Photos',
      children: [
        OutlinedButton.icon(
          onPressed: _uploading ? null : _pickAndUploadImages,
          icon: _uploading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add_a_photo),
          label: Text(_uploading ? 'Uploading image...' : 'Pick & Upload Photos from Gallery'),
        ),
        if (_uploadedImageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _uploadedImageUrls.length,
            itemBuilder: (ctx, i) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    normalizeImageUrl(_uploadedImageUrls[i]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.grey, child: Icon(Icons.broken_image)),
                  ),
                ),
                Positioned(
                  top: 4, right: 4,
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
        ],
      ],
    );
  }

  // ----------------------------------------------------------- step 5: contact

  Widget _contactStep() {
    return PropertySection(
      title: 'Contact Information',
      children: [
        TextFormField(
          controller: _contactName,
          decoration: InputDecoration(
            labelText: 'Contact Name *',
            errorText: _errors['contactName'],
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contactPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number *',
            errorText: _errors['contactPhone'],
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'WhatsApp Number (optional)',
            hintText: 'Defaults to phone number if empty',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ step 6: preview

  Widget _previewStep() {
    final citiesAsync = ref.watch(citiesProvider);
    final cities = citiesAsync.valueOrNull;
    final city = cities?.where((c) => c.id == _cityId).firstOrNull;
    final localities = _localityId != null
        ? ref.watch(localitiesProvider(_cityId ?? '')).valueOrNull
        : null;
    final locality = localities?.where((l) => l.id == _localityId).firstOrNull;
    final area = _computeAreaSqft();
    final type = _propertyType ?? PropertyType.apartment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_uploadedImageUrls.isNotEmpty)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    normalizeImageUrl(_uploadedImageUrls.first),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.grey, child: Icon(Icons.broken_image, size: 40)),
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.home_work_outlined, size: 48, color: Colors.grey),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title.text.trim().isEmpty ? 'Untitled Property' : _title.text.trim(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatINR(double.tryParse(_price.text.trim()) ?? 0),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(type.label),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          avatar: const Icon(Icons.swap_horiz, size: 16),
                          label: Text(_listingType == 'Rent' ? 'For Rent' : 'For Sale'),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (area != null)
                          Chip(
                            avatar: const Icon(Icons.aspect_ratio, size: 16),
                            label: Text('${area.toStringAsFixed(0)} sqft'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              _addr.text.trim(),
                              locality?.name,
                              city?.name,
                            ].where((s) => s != null && s.isNotEmpty).join(', '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (_desc.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_desc.text.trim(), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _detailsPreview(type),
        if (_selectedAmenities.isNotEmpty) ...[
          const SizedBox(height: 4),
          PropertySection(
            title: 'Amenities',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _selectedAmenities
                    .map((a) => Chip(label: Text(a), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            ],
          ),
        ],
        PropertySection(
          title: 'Contact',
          children: [
            _previewRow(Icons.person, _contactName.text.trim().isEmpty
                ? '—' : _contactName.text.trim()),
            _previewRow(Icons.phone, _contactPhone.text.trim().isEmpty
                ? '—' : _contactPhone.text.trim()),
            _previewRow(Icons.chat, _whatsapp.text.trim().isEmpty
                ? '—' : _whatsapp.text.trim()),
          ],
        ),
      ],
    );
  }

  Widget _detailsPreview(PropertyType type) {
    final rows = <Widget>[];
    for (final f in fieldsFor(type)) {
      if (f.type == FieldType.amenities) continue;
      final v = _fieldValue(f);
      String text;
      if (f.type == FieldType.boolean) {
        if (v != true) continue;
        text = 'Yes';
      } else {
        final s = v?.toString().trim() ?? '';
        if (s.isEmpty) continue;
        text = f.unit != null ? '$s ${f.unit}' : s;
      }
      rows.add(_previewRow(_iconForKey(f.key), '${f.label}: $text'));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return PropertySection(title: 'Property Details', children: rows);
  }

  static IconData _iconForKey(String key) {
    if (key.toLowerCase().contains('area')) return Icons.aspect_ratio;
    if (key.toLowerCase().contains('floor')) return Icons.stairs;
    if (key.toLowerCase().contains('parking')) return Icons.local_parking;
    if (key.toLowerCase().contains('bath')) return Icons.bathtub;
    if (key.toLowerCase().contains('bhk') || key == 'beds') return Icons.bed;
    if (key.toLowerCase().contains('facing')) return Icons.explore;
    if (key.toLowerCase().contains('road')) return Icons.add_road;
    if (key.toLowerCase().contains('power') || key.toLowerCase().contains('electric')) {
      return Icons.bolt;
    }
    return Icons.info_outline;
  }

  Widget _previewRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );

  // ------------------------------------------------------------ step 7: submit

  Widget _submitStep() {
    final type = _propertyType ?? PropertyType.apartment;
    final area = _computeAreaSqft();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready to submit',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _summaryRow('Title', _title.text.trim()),
                _summaryRow('Type', type.label),
                _summaryRow('Listing', _listingType == 'Rent' ? 'For Rent' : 'For Sale'),
                _summaryRow('Price', formatINR(double.tryParse(_price.text.trim()) ?? 0)),
                if (area != null) _summaryRow('Area', '${area.toStringAsFixed(0)} sqft'),
                _summaryRow('City', _cityName() ?? '—'),
                _summaryRow('Address', _addr.text.trim()),
                _summaryRow('Photos', '${_uploadedImageUrls.length}'),
                _summaryRow('Contact', _contactName.text.trim()),
                _summaryRow('Phone', _contactPhone.text.trim()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_send, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.editId != null
                      ? 'Your changes will be saved and re-reviewed by the admin.'
                      : 'Your property will be submitted for admin approval. '
                          'You can track its status from your dashboard.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _cityName() {
    final cities = ref.read(citiesProvider).valueOrNull;
    return cities?.where((c) => c.id == _cityId).firstOrNull?.name;
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade700)),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
