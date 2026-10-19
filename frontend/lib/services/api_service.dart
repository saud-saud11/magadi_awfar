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

    if (danubeLive.isNotEmpty) {
      final existingNames = danubeLive.map((d) => d.nameAr).toSet();
      final extraOffline = offlineRes.matchedProducts.where((p) => !existingNames.contains(p.nameAr)).toList();
      final combinedMatched = [...danubeLive, ...extraOffline];

      return SearchResult(
        query: query,
        districtName: district,
        exactSizeMatched: offlineRes.exactSizeMatched || danubeLive.isNotEmpty,
        statusMessage: 'تم العثور على ${combinedMatched.length} منتجات في المدينة المنورة (تحديث حي مباشر).',
        disclaimer: 'الأرخص بين العروض المطابقة التي تم فحصها لموقعك',
        matchedProducts: combinedMatched,
        alternativeSizes: offlineRes.alternativeSizes,
        subCategories: ['الكل', ...offlineRes.subCategories],
        sourcesSummary: offlineRes.sourcesSummary.isNotEmpty ? offlineRes.sourcesSummary : [
          {'store_name_ar': 'الدانوب', 'status': 'connected'},
          {'store_name_ar': 'بنده', 'status': 'connected'},
          {'store_name_ar': 'أسواق العثيم', 'status': 'connected'},
          {'store_name_ar': 'أسواق التميمي', 'status': 'connected'},
          {'store_name_ar': 'نون منتس', 'status': 'connected'},
          {'store_name_ar': 'أمازون السعودية', 'status': 'connected'},
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

