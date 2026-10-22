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
  List<StoreOffer> offers = const [],
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
  offers: offers,
);

StoreOffer offer(
  String store,
  int price, {
  int minutes = 1,
  String sku = '1',
  bool stock = true,
}) => StoreOffer.fromJson({
  'store_code': store,
  'price_halalas': price,
  'price_sar': price / 100,
  'price_verified': true,
  'stock_known': true,
  'is_in_stock': stock,
  'product_url': 'https://$store.example/$sku',
  'last_verified_at': DateTime.now()
      .toUtc()
      .subtract(Duration(minutes: minutes))
      .toIso8601String(),
});

void main() {
  test(
    'one canonical card preserves current store offers and is idempotent',
    () {
      final a = item(
        11,
        'المراعي لبن',
        canonical: 'product:11',
        aliases: [11, 22],
        offers: [offer('danube', 700)],
      );
      final b = item(
        22,
        'Almarai Fresh Laban',
        canonical: 'product:11',
        aliases: [11, 22],
        offers: [offer('panda', 600)],
      );
      final merged = ProductMatching.consolidateCards([a, b]);
      expect(merged, hasLength(1));
      expect(merged.single.id, 11);
      expect(merged.single.catalogProductIds, [11, 22]);
      expect(merged.single.offers.map((o) => o.storeCode), ['panda', 'danube']);
      expect(merged.single.offers.map((o) => o.isCheapestProduct), [
        true,
        false,
      ]);
      expect(
        ProductMatching.consolidateCards([b, a]).single.toJson(),
        merged.single.toJson(),
      );
      expect(
        ProductMatching.consolidateCards(merged).single.toJson(),
        merged.single.toJson(),
      );
    },
  );
  test(
    'newer observation wins over an older cheaper price for the same listing',
    () {
      final a = item(
        11,
        'لبن',
        offers: [
          offer('danube', 300, minutes: 60),
          offer('panda', 200, minutes: 1500),
        ],
      );
      final b = item(
        11,
        'لبن',
        offers: [
          offer('danube', 700),
          offer('danube', 100, sku: '2', stock: false),
        ],
      );
      for (final inputs in [
        [a, b],
        [b, a],
      ]) {
        final merged = ProductMatching.consolidateCards(inputs);
        expect(merged.single.offers, hasLength(1));
        expect(merged.single.offers.single.priceHalalas, 700);
        expect(merged.single.offers.single.isInStock, isTrue);
      }
    },
  );
  test(
    'same wording does not override server splits or conflicting specifications',
    () {
      final a = item(11, 'لبن', canonical: 'product:11');
      for (final b in [
        item(22, 'لبن', canonical: 'product:22'),
        item(11, 'لبن', canonical: 'product:11', amount: 500),
        item(11, 'لبن', canonical: 'product:11', pack: 6),
      ]) {
        expect(ProductMatching.consolidateCards([a, b]), hasLength(2));
      }
      final left = item(11, 'لبن', aliases: [11, 22], barcode: '6281007117913');
      final bridge = item(22, 'لبن', aliases: [11, 22, 33]);
      final right = item(
        33,
        'لبن',
        aliases: [22, 33],
        barcode: '6281007118132',
      );
      expect(
        ProductMatching.consolidateCards([left, bridge, right]),
        hasLength(3),
      );
      expect(
        ProductMatching.consolidateCards([right, bridge, left]),
        hasLength(3),
      );
    },
  );
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
      expect(
        ProductMatching.measurement(
          'بامبرز كلوت (5) 12-18 كيلو صندوق جامبو 72 حفاض',
        ),
        (amount: 72.0, unit: 'count', pack: null),
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
