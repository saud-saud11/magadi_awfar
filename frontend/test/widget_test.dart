import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magadi_awfar/main.dart';
import 'package:magadi_awfar/services/offline_catalog.dart';

void main() {
  testWidgets('App renders Arabic home screen with search and district', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MagadiAwfarApp());
    await tester.pump();

    // Verify app brand is rendered
    expect(find.text('مقاضي أوفر'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('بالصوت'), findsOneWidget);
    expect(find.text('مقاضي البيت'), findsOneWidget);
    expect(find.text('السلة'), findsOneWidget);
  });

  test(
    'Search sensitivity: searching for barley drink matches barley drinks and NEVER matches rice',
    () {
      final res = OfflineCatalog.search(query: 'شراب شعير');
      expect(res.matchedProducts.isNotEmpty, isTrue);
      for (var prod in res.matchedProducts) {
        expect(
          prod.nameAr.contains('أرز') || prod.nameAr.contains('الشعلان'),
          isFalse,
        );
        expect(
          prod.nameAr.contains('شعير') ||
              prod.nameAr.contains('موسي') ||
              prod.nameAr.contains('بربيكان'),
          isTrue,
        );
      }
    },
  );

  test(
    'Search sensitivity: searching for rice matches rice and NEVER barley drink',
    () {
      final res = OfflineCatalog.search(query: 'رز الشعلان');
      expect(res.matchedProducts.isNotEmpty, isTrue);
      for (var prod in res.matchedProducts) {
        expect(
          prod.nameAr.contains('الشعلان') || prod.nameAr.contains('أرز'),
          isTrue,
        );
        expect(
          prod.nameAr.contains('شعير') || prod.nameAr.contains('موسي'),
          isFalse,
        );
      }
    },
  );

  test(
    'Search sensitivity: unknown query returns 0 matched products and no false staples',
    () {
      final res = OfflineCatalog.search(query: 'منتج_غير_موجود_١٢٣٤٥');
      expect(res.matchedProducts.isEmpty, isTrue);
    },
  );
}
