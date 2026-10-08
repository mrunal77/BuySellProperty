import 'package:buysell_mobile/src/features/listing_editor/domain/property_type_config.dart';
import 'package:buysell_mobile/src/features/search/data/properties_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertySearchFilterConfig Unit Tests', () {
    test('Shows BHK for residential types (Apartment, House, Villa)', () {
      final aptConfig = PropertySearchFilterConfig.forType(PropertyType.apartment);
      expect(aptConfig.showBhk, isTrue);
      expect(aptConfig.showBathrooms, isTrue);
      expect(aptConfig.showFurnishing, isTrue);

      final villaConfig = PropertySearchFilterConfig.forType(PropertyType.villa);
      expect(villaConfig.showBhk, isTrue);
    });

    test('Hides BHK and Bathrooms for Plot', () {
      final plotConfig = PropertySearchFilterConfig.forType(PropertyType.plot);
      expect(plotConfig.showBhk, isFalse);
      expect(plotConfig.showBathrooms, isFalse);
      expect(plotConfig.showFurnishing, isFalse);
      expect(plotConfig.showFacing, isTrue);
    });

    test('Hides BHK for Commercial Shop and Office', () {
      final shopConfig = PropertySearchFilterConfig.forType(PropertyType.shop);
      expect(shopConfig.showBhk, isFalse);
      expect(shopConfig.showBathrooms, isTrue);
      expect(shopConfig.showFurnishing, isTrue);
    });
  });

  group('PropertyQuery Serialization Tests', () {
    test('toMap serializes keyword, price range, and sorting correctly', () {
      const q = PropertyQuery(
        keyword: 'Manish Nagar',
        listingType: 'Sale',
        minPrice: 3000000,
        maxPrice: 6000000,
        beds: 2,
        sort: 'price_asc',
      );

      final map = q.toMap();
      expect(map['keyword'], 'Manish Nagar');
      expect(map['listingType'], 'Sale');
      expect(map['minPrice'], 3000000);
      expect(map['maxPrice'], 6000000);
      expect(map['beds'], 2);
      expect(map['sort'], 'price_asc');
    });

    test('PropertyQuery equality and hashCode check', () {
      const q1 = PropertyQuery(keyword: 'Nagpur', minPrice: 1000);
      const q2 = PropertyQuery(keyword: 'Nagpur', minPrice: 1000);
      const q3 = PropertyQuery(keyword: 'Pune', minPrice: 1000);

      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
      expect(q1, isNot(equals(q3)));
    });
  });
}
