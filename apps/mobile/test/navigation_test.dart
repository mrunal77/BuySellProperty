import 'package:buysell_mobile/src/core/browse_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _property = {
  'id': 'abc-123',
  'title': 'Sunny 2BHK',
  'price': 7500000,
  'propertyType': 'Apartment',
  'listingType': 'Sale',
  'areaSqft': 1100,
  'bedrooms': 2,
};

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: PropertyCard(p: _property)),
        ),
        GoRoute(
          path: '/p/:id',
          builder: (_, s) => Scaffold(
            appBar: AppBar(),
            body: Text('detail ${s.pathParameters['id']}'),
          ),
        ),
      ],
    );

void main() {
  testWidgets('tapping a card pushes detail; system back returns to the list',
      (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    expect(find.text('Sunny 2BHK'), findsOneWidget);

    await tester.tap(find.text('Sunny 2BHK'));
    await tester.pumpAndSettle();
    expect(find.text('detail abc-123'), findsOneWidget);

    // System back button must pop within the app, not exit it.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Sunny 2BHK'), findsOneWidget);
    expect(find.text('detail abc-123'), findsNothing);
  });
}
