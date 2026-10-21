import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:magadi_awfar/models/models.dart';
import 'package:magadi_awfar/services/live_danube_client.dart';
import 'package:magadi_awfar/services/offline_catalog.dart';
import 'package:magadi_awfar/services/product_matching.dart';
import 'package:magadi_awfar/services/local_voice_basket.dart';
import 'package:magadi_awfar/screens/basket_screen.dart';
import 'package:magadi_awfar/widgets/verified_product_card.dart';
import 'package:magadi_awfar/theme/app_theme.dart';

StoreOffer offer(
  int price, {
  String branch = 'online',
  bool verified = true,
  int age = 0,
}) => StoreOffer(
  id: 1,
  storeCode: 'danube',
  storeNameAr: 'الدانوب',
  branchNameAr: branch,
  priceHalalas: price,
  priceSar: price / 100,
  isOnSale: false,
  isInStock: true,
  stockKnown: true,
  productUrl: 'https://danube.sa',
  totalStatus: 'REQUIRES_STORE_CONFIRMATION',
  totalStatusText: 'الرسوم غير معروفة',
  isCheapestProduct: false,
  isCheapestTotal: false,
  priceVerified: verified,
  lastVerifiedAt: DateTime.now().toUtc().subtract(Duration(hours: age)),
);
ProductItem product({
  int id = 1,
  double amount = 500,
  String unit = 'g',
  int pack = 1,
  List<StoreOffer> offers = const [],
}) => ProductItem(
  id: id,
  nameAr: 'نوتيلا كريمة البندق $amount جرام',
  normalizedSizeAmount: amount,
  normalizedSizeUnit: unit,
  packCount: pack,
  offers: offers,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('one observed Danube offer never creates competitors or fees', () {
    final hit = {
      'objectID': 'sku-1',
      'full_name_ar': 'نوتيلا 500 جرام',
      'price': '18.75',
      'image': 'https://example.org/p.jpg',
      'url_ar': '//evil.example/path',
    };
    final items = LiveDanubeClient.parseHits([
      hit,
      {...hit, 'price': 0},
    ], DateTime.now().toUtc());
    expect(items, hasLength(1));
    expect(items.single.offers, hasLength(1));
    final o = items.single.offers.single;
    expect(o.priceHalalas, 1875);
    expect(o.storeCode, 'danube');
    expect(o.priceVerified, isTrue);
    expect(o.stockKnown, isFalse);
    expect(o.originalPriceSar, isNull);
    expect(o.totalLandedSar, isNull);
    expect(o.productUrl, 'https://danube.sa');
    expect(items.single.gtinBarcode, isNull);
    expect(
      LiveDanubeClient.parseHits([hit], DateTime.now()).single.id,
      items.single.id,
    );
  });
  test('catalog is metadata only and separates exact from alternate sizes', () {
    final result = OfflineCatalog.search(query: 'نوتيلا 500 جرام');
    for (final p in [...result.matchedProducts, ...result.alternativeSizes]) {
      expect(p.offers, isEmpty);
      expect(p.lowestOffer, isNull);
      expect(p.id, lessThan(0));
    }
    expect(
      result.matchedProducts.every((p) => p.normalizedSizeAmount == 500),
      isTrue,
    );
    expect(
      result.alternativeSizes.every(
        (p) => p.normalizedSizeAmount != 500 || p.packCount != 1,
      ),
      isTrue,
    );
  });
  test('Arabic measurements, units and multipacks are exact', () {
    expect(ProductMatching.exactSize('نوتيلا ٥٠٠ جرام', product()), isTrue);
    expect(ProductMatching.exactSize('نوتيلا 0.5kg', product()), isTrue);
    expect(
      ProductMatching.exactSize('نوتيلا 500 جرام', product(amount: 450)),
      isFalse,
    );
    expect(
      ProductMatching.exactSize('نوتيلا 500 جرام', product(unit: 'ml')),
      isFalse,
    );
    expect(
      ProductMatching.exactSize('نوتيلا 500 جرام', product(pack: 6)),
      isFalse,
    );
    expect(ProductMatching.exactSize('6x500g', product(pack: 6)), isTrue);
    expect(ProductMatching.exactSize('500g × 6', product(pack: 6)), isTrue);
    expect(
      ProductMatching.exactSize('نوتيلا 500 جرام 6 عبوات', product(pack: 6)),
      isTrue,
    );
  });
  test('legacy and stale prices cannot rank and UTC survives persistence', () {
    expect(
      product(
        offers: [offer(100, verified: false), offer(200, age: 48), offer(1800)],
      ).lowestOffer!.priceHalalas,
      1800,
    );
    final restored = StoreOffer.fromJson({
      ...offer(1800).toJson(),
      'last_verified_at': '2026-01-01T12:00:00',
    });
    expect(restored.lastVerifiedAt!.isUtc, isTrue);
    expect(
      ProductItem.fromJson(
        jsonDecode(jsonEncode(product(offers: [offer(1800)]).toJson())),
      ).lowestOffer!.priceHalalas,
      1800,
    );
  });
  test('basket uses integers and never merges branch coverage', () {
    final basket = [
      BasketItem(
        product: product(offers: [offer(1875, branch: 'A')]),
        quantity: 3,
      ),
      BasketItem(
        product: product(id: 2, offers: [offer(500, branch: 'B')]),
      ),
    ];
    final quotes = compareKnownBasket(basket);
    expect(quotes, hasLength(2));
    expect(quotes.every((q) => !q.complete), isTrue);
    expect(quotes.firstWhere((q) => q.scope == 'A').subtotalHalalas, 5625);
  });
  test(
    'local voice keeps state, negation, quantity, undo and real variants',
    () {
      final add = LocalVoiceBasket.execute('حليب السعودية');
      expect(add.currentBasket, hasLength(1));
      final original = add.currentBasket.single;
      expect(
        LocalVoiceBasket.execute('لا تضيف عصير').currentBasket,
        hasLength(1),
      );
      expect(
        LocalVoiceBasket.execute('زيد واحدة').currentBasket.single.quantity,
        2,
      );
      expect(
        LocalVoiceBasket.execute('خله اثنين').currentBasket.single.quantity,
        2,
      );
      expect(
        LocalVoiceBasket.execute('زيد واحدة').currentBasket.single.quantity,
        3,
      );
      expect(
        LocalVoiceBasket.execute('تراجع').currentBasket.single.quantity,
        2,
      );
      expect(
        LocalVoiceBasket.execute('').currentBasket.single.productId,
        original.productId,
      );
      expect(
        LocalVoiceBasket.execute('منتج غير موجود نهائيًا').currentBasket,
        hasLength(1),
      );
    },
  );
  for (final width in [320.0, 390.0, 1100.0]) {
    testWidgets('product and basket fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = product(offers: [offer(1875)]);
      final key = GlobalKey();
      final fonts = FontLoader('Tajawal')
        ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
      await fonts.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox(
                width: 440,
                child: RepaintBoundary(
                  key: key,
                  child: Scaffold(
                    body: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [VerifiedProductCard(product: p, onAdd: () {})],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (width == 390 && Platform.environment['MAGADI_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/magadi-product-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox(
                width: 440,
                child: BasketScreen(
                  basketItems: [BasketItem(product: p)],
                  onClearBasket: () {},
                  onRemoveItem: (_) {},
                  onUpdateQuantity: (_, __) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
