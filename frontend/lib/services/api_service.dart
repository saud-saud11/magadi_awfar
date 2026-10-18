import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'offline_catalog.dart';

class ApiService {
  // Optional custom backend URL
  static String? customBaseUrl;

  // Dynamically uses host/port, but immediately uses client catalog on GitHub Pages
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.contains('github.io')) {
        // GitHub Pages has no python backend, use instant catalog
        return '';
      }
      final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$portPart/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static Future<List<District>> getDistricts() async {
    if (baseUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/districts')).timeout(const Duration(seconds: 3));
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
    if (baseUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
          'q': query,
          'district': district,
          'sort_by': sortBy,
        });

        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
          return SearchResult.fromJson(data);
        }
      } catch (e) {
        print('ApiService.search error, falling back to catalog: $e');
      }
    }
    // Instant fallback to Al-Madinah staple catalog
    return OfflineCatalog.search(
      query: query,
      district: district,
      sortBy: sortBy,
    );
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

