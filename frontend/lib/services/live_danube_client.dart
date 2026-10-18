import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class LiveDanubeClient {
  static const String appId = '1D2IEWLQAD';
  static const String apiKey = '87ca3b6b2ce56f0bb76fc194a8d170e2';
  static const String endpoint = 'https://1d2iewlqad-dsn.algolia.net/1/indexes/spree_products/query';

  static Future<List<ProductItem>> search(String query) async {
    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'X-Algolia-Application-Id': appId,
          'X-Algolia-API-Key': apiKey,
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'params': 'query=$query&hitsPerPage=15&filters=tenant_id = 1',
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final hits = data['hits'] as List<dynamic>? ?? [];
        final List<ProductItem> items = [];

        int idCounter = 80000;
        for (final hit in hits) {
          final priceNum = hit['price'];
          if (priceNum == null) continue;
          final double priceSar = (priceNum as num).toDouble();
          final int priceHalalas = (priceSar * 100).round();
          final origNum = hit['original_price'];
          final double? origSar = origNum != null ? (origNum as num).toDouble() : null;

          final String nameAr = (hit['full_name_ar'] as String?)?.isNotEmpty == true
              ? hit['full_name_ar']
              : (hit['name_ar'] as String? ?? hit['name_en'] as String? ?? query);
          final String? nameEn = hit['full_name_en'] as String? ?? hit['name_en'] as String?;
          final String? brandAr = hit['brand_ar'] as String?;
          final String? image = hit['image'] as String?;
          final String slug = hit['url_ar'] as String? ?? hit['url_en'] as String? ?? '';
          final String prodUrl = slug.isNotEmpty ? 'https://danube.sa$slug' : 'https://danube.sa';

          items.add(ProductItem(
            id: ++idCounter,
            gtinBarcode: hit['objectID']?.toString(),
            nameAr: nameAr,
            nameEn: nameEn,
            brandAr: brandAr,
            subCategory: 'الدانوب مباشر',
            subCategoryRank: 1,
            normalizedSizeAmount: null,
            normalizedSizeUnit: null,
            packCount: 1,
            imageUrl: image,
            offers: [
              StoreOffer(
                id: 1,
                storeCode: 'danube',
                storeNameAr: 'الدانوب',
                branchNameAr: 'فرع محطة قطار الحرمين (المدينة المنورة)',
                priceHalalas: priceHalalas,
                priceSar: priceSar,
                originalPriceSar: origSar,
                isOnSale: origSar != null && origSar > priceSar,
                isInStock: hit['in_stock'] != false,
                productUrl: prodUrl,
                deepLink: 'danube://product/${hit['master_id'] ?? hit['objectID']}',
                promoConditions: (origSar != null && origSar > priceSar) ? 'خصم مباشر' : null,
                deliveryFeeSar: 15.0,
                totalLandedSar: priceSar + 15.0,
                totalStatus: 'CONFIRMED',
                totalStatusText: 'السعر مؤكد من الدانوب مباشر',
                isCheapestProduct: true,
                isCheapestTotal: true,
                unitPricePer100gSar: null,
              ),
            ],
          ));
        }
        return items;
      }
    } catch (e) {
      print('LiveDanubeClient search error: $e');
    }
    return [];
  }
}
