import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class LiveDanubeClient {
  static const String appId = '1D2IEWLQAD';
  static const String apiKey = '87ca3b6b2ce56f0bb76fc194a8d170e2';
  static const String endpoint = 'https://1d2iewlqad-dsn.algolia.net/1/indexes/spree_products/query';

  static Map<String, dynamic> _parseSizeAndUnit(String text) {
    // Check for kg / كغم / كجم
    final kgRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:كغم|كجم|كيلو|ك|kg)', caseSensitive: false);
    final kgMatch = kgRegex.firstMatch(text);
    if (kgMatch != null) {
      final val = double.tryParse(kgMatch.group(1)!);
      if (val != null) {
        return {'amount': val * 1000.0, 'unit': 'g'};
      }
    }

    // Check for grams / غرام / جم
    final gRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:جرام|غرام|جم|غ|g)', caseSensitive: false);
    final gMatch = gRegex.firstMatch(text);
    if (gMatch != null) {
      final val = double.tryParse(gMatch.group(1)!);
      if (val != null) {
        return {'amount': val, 'unit': 'g'};
      }
    }

    // Check for liters / لتر
    final lRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:لتر|L|l)', caseSensitive: false);
    final lMatch = lRegex.firstMatch(text);
    if (lMatch != null) {
      final val = double.tryParse(lMatch.group(1)!);
      if (val != null) {
        return {'amount': val * 1000.0, 'unit': 'ml'};
      }
    }

    // Check for ml / مل
    final mlRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:مل|ml)', caseSensitive: false);
    final mlMatch = mlRegex.firstMatch(text);
    if (mlMatch != null) {
      final val = double.tryParse(mlMatch.group(1)!);
      if (val != null) {
        return {'amount': val, 'unit': 'ml'};
      }
    }

    return {'amount': null, 'unit': null};
  }

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
          'query': query,
          'hitsPerPage': 30,
          'filters': 'tenant_id = 1',
        }),
      ).timeout(const Duration(seconds: 7));

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

          final String rawNameAr = (hit['full_name_ar'] as String?)?.isNotEmpty == true
              ? hit['full_name_ar']
              : (hit['name_ar'] as String? ?? hit['name_en'] as String? ?? query);
          final String? nameEn = hit['full_name_en'] as String? ?? hit['name_en'] as String?;
          final String? brandAr = hit['brand_ar'] as String?;
          final String? image = hit['image'] as String?;
          final String slug = hit['url_ar'] as String? ?? hit['url_en'] as String? ?? '';
          final String prodUrl = slug.isNotEmpty ? 'https://danube.sa$slug' : 'https://danube.sa';

          // Combine brand with name if brand is missing from title
          String displayNameAr = rawNameAr;
          if (brandAr != null && brandAr.trim().isNotEmpty && !displayNameAr.contains(brandAr.trim())) {
            displayNameAr = '${brandAr.trim()} $displayNameAr';
          }

          final sizeInfo = _parseSizeAndUnit(displayNameAr);
          final double? sizeAmount = sizeInfo['amount'] as double?;
          final String? sizeUnit = sizeInfo['unit'] as String?;

          double? unitPrice;
          if (sizeAmount != null && sizeAmount > 0) {
            unitPrice = (priceSar / sizeAmount) * 100.0;
          }

          int packCount = 1;
          String packType = 'single';
          String packLabel = 'بالحبّة (مفرد)';
          
          if (displayNameAr.contains('٢٤*') || displayNameAr.contains('24*') || displayNameAr.contains('24x') || displayNameAr.contains('24×') || displayNameAr.contains('كرتون')) {
            packCount = 24;
            packType = 'bundle';
            packLabel = 'كرتون (24 علبة)';
          } else if (displayNameAr.contains('٦*') || displayNameAr.contains('6*') || displayNameAr.contains('6x') || displayNameAr.contains('6×') || displayNameAr.contains('شدة') || displayNameAr.contains('شدّة') || displayNameAr.contains('حزمة')) {
            packCount = 6;
            packType = 'bundle';
            packLabel = 'حزمة (6 علب)';
          } else if (displayNameAr.contains('١٢*') || displayNameAr.contains('12*') || displayNameAr.contains('12x') || displayNameAr.contains('12×') || displayNameAr.contains('درزن')) {
            packCount = 12;
            packType = 'bundle';
            packLabel = 'شدّة (12 علبة)';
          } else if (displayNameAr.contains('٣٠*') || displayNameAr.contains('30*') || displayNameAr.contains('30x') || displayNameAr.contains('30×')) {
            packCount = 30;
            packType = 'bundle';
            packLabel = 'كرتون (30 علبة)';
          }

          items.add(ProductItem(
            id: ++idCounter,
            gtinBarcode: hit['objectID']?.toString(),
            nameAr: displayNameAr,
            nameEn: nameEn,
            brandAr: brandAr,
            subCategory: packType == 'bundle' ? 'حزم وكراتين (عروض شدّات)' : 'عبوات فردية (بالحبّة)',
            subCategoryRank: packType == 'bundle' ? 2 : 1,
            normalizedSizeAmount: sizeAmount,
            normalizedSizeUnit: sizeUnit,
            packCount: packCount,
            packType: packType,
            packLabelAr: packLabel,
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
                promoConditions: (origSar != null && origSar > priceSar)
                    ? 'وفر ${(origSar - priceSar).toStringAsFixed(2)} ر.س'
                    : 'سعر حي ومباشر من المتجر 🟢',
                deliveryFeeSar: 15.0,
                totalLandedSar: priceSar + 15.0,
                totalStatus: 'CONFIRMED',
                totalStatusText: 'سعر مباشر مؤكد لحظياً 🟢',
                isCheapestProduct: true,
                isCheapestTotal: true,
                unitPricePer100gSar: unitPrice,
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
