import 'package:flutter_test/flutter_test.dart';
import 'package:magadi_awfar/models/models.dart';
import 'package:magadi_awfar/services/product_matching.dart';

ProductItem item(
  int id,
  String name, {
  String? canonical,
  List<int> aliases = const [],
  String? barcode,
  double amount = 1000,
  int pack = 1,
}) => ProductItem(
  id: id,
  nameAr: name,
  canonicalId: canonical,
  catalogProductIds: aliases,
  matchingMethod: 'specifications',
  gtinBarcode: barcode,
  normalizedSizeAmount: amount,
  normalizedSizeUnit: 'ml',
  packCount: pack,
  offers: [],
);

void main() {
  test(
    'saved basket keeps canonical identity and source aliases after restart',
    () {
      final old = item(22, 'المراعي لبن كامل الدسم 1 لتر');
      final fresh = item(
        11,
        'المراعي لبن طازج كامل الدسم ١لتر',
        canonical: 'product:11',
        aliases: [11, 22, 33],
      );
      final restored = ProductItem.fromJson(fresh.toJson());
      expect(restored.canonicalId, 'product:11');
      expect(restored.catalogProductIds, [11, 22, 33]);
      expect(restored.matchingMethod, 'specifications');
      expect(ProductMatching.sameProduct(old, restored), isTrue);
      expect(ProductMatching.sameProduct(restored, old), isTrue);
    },
  );
  test(
    'ambiguous server variants, changed sizes and conflicting barcodes stay separate',
    () {
      final a = item(11, 'لبن المراعي', canonical: 'product:11');
      final b = item(22, 'لبن المراعي', canonical: 'product:22');
      expect(ProductMatching.sameProduct(a, b), isFalse);
      expect(
        ProductMatching.sameProduct(a, item(11, 'لبن المراعي', amount: 500)),
        isFalse,
      );
      expect(
        ProductMatching.sameProduct(a, item(11, 'لبن المراعي', pack: 6)),
        isFalse,
      );
      expect(
        ProductMatching.sameProduct(
          item(11, 'لبن المراعي', barcode: '6281007117913'),
          item(22, 'لبن المراعي', barcode: '6281007118132'),
        ),
        isFalse,
      );
    },
  );
  test(
    'barcode padding is equivalent but does not override an explicit server split',
    () {
      final a = item(11, 'لبن المراعي', barcode: '6281007117913');
      final b = item(22, 'Almarai Laban', barcode: '06281007117913');
      expect(ProductMatching.sameProduct(a, b), isTrue);
      expect(
        ProductMatching.sameProduct(
          item(
            11,
            'full fat',
            barcode: '6281007117913',
            canonical: 'product:11',
          ),
          item(
            22,
            'low fat',
            barcode: '6281007117913',
            canonical: 'product:22',
          ),
        ),
        isFalse,
      );
    },
  );
  test(
    'nested packs, counted products and uncertain sizes stay aligned with the server',
    () {
      expect(ProductMatching.measurement('3*6*250ml'), (
        amount: 250.0,
        unit: 'ml',
        pack: 18,
      ));
      expect(ProductMatching.measurement('2*(6*250ml)'), (
        amount: 250.0,
        unit: 'ml',
        pack: 12,
      ));
      expect(
        ProductMatching.measurement('Pampers Diapers Size 3 (4-9kg) 60 pcs'),
        (amount: 60.0, unit: 'count', pack: null),
      );
      for (final title in [
        '330-355 ML',
        'Pepsi 15*150ml & Pepsi Diet 15*150ml',
        'multipack 150ml',
        'Detergent 2.25kg 25kg',
      ]) {
        expect(
          ProductMatching.measurement(title).amount,
          isNull,
          reason: title,
        );
      }
      final counted = ProductItem.fromJson({
        'id': 1,
        'name_ar': 'حفاضات',
        'normalized_size_amount': 52,
        'normalized_size_unit': 'count',
        'pack_count': 1,
        'quantity_status': 'exact',
      });
      expect(counted.displaySize, '52 قطعة');
      expect(counted.displayPackBadge, 'عبوة واحدة');
      final uncertain = ProductItem.fromJson({
        'id': 2,
        'name_ar': 'بيبسي 330–355 مل',
        'quantity_status': 'range',
      });
      expect(uncertain.displaySize, 'الحجم أو عدد العبوات غير مؤكد');
      expect(ProductItem.fromJson(uncertain.toJson()).quantityStatus, 'range');
      expect(ProductMatching.sameProduct(uncertain, uncertain), isFalse);
    },
  );
}
