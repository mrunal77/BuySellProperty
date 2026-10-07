import 'package:buysell_mobile/src/features/listing_editor/domain/property_type_config.dart';
import 'package:buysell_mobile/src/features/listing_editor/presentation/listing_editor_screen.dart';
import 'package:buysell_mobile/src/features/search/data/properties_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _pune = CityDto.fromJson(const {
  'id': 'c1',
  'name': 'Pune',
  'state': 'MH',
  'latitude': 18.5204,
  'longitude': 73.8567,
});

Widget _app() => ProviderScope(
      overrides: [
        citiesProvider.overrideWith((ref) async => [_pune]),
        localitiesProvider.overrideWith((ref, cityId) async => []),
      ],
      child: const MaterialApp(home: ListingEditorScreen()),
    );

void main() {
  testWidgets('dynamic wizard: step-by-step flow for Apartment', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Step 1: Basic Information
    expect(find.text('Step 1 of 7'), findsOneWidget);

    // Next is blocked without a property type / title / price.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Select a property type'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);

    // Select property type and fill common fields.
    await tester.tap(find.text('Property Type *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apartment').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Property Title *'), 'Sunlit 2 BHK Apartment');
    await tester.enterText(find.widgetWithText(TextFormField, 'Price (₹) *'), '6500000');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 7'), findsOneWidget);

    // Step 2: type-specific dynamic fields appear for Apartment.
    expect(find.text('BHK Configuration'), findsOneWidget);
    expect(find.text('Carpet Area'), findsOneWidget);
    expect(find.text('Car Parking'), findsOneWidget);

    // Required dynamic fields block advancing when empty.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('BHK Configuration is required'), findsOneWidget);
    expect(find.text('Carpet Area is required'), findsOneWidget);

    await tester.tap(find.text('BHK Configuration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Bathrooms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bathrooms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Furnishing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Furnishing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semi Furnished').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Carpet Area'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Carpet Area'), '1100');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 7'), findsOneWidget);

    // Step 3: Location — city + address required.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Select a city'), findsOneWidget);

    await tester.tap(find.text('City *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pune, MH').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Address / Landmark *'), 'Koregaon Park, Lane 5');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 4 of 7'), findsOneWidget);

    // Step 4: Photos are optional.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 5 of 7'), findsOneWidget);

    // Step 5: Contact — phone validated.
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact Name *'), 'Amit');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number *'), '987');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid phone number'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number *'), '9876543210');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 6 of 7'), findsOneWidget);

    // Step 6: Preview shows what will be published.
    expect(find.text('Sunlit 2 BHK Apartment'), findsOneWidget);
    expect(find.text('Apartment'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 7 of 7'), findsOneWidget);
    expect(find.text('Ready to submit'), findsOneWidget);
    expect(find.text('Submit for Approval'), findsOneWidget);
  });

  testWidgets('dynamic wizard: switching type swaps fields and keeps values', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Property Type *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plot').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Property Title *'), 'Industrial Plot');
    await tester.enterText(find.widgetWithText(TextFormField, 'Price (₹) *'), '2500000');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Plot config: no BHK, but areaUnit + plotType shown.
    expect(find.text('BHK Configuration'), findsNothing);
    expect(find.text('Plot Area'), findsOneWidget);
    expect(find.text('Area Unit'), findsOneWidget);
    expect(find.text('Plot Type'), findsOneWidget);
    expect(find.text('Land Use'), findsOneWidget);

    // Back to step 1: values entered earlier are preserved.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Industrial Plot'), findsOneWidget);
    expect(find.text('Plot'), findsOneWidget);

    // Switch type to Villa.
    await tester.tap(find.byType(DropdownButtonFormField<PropertyType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Villa').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('BHK Configuration'), findsOneWidget);
    expect(find.text('Built-Up Area'), findsOneWidget);
    // 'Swimming Pool' also exists as an amenity chip, hence findsWidgets.
    expect(find.text('Swimming Pool'), findsWidgets);
    expect(find.text('Garden'), findsOneWidget);
    // Plot-only fields disappear for Villa.
    expect(find.text('Land Use'), findsNothing);
    expect(find.text('Area Unit'), findsNothing);
  });
}