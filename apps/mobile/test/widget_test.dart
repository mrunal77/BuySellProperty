// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buysell_mobile/main.dart';
import 'package:buysell_mobile/src/features/search/data/properties_api.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        propertySearchProvider.overrideWith((ref, q) async =>
            {'data': <Object>[], 'page': 1, 'pageSize': 20, 'total': 0}),
        citiesProvider.overrideWith((ref) async => []),
      ],
      child: const BuySellApp(),
    ));
    await tester.pump();
  });
}
