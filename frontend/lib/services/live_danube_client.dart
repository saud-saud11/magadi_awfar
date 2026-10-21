import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'product_matching.dart';

class LiveDanubeClient {
  static const String appId = '1D2IEWLQAD';
  static const String apiKey = '87ca3b6b2ce56f0bb76fc194a8d170e2';
  static const String endpoint =
      'https://1d2iewlqad-dsn.algolia.net/1/indexes/spree_products/query';

  static Future<List<ProductItem>> search(String query) async {
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'X-Algolia-Application-Id': appId,
            'X-Algolia-API-Key': apiKey,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'query': query,
            'hitsPerPage': 30,
            'filters': 'tenant_id = 1',
          }),
        )
        .timeout(const Duration(seconds: 7));
    if (response.statusCode != 200) {
      throw StateError('تعذر الاتصال بمصدر الأسعار');
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return parseHits(
      data['hits'] as List<dynamic>? ?? [],
      DateTime.now().toUtc(),
    );
  }

  static List<ProductItem> parseHits(List<dynamic> hits, DateTime fetchedAt) {
    final products = <ProductItem>[];
    for (final dynamic raw in hits) {
      if (raw is! Map) continue;
      final hit = Map<String, dynamic>.from(raw);
      final price = num.tryParse('${hit['price']}')?.toDouble();
      if (price == null || !price.isFinite || price <= 0) continue;
      final title =
          (hit['full_name_ar'] ?? hit['name_ar'] ?? hit['name_en'] ?? '')
              .toString()
              .trim();
      if (title.isEmpty) continue;
      final brand = hit['brand_ar']?.toString();
      final name = brand != null && brand.isNotEmpty && !title.contains(brand)
          ? '$brand $title'
          : title;
      final size = ProductMatching.measurement(name);
      final pack =
          (hit['pack_count'] is num
              ? (hit['pack_count'] as num).toInt()
              : size.pack) ??
          1;
      final sourceId =
          hit['objectID']?.toString() ?? hit['master_id']?.toString() ?? name;
      final id = ProductMatching.localId('danube:$sourceId');
      final image = hit['image']?.toString();
      final barcodeCandidate =
          hit['barcode']?.toString() ??
          hit['ean']?.toString() ??
          RegExp(r'/(\d{8,14})[-.]').firstMatch(image ?? '')?.group(1);
      final barcode =
          barcodeCandidate != null &&
              ProductMatching.validBarcode(barcodeCandidate)
          ? barcodeCandidate
          : null;
      final slug = (hit['url_ar'] ?? hit['url_en'] ?? '').toString();
      final parsedUrl = Uri.tryParse('https://danube.sa')!.resolve(slug);
      final url = parsedUrl.scheme == 'https' && parsedUrl.host == 'danube.sa'
          ? parsedUrl.toString()
          : 'https://danube.sa';
      final original = num.tryParse('${hit['original_price']}')?.toDouble();
      final onSale = original != null && original.isFinite && original > price;
      final stockKnown = hit['in_stock'] is bool;
      final stock = hit['in_stock'] == true;
      final halalas = (price * 100).round();
      products.add(
        ProductItem(
          id: id,
          gtinBarcode: barcode,
          nameAr: name,
          nameEn: hit['name_en']?.toString(),
          brandAr: brand,
          normalizedSizeAmount: size.amount,
          normalizedSizeUnit: size.unit,
          packCount: pack,
          packType: pack > 1 ? 'bundle' : 'single',
          imageUrl: image,
          offers: [
            StoreOffer(
              id: id,
              storeCode: 'danube',
              storeNameAr: 'الدانوب',
              branchNameAr:
                  'كتالوج المتجر الإلكتروني؛ تغطية الحي تُؤكّد لدى المتجر',
              priceHalalas: halalas,
              priceSar: halalas / 100,
              originalPriceSar: onSale ? original : null,
              isOnSale: onSale,
              isInStock: stock,
              stockKnown: stockKnown,
              productUrl: url,
              sourceUrl: url,
              lastVerifiedAt: fetchedAt,
              priceVerified: true,
              totalStatus: 'REQUIRES_STORE_CONFIRMATION',
              totalStatusText: 'رسوم التوصيل والخدمة تُؤكّد لدى المتجر',
              isCheapestProduct: true,
              isCheapestTotal: false,
              unitPricePer100gSar:
                  size.amount != null && size.amount! > 0 && pack == 1
                  ? price * 100 / size.amount!
                  : null,
            ),
          ],
        ),
      );
    }
    return products;
  }
}
