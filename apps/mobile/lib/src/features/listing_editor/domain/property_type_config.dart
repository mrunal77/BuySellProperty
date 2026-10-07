/// Property type configuration driving the dynamic listing form.
///
/// One source of truth per property type: which fields exist, their kind,
/// options, units and whether they are required. Common fields (title, price,
/// description, location, photos, contact) live in the wizard itself and are
/// never repeated here.
library;

enum PropertyType {
  apartment,
  independentHouse,
  villa,
  plot,
  shop,
  office,
  warehouse,
  industrial,
  farmhouse,
  pg,
  // Pre-existing backend types kept so editing older listings never
  // silently changes the property type.
  commercial,
  studio;

  String get apiValue => switch (this) {
        PropertyType.apartment => 'Apartment',
        PropertyType.independentHouse => 'IndependentHouse',
        PropertyType.villa => 'Villa',
        PropertyType.plot => 'Plot',
        PropertyType.shop => 'Shop',
        PropertyType.office => 'Office',
        PropertyType.warehouse => 'Warehouse',
        PropertyType.industrial => 'Industrial',
        PropertyType.farmhouse => 'Farmhouse',
        PropertyType.pg => 'PG',
        PropertyType.commercial => 'Commercial',
        PropertyType.studio => 'Studio',
      };

  String get label => switch (this) {
        PropertyType.apartment => 'Apartment',
        PropertyType.independentHouse => 'Independent House',
        PropertyType.villa => 'Villa',
        PropertyType.plot => 'Plot',
        PropertyType.shop => 'Shop',
        PropertyType.office => 'Office Space',
        PropertyType.warehouse => 'Warehouse',
        PropertyType.industrial => 'Industrial Property',
        PropertyType.farmhouse => 'Farmhouse',
        PropertyType.pg => 'PG / Hostel',
        PropertyType.commercial => 'Commercial / Retail',
        PropertyType.studio => 'Studio Apartment',
      };

  static PropertyType? tryFromApi(String? v) {
    for (final t in PropertyType.values) {
      if (t.apiValue == v) return t;
    }
    return null;
  }
}

enum FieldType { number, text, dropdown, boolean, amenities }

class FieldDef {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final String? unit;
  final List<String>? options;
  final int maxLines;

  const FieldDef(
    this.key,
    this.label, {
    this.type = FieldType.text,
    this.required = false,
    this.unit,
    this.options,
    this.maxLines = 1,
  });
}

const _furnishingOptions = ['Unfurnished', 'Semi Furnished', 'Furnished'];
const _facingOptions = [
  'North', 'South', 'East', 'West',
  'North East', 'North West', 'South East', 'South West',
];
const _ageOptions = ['New', '0-5 Years', '5-10 Years', '10-15 Years', '15+ Years'];
const _possessionOptions = ['Ready to Move', 'Under Construction', 'Within 6 Months', 'Within 1 Year'];
const _waterOptions = ['Municipal Supply', 'Borewell', 'Tanker', '24x7 Supply'];
const _bhkOptions = ['1', '1.5', '2', '2.5', '3', '4', '5', '6+'];
const _bathOptions = ['1', '2', '3', '4', '5', '6'];

const _amenitiesField = FieldDef('amenities', 'Amenities', type: FieldType.amenities);

/// Fields shown for each property type, in display order.
Map<PropertyType, List<FieldDef>> propertyTypeFields() => {
      PropertyType.apartment: const [
        FieldDef('bhk', 'BHK Configuration', type: FieldType.dropdown, options: _bhkOptions, required: true),
        FieldDef('subType', 'Apartment Sub-Type', type: FieldType.dropdown,
            options: ['Apartment', 'Studio', 'Penthouse', 'Builder Floor']),
        FieldDef('carpetArea', 'Carpet Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('bathrooms', 'Bathrooms', type: FieldType.dropdown, options: _bathOptions, required: true),
        FieldDef('balcony', 'Balconies', type: FieldType.number),
        FieldDef('floor', 'Floor', type: FieldType.number),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('facing', 'Facing', type: FieldType.dropdown, options: _facingOptions),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('parking', 'Car Parking', type: FieldType.boolean),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
        FieldDef('possessionStatus', 'Possession Status', type: FieldType.dropdown, options: _possessionOptions),
        FieldDef('maintenance', 'Maintenance (₹/month)', type: FieldType.number),
        _amenitiesField,
      ],
      PropertyType.independentHouse: const [
        FieldDef('bhk', 'BHK Configuration', type: FieldType.dropdown, options: _bhkOptions, required: true),
        FieldDef('carpetArea', 'Carpet Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('plotArea', 'Plot Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('bathrooms', 'Bathrooms', type: FieldType.dropdown, options: _bathOptions, required: true),
        FieldDef('balcony', 'Balconies', type: FieldType.number),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('facing', 'Facing', type: FieldType.dropdown, options: _facingOptions),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('parking', 'Car Parking', type: FieldType.boolean),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
        FieldDef('waterSupply', 'Water Supply', type: FieldType.dropdown, options: _waterOptions),
        _amenitiesField,
      ],
      PropertyType.villa: const [
        FieldDef('bhk', 'BHK Configuration', type: FieldType.dropdown, options: _bhkOptions, required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('plotArea', 'Plot Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('carpetArea', 'Carpet Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('bathrooms', 'Bathrooms', type: FieldType.dropdown, options: _bathOptions, required: true),
        FieldDef('balcony', 'Balconies', type: FieldType.number),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('facing', 'Facing', type: FieldType.dropdown, options: _facingOptions),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('garden', 'Garden', type: FieldType.boolean),
        FieldDef('swimmingPool', 'Swimming Pool', type: FieldType.boolean),
        FieldDef('parking', 'Car Parking', type: FieldType.boolean),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
        FieldDef('possessionStatus', 'Possession Status', type: FieldType.dropdown, options: _possessionOptions),
        _amenitiesField,
      ],
      PropertyType.plot: const [
        FieldDef('plotArea', 'Plot Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('areaUnit', 'Area Unit', type: FieldType.dropdown,
            options: ['sqft', 'sq.m', 'sq.yd', 'acre', 'hectare'], required: true),
        FieldDef('plotType', 'Plot Type', type: FieldType.dropdown,
            options: ['Residential Plot', 'Commercial Plot', 'Agricultural Land', 'Industrial Land', 'Farm Land'],
            required: true),
        FieldDef('landUse', 'Land Use', type: FieldType.dropdown,
            options: ['Residential', 'Commercial', 'Agricultural', 'Industrial', 'Mixed'], required: true),
        FieldDef('facing', 'Facing', type: FieldType.dropdown, options: _facingOptions),
        FieldDef('roadWidth', 'Road Width', type: FieldType.number, unit: 'ft'),
        FieldDef('roadConnectivity', 'Road Connectivity', type: FieldType.dropdown,
            options: ['Paved Road', 'Dirt Road', 'Highway Nearby']),
        FieldDef('cornerPlot', 'Corner Plot', type: FieldType.boolean),
        FieldDef('boundaryWall', 'Boundary Wall', type: FieldType.boolean),
        FieldDef('ownershipType', 'Ownership Type', type: FieldType.dropdown,
            options: ['Freehold', 'Leasehold', 'Power of Attorney']),
        FieldDef('developmentStatus', 'Development Status', type: FieldType.dropdown,
            options: ['Fully Developed', 'Partially Developed', 'Undeveloped']),
        FieldDef('waterAvailability', 'Water Availability', type: FieldType.boolean),
        FieldDef('electricityAvailability', 'Electricity Availability', type: FieldType.boolean),
      ],
      PropertyType.shop: const [
        FieldDef('carpetArea', 'Carpet Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('floor', 'Floor', type: FieldType.number),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('washroom', 'Washroom', type: FieldType.boolean),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('mainRoadFacing', 'Main Road Facing', type: FieldType.boolean),
        FieldDef('roadWidth', 'Road Width', type: FieldType.number, unit: 'ft'),
        FieldDef('suitableFor', 'Suitable For', maxLines: 2),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
        FieldDef('powerBackup', 'Power Backup', type: FieldType.boolean),
        FieldDef('waterSupply', 'Water Supply', type: FieldType.dropdown, options: _waterOptions),
      ],
      PropertyType.office: const [
        FieldDef('carpetArea', 'Carpet Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('floor', 'Floor', type: FieldType.number),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('cabins', 'Cabins', type: FieldType.number),
        FieldDef('workstations', 'Workstations', type: FieldType.number),
        FieldDef('conferenceRoom', 'Conference Room', type: FieldType.boolean),
        FieldDef('washrooms', 'Washrooms', type: FieldType.number),
        FieldDef('reception', 'Reception', type: FieldType.boolean),
        FieldDef('pantry', 'Pantry', type: FieldType.boolean),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('powerBackup', 'Power Backup', type: FieldType.boolean),
        FieldDef('lift', 'Lift', type: FieldType.boolean),
        FieldDef('security', '24x7 Security', type: FieldType.boolean),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
      ],
      PropertyType.warehouse: const [
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('plotArea', 'Plot Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('ceilingHeight', 'Ceiling Height', type: FieldType.number, unit: 'ft'),
        FieldDef('floor', 'Floor', type: FieldType.number),
        FieldDef('loadingUnloadingArea', 'Loading/Unloading Area', type: FieldType.boolean),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('shutters', 'Number of Shutters', type: FieldType.number),
        FieldDef('roadWidth', 'Road Width', type: FieldType.number, unit: 'ft'),
        FieldDef('powerSupply', 'Power Supply', type: FieldType.dropdown, options: ['3 Phase', '2 Phase', '1 Phase']),
        FieldDef('waterSupply', 'Water Supply', type: FieldType.dropdown, options: _waterOptions),
        FieldDef('fireSafety', 'Fire Safety Arrangements', type: FieldType.boolean),
        FieldDef('security', 'Security', type: FieldType.boolean),
        FieldDef('suitableFor', 'Suitable For', maxLines: 2),
      ],
      PropertyType.industrial: const [
        FieldDef('plotArea', 'Plot Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('factoryArea', 'Factory Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('ceilingHeight', 'Ceiling Height', type: FieldType.number, unit: 'ft'),
        FieldDef('powerLoad', 'Power Load', type: FieldType.number, unit: 'KW'),
        FieldDef('waterSupply', 'Water Supply', type: FieldType.dropdown, options: _waterOptions),
        FieldDef('roadWidth', 'Road Width', type: FieldType.number, unit: 'ft'),
        FieldDef('loadingUnloading', 'Loading/Unloading', type: FieldType.boolean),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('industrialZone', 'Industrial Zone'),
        FieldDef('fireSafety', 'Fire Safety Arrangements', type: FieldType.boolean),
        FieldDef('craneAvailability', 'Crane Availability', type: FieldType.boolean),
        FieldDef('officeSpace', 'Office Space', type: FieldType.boolean),
        FieldDef('storageSpace', 'Storage Space', type: FieldType.boolean),
      ],
      PropertyType.farmhouse: const [
        FieldDef('plotArea', 'Plot/Land Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('bhk', 'BHK Configuration', type: FieldType.dropdown, options: _bhkOptions, required: true),
        FieldDef('bathrooms', 'Bathrooms', type: FieldType.dropdown, options: _bathOptions, required: true),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('garden', 'Garden', type: FieldType.boolean),
        FieldDef('swimmingPool', 'Swimming Pool', type: FieldType.boolean),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('waterSource', 'Water Source', type: FieldType.dropdown,
            options: ['Borewell', 'Well', 'Municipal', 'River']),
        FieldDef('electricity', 'Electricity', type: FieldType.boolean),
        FieldDef('roadAccess', 'Road Access', type: FieldType.boolean),
        FieldDef('boundaryWall', 'Boundary Wall', type: FieldType.boolean),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions),
        FieldDef('facing', 'Facing', type: FieldType.dropdown, options: _facingOptions),
      ],
      PropertyType.pg: const [
        FieldDef('propertyArea', 'Property Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('totalRooms', 'Total Rooms', type: FieldType.number, required: true),
        FieldDef('beds', 'Beds', type: FieldType.number, required: true),
        FieldDef('occupancy', 'Occupancy', type: FieldType.dropdown,
            options: ['Boys', 'Girls', 'Co-ed'], required: true),
        FieldDef('attachedBathrooms', 'Attached Bathrooms', type: FieldType.number),
        FieldDef('commonBathrooms', 'Common Bathrooms', type: FieldType.number),
        FieldDef('foodAvailable', 'Food Available', type: FieldType.boolean),
        FieldDef('ac', 'AC', type: FieldType.boolean),
        FieldDef('wifi', 'Wi-Fi', type: FieldType.boolean),
        FieldDef('laundry', 'Laundry', type: FieldType.boolean),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('security', '24x7 Security', type: FieldType.boolean),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions),
        FieldDef('suitableFor', 'Suitable For', type: FieldType.dropdown,
            options: ['Students', 'Working Professionals', 'Families', 'Anyone']),
      ],
      PropertyType.commercial: const [
        FieldDef('carpetArea', 'Carpet Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('builtUpArea', 'Built-Up Area', type: FieldType.number, unit: 'sqft'),
        FieldDef('floor', 'Floor', type: FieldType.number),
        FieldDef('totalFloors', 'Total Floors', type: FieldType.number),
        FieldDef('washrooms', 'Washrooms', type: FieldType.number),
        FieldDef('facing', 'Facing', type: FieldType.dropdown, options: _facingOptions),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('parking', 'Parking', type: FieldType.boolean),
        FieldDef('powerBackup', 'Power Backup', type: FieldType.boolean),
        FieldDef('security', '24x7 Security', type: FieldType.boolean),
        FieldDef('waterSupply', 'Water Supply', type: FieldType.dropdown, options: _waterOptions),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
      ],
      PropertyType.studio: const [
        FieldDef('propertyArea', 'Property Area', type: FieldType.number, unit: 'sqft', required: true),
        FieldDef('bathrooms', 'Bathrooms', type: FieldType.dropdown, options: _bathOptions, required: true),
        FieldDef('balcony', 'Balconies', type: FieldType.number),
        FieldDef('kitchen', 'Kitchen', type: FieldType.boolean),
        FieldDef('furnishing', 'Furnishing', type: FieldType.dropdown, options: _furnishingOptions, required: true),
        FieldDef('parking', 'Car Parking', type: FieldType.boolean),
        FieldDef('ageOfProperty', 'Age of Property', type: FieldType.dropdown, options: _ageOptions),
        FieldDef('possessionStatus', 'Possession Status', type: FieldType.dropdown, options: _possessionOptions),
        _amenitiesField,
      ],
    };

List<FieldDef> fieldsFor(PropertyType type) => propertyTypeFields()[type] ?? const [];

/// Which field to feed into the legacy `area_sqft` column (search filter).
/// First key with a parseable value wins; keys are in priority order per type.
List<String> primaryAreaKeys(PropertyType type) => switch (type) {
      PropertyType.apartment ||
      PropertyType.independentHouse ||
      PropertyType.villa ||
      PropertyType.shop ||
      PropertyType.office ||
      PropertyType.commercial =>
        ['carpetArea', 'builtUpArea', 'plotArea', 'propertyArea'],
      PropertyType.plot ||
      PropertyType.industrial ||
      PropertyType.farmhouse =>
        ['plotArea', 'builtUpArea', 'carpetArea', 'propertyArea'],
      PropertyType.warehouse => ['builtUpArea', 'plotArea', 'carpetArea'],
      PropertyType.pg || PropertyType.studio => ['propertyArea', 'builtUpArea', 'carpetArea'],
    };

/// Area unit conversion to square feet.
double? areaToSqft(double value, String? unit) => switch (unit) {
      'sq.m' => value * 10.7639,
      'sq.yd' => value * 9,
      'acre' => value * 43560,
      'hectare' => value * 107639,
      _ => value,
    };

/// Display label for a details key (used by preview + property detail).
String labelForKey(String key) => fieldDefForKey(key)?.label ?? _humanizeKey(key);

FieldDef? fieldDefForKey(String key) {
  for (final list in propertyTypeFields().values) {
    for (final f in list) {
      if (f.key == key) return f;
    }
  }
  return null;
}

String _humanizeKey(String key) {
  final spaced = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').trim();
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Furnishing stored in DB as enum without spaces; UI shows with a space.
String furnishingToApi(String display) => switch (display.trim()) {
      'Semi Furnished' => 'SemiFurnished',
      'Furnished' => 'Furnished',
      _ => 'Unfurnished',
    };

String furnishingToDisplay(String? api) => switch (api) {
      'SemiFurnished' => 'Semi Furnished',
      'Furnished' => 'Furnished',
      _ => 'Unfurnished',
  };

const availableAmenities = [
  'Swimming Pool',
  'Gymnasium',
  '24x7 Security',
  'Power Backup',
  'Reserved Parking',
  'Clubhouse',
];
