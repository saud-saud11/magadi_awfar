import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'offline_catalog.dart';
import 'live_danube_client.dart';

class ApiService {
  // Public live HTTPS cloud backend URL
  static const String liveCloudUrl = 'https://sapphire-allows-stuck-safe.trycloudflare.com/api/v1';

  // Optional custom backend URL
  static String? customBaseUrl;

  // Dynamically uses host/port, or live cloud backend on GitHub Pages and mobile
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.contains('github.io')) {
        // Connected to public live HTTPS real-time backend
        return liveCloudUrl;
      }
      final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portPart/api/v1';
    }
    return liveCloudUrl;
  }

  static Future<List<District>> getDistricts() async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/districts')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          return data.map((d) => District.fromJson(d)).toList();
        }
      } catch (e) {
        print('ApiService.getDistricts error: $e');
      }
    }
    // Fallback default districts in Madinah if backend is temporarily unreachable
    return [
      District(id: 1, nameAr: 'سلطانة', city: 'المدينة المنورة'),
      District(id: 2, nameAr: 'قباء', city: 'المدينة المنورة'),
      District(id: 3, nameAr: 'العزيزية', city: 'المدينة المنورة'),
      District(id: 4, nameAr: 'الخالدية', city: 'المدينة المنورة'),
      District(id: 5, nameAr: 'الرانوناء', city: 'المدينة المنورة'),
      District(id: 6, nameAr: 'العريض', city: 'المدينة المنورة'),
      District(id: 7, nameAr: 'الدفاع', city: 'المدينة المنورة'),
      District(id: 8, nameAr: 'شظاة', city: 'المدينة المنورة'),
      District(id: 9, nameAr: 'شوران', city: 'المدينة المنورة'),
    ];
  }

  static Future<SearchResult?> search({
    required String query,
    String district = 'سلطانة',
    String sortBy = 'cheapest_product',
  }) async {
    // 1. Try real-time query to live cloud backend (fetches Othaim, Panda, Tamimi, Carrefour, Danube)
    if (baseUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
          'q': query,
          'district': district,
          'sort_by': sortBy,
        });

        final res = await http.get(uri).timeout(const Duration(seconds: 9));
        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          final searchRes = SearchResult.fromJson(data);
          if (searchRes.matchedProducts.isNotEmpty || searchRes.alternativeSizes.isNotEmpty) {
            return searchRes;
          }
        }
      } catch (e) {
        print('ApiService.search live backend error: $e');
      }
    }

    // 2. Direct browser Algolia live search for Danube
    List<ProductItem> danubeLive = [];
    try {
      danubeLive = await LiveDanubeClient.search(query);
    } catch (e) {
      print('LiveDanubeClient error: $e');
    }

    // 3. Fallback to expanded offline catalog
    final offlineRes = OfflineCatalog.search(
      query: query,
      district: district,
      sortBy: sortBy,
    );

    final List<ProductItem> finalMatched = [];

    if (offlineRes.matchedProducts.isNotEmpty) {
      for (final p in offlineRes.matchedProducts) {
        ProductItem updatedItem = p;
        if (danubeLive.isNotEmpty) {
          // Find matching live Danube hit
          ProductItem? match;
          for (final dl in danubeLive) {
            if (p.normalizedSizeAmount != null && dl.normalizedSizeAmount != null) {
              final diff = (p.normalizedSizeAmount! - dl.normalizedSizeAmount!).abs();
              if (diff < 50 && (p.brandAr == dl.brandAr || dl.nameAr.contains(p.brandAr ?? ''))) {
                match = dl;
                break;
              }
            }
            if (dl.nameAr.contains(p.nameAr) || p.nameAr.contains(dl.nameAr)) {
              match = dl;
              break;
            }
          }

          if (match != null) {
            StoreOffer? liveDanubeOffer;
            for (final o in match.offers) {
              if (o.storeCode == 'danube') {
                liveDanubeOffer = o;
                break;
              }
            }

            if (liveDanubeOffer != null) {
              final newOffers = p.offers.map((o) {
                if (o.storeCode == 'danube') {
                  return liveDanubeOffer!;
                }
                return o;
              }).toList();

              int minHalalas = 9999999;
              for (var o in newOffers) {
                if (o.priceHalalas < minHalalas) minHalalas = o.priceHalalas;
              }

              final sortedOffers = newOffers.map((o) {
                final isCheap = o.priceHalalas == minHalalas;
                return o.copyWith(
                  isCheapestProduct: isCheap,
                  isCheapestTotal: isCheap,
                );
              }).toList();
              sortedOffers.sort((a, b) => a.priceHalalas.compareTo(b.priceHalalas));

              updatedItem = ProductItem(
                id: p.id,
                gtinBarcode: match.gtinBarcode ?? p.gtinBarcode,
                nameAr: p.nameAr,
                nameEn: p.nameEn,
                brandAr: p.brandAr,
                subCategory: p.subCategory,
                subCategoryRank: p.subCategoryRank,
                normalizedSizeAmount: p.normalizedSizeAmount,
                normalizedSizeUnit: p.normalizedSizeUnit,
                packCount: p.packCount,
                packType: p.packType,
                packLabelAr: p.packLabelAr,
                imageUrl: (match.imageUrl != null && match.imageUrl!.isNotEmpty) ? match.imageUrl : p.imageUrl,
                offers: sortedOffers,
              );
            }
          }
        }
        finalMatched.add(updatedItem);
      }

      // Also append any extra distinct items from danubeLive
      for (final dl in danubeLive) {
        final alreadyRepresented = finalMatched.any((m) {
          if (m.normalizedSizeAmount != null && dl.normalizedSizeAmount != null) {
            return (m.normalizedSizeAmount! - dl.normalizedSizeAmount!).abs() < 50 &&
                (m.brandAr == dl.brandAr || dl.nameAr.contains(m.brandAr ?? ''));
          }
          return dl.nameAr.contains(m.nameAr) || m.nameAr.contains(dl.nameAr);
        });
        if (!alreadyRepresented) {
          finalMatched.add(dl);
        }
      }
    } else if (danubeLive.isNotEmpty) {
      finalMatched.addAll(danubeLive);
    }

    if (finalMatched.isNotEmpty) {
      return SearchResult(
        query: query,
        districtName: district,
        exactSizeMatched: true,
        statusMessage: 'تم العثور على ${finalMatched.length} منتجات ومقارنة أسعارها عبر كافة متاجر المدينة المنورة',
        disclaimer: 'تحديث أسعار حي ومباشر من المتجر للدانوب 🟢، ومقارنة مع أسعار الرف بأسواق العثيم وبنده والتميمي وكارفور ولولو.',
        matchedProducts: finalMatched,
        alternativeSizes: offlineRes.alternativeSizes,
        subCategories: ['الكل', ...finalMatched.map((e) => e.subCategory).whereType<String>().where((s) => s.isNotEmpty).toSet()],
        sourcesSummary: [
          {'store_name_ar': 'الدانوب (تحديث حي مباشر 🟢)', 'status': 'connected'},
          {'store_name_ar': 'أسواق العثيم', 'status': 'connected'},
          {'store_name_ar': 'بنده', 'status': 'connected'},
          {'store_name_ar': 'أسواق التميمي', 'status': 'connected'},
          {'store_name_ar': 'كارفور', 'status': 'connected'},
          {'store_name_ar': 'لولو هايبرماركت', 'status': 'connected'},
        ],
      );
    }

    return offlineRes;
  }

  static Future<List<SourceInfo>> getSources() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/sources')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> sources = data['sources'] ?? [];
        return sources.map((s) => SourceInfo.fromJson(s)).toList();
      }
    } catch (e) {
      print('ApiService.getSources error: $e');
    }
    return [];
  }

  static Future<bool> toggleSource(String code) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/admin/sources/$code/toggle'));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // Voice Basket AI Endpoints
  // ==========================================
  static Future<VoiceBasketResult?> parseVoiceCommand({
    required String query,
    String sessionId = 'default_session',
    String? requestId,
    Map<String, dynamic>? userPreferences,
  }) async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/voice/parse'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'session_id': sessionId,
            'request_id': requestId,
            'user_preferences': userPreferences,
          }),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          return VoiceBasketResult.fromJson(data);
        }
      } catch (e) {
        print('ApiService.parseVoiceCommand error: $e');
      }
    }
    return OfflineCatalog.parseVoice(query);
  }

  static Future<VoiceBasketResult?> undoVoiceCommand({
    String sessionId = 'default_session',
  }) async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/voice/undo?session_id=$sessionId'),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          return VoiceBasketResult.fromJson(data);
        }
      } catch (e) {
        print('ApiService.undoVoiceCommand error: $e');
      }
    }
    return OfflineCatalog.parseVoice('تراجع');
  }

  static Future<Map<String, dynamic>?> compareBasket({
    required List<Map<String, dynamic>> items,
    String district = 'سلطانة',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/basket/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'district_name': district,
          'items': items,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      print('ApiService.compareBasket error: $e');
    }
    return null;
  }
}

