import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'offline_catalog.dart';
import 'live_danube_client.dart';
import 'product_matching.dart';
import 'device_identity.dart';
import 'local_voice_basket.dart';

class ApiService {
  // Public live HTTPS cloud backend URL
  static const String liveCloudUrl = String.fromEnvironment('API_BASE_URL');

  // Optional custom backend URL
  static String? customBaseUrl;
  static String selectedDistrict = 'سلطانة';

  // Dynamically uses host/port, or live cloud backend on GitHub Pages and mobile
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (liveCloudUrl.isNotEmpty) return liveCloudUrl;
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.contains('github.io')) {
        // Connected to public live HTTPS real-time backend
        return liveCloudUrl;
      }
      final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443)
          ? ':${uri.port}'
          : '';
      return '${uri.scheme}://${uri.host}$portPart/api/v1';
    }
    return liveCloudUrl;
  }

  static Future<List<District>> getDistricts() async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse('$baseUrl/districts'))
            .timeout(const Duration(seconds: 4));
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
    List<ProductItem> live = [];
    List<dynamic> sources = [];
    SearchResult? serverResult;
    if (baseUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/search').replace(
          queryParameters: {
            'q': query,
            'district': district,
            'sort_by': sortBy,
          },
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 16));
        if (res.statusCode == 200) {
          final result = SearchResult.fromJson(
            jsonDecode(utf8.decode(res.bodyBytes)),
          );
          serverResult = result;
          sources = result.sourcesSummary;
          live = [
            ...result.matchedProducts,
            ...result.alternativeSizes,
          ].where((p) => p.offers.any((o) => o.priceVerified)).toList();
        }
      } catch (_) {
        /* Try the retailer's public search source below. */
      }
    }
    if (live.isEmpty && serverResult == null) {
      try {
        live = await LiveDanubeClient.search(query);
        sources = [
          {
            'code': 'danube',
            'name_ar': 'الدانوب',
            'status': live.isEmpty ? 'temporarily_unavailable' : 'connected',
            'status_text':
                'تعذر الاتصال بخادم المقارنة؛ هذه نتائج المصدر الاحتياطي فقط',
            'is_enabled': true,
            'products_count': live.length,
          },
        ];
      } catch (_) {}
    }
    if (live.isEmpty) {
      if (serverResult != null) return serverResult;
      return OfflineCatalog.search(
        query: query,
        district: district,
        sortBy: sortBy,
      );
    }
    // Unverified legacy server offers never enter rankings, baskets or alerts.
    live = live
        .map(
          (p) => ProductItem.fromJson({
            ...p.toJson(),
            'offers': p.offers
                .where((o) => o.isFresh)
                .map((o) => o.toJson())
                .toList(),
          }),
        )
        .toList();
    final matched = live
        .where((p) => ProductMatching.exactSize(query, p))
        .toList();
    final alternatives = live
        .where((p) => !ProductMatching.exactSize(query, p))
        .toList();
    return SearchResult(
      query: query,
      districtName: district,
      exactSizeMatched: matched.isNotEmpty,
      statusMessage: matched.isEmpty
          ? 'لم نجد الحجم المطلوب؛ هذه أحجام بديلة'
          : 'الأسعار المتاحة من المصادر التي استجابت',
      disclaimer:
          'الأسعار للمنتجات قبل الرسوم. التوفر والتوصيل إلى $district يُؤكّدان لدى المتجر.',
      matchedProducts: matched,
      alternativeSizes: alternatives,
      subCategories: [
        'الكل',
        ...live.map((p) => p.subCategory).whereType<String>().toSet(),
      ],
      sourcesSummary: sources,
    );
  }

  static Future<List<SourceInfo>> getSources() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/sources'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(res.bodyBytes),
        );
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
      final res = await http.post(
        Uri.parse('$baseUrl/admin/sources/$code/toggle'),
      );
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
    String? sessionId,
    String? requestId,
    Map<String, dynamic>? userPreferences,
  }) async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse('$baseUrl/voice/parse'),
              headers: await DeviceIdentity.headers,
              body: jsonEncode({
                'query': query,
                'session_id': await DeviceIdentity.id,
                'request_id': requestId,
                'user_preferences': userPreferences,
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(
            utf8.decode(res.bodyBytes),
          );
          return VoiceBasketResult.fromJson(data);
        }
      } catch (e) {
        print('ApiService.parseVoiceCommand error: $e');
      }
    }
    return LocalVoiceBasket.execute(query);
  }

  static Future<VoiceBasketResult?> undoVoiceCommand({
    String? sessionId,
  }) async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse('$baseUrl/voice/undo').replace(
                queryParameters: {'session_id': await DeviceIdentity.id},
              ),
              headers: await DeviceIdentity.headers,
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(
            utf8.decode(res.bodyBytes),
          );
          return VoiceBasketResult.fromJson(data);
        }
      } catch (e) {
        print('ApiService.undoVoiceCommand error: $e');
      }
    }
    return LocalVoiceBasket.execute('تراجع');
  }

  static Future<Map<String, dynamic>?> compareBasket({
    required List<Map<String, dynamic>> items,
    String district = 'سلطانة',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/basket/compare'),
            headers: await DeviceIdentity.headers,
            body: jsonEncode({'district_name': district, 'items': items}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      print('ApiService.compareBasket error: $e');
    }
    return null;
  }
}
