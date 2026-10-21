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
}
