import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class PantryService {
  static final PantryService _instance = PantryService._internal();
  factory PantryService() => _instance;
  PantryService._internal();

  static const String _prefKeyDeviceUuid = 'magadi_device_uuid';
  static const String _prefKeyCachedPantry = 'magadi_cached_pantry_items';
  static const String _prefKeyCachedNotifications = 'magadi_cached_notifications';

  String? _cachedDeviceUuid;
  final ValueNotifier<List<PantryItemModel>> trackedItemsNotifier = ValueNotifier<List<PantryItemModel>>([]);
  final ValueNotifier<int> unreadNotificationsCountNotifier = ValueNotifier<int>(0);

  /// Returns device/guest persistent UUID
  Future<String> getDeviceUuid() async {
    if (_cachedDeviceUuid != null && _cachedDeviceUuid!.isNotEmpty) {
      return _cachedDeviceUuid!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_prefKeyDeviceUuid);
    if (stored == null || stored.isEmpty) {
      stored = 'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await prefs.setString(_prefKeyDeviceUuid, stored);
    }
    _cachedDeviceUuid = stored;
    return stored;
  }

  /// Initial load from local cache then sync from backend
  Future<void> initialize() async {
    await _loadFromLocalCache();
    await fetchPantrySummary();
    await fetchNotificationHistory();
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyCachedPantry);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        trackedItemsNotifier.value = list.map((i) => PantryItemModel.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading pantry local cache: $e');
    }
  }

  Future<void> _saveToLocalCache(List<PantryItemModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((i) => i.toJson()).toList();
      await prefs.setString(_prefKeyCachedPantry, jsonEncode(list));
      trackedItemsNotifier.value = items;
    } catch (e) {
      debugPrint('Error saving pantry local cache: $e');
    }
  }

  /// Check if a product ID is currently tracked in watchlist
  bool isProductTracked(int productId) {
    return trackedItemsNotifier.value.any((it) => it.productId == productId);
  }

  PantryItemModel? getTrackedItemByProductId(int productId) {
    try {
      return trackedItemsNotifier.value.firstWhere((it) => it.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// Fetch full summary from backend
  Future<PantrySummaryModel?> fetchPantrySummary() async {
    final uuid = await getDeviceUuid();
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/pantry').replace(queryParameters: {'device_uuid': uuid});
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        final summary = PantrySummaryModel.fromJson(data);
        await _saveToLocalCache(summary.items);
        return summary;
      }
    } catch (e) {
      debugPrint('Error fetching pantry summary: $e');
    }

    // Offline fallback from notifier
    return PantrySummaryModel(
      totalItems: trackedItemsNotifier.value.length,
      activeAlertsCount: trackedItemsNotifier.value.where((it) => it.isAlertEnabled).length,
      itemsWithDropsCount: trackedItemsNotifier.value.where((it) => it.hasPriceDrop).length,
      totalPotentialSavingsSar: trackedItemsNotifier.value.fold(0.0, (acc, it) => acc + (it.priceDropSar * it.usualQuantity)),
      items: trackedItemsNotifier.value,
    );
  }

  /// Add product to pantry watchlist
  Future<bool> addToPantry(ProductItem product, {int usualQuantity = 1, double? targetPriceSar}) async {
    final uuid = await getDeviceUuid();
    final baseUrl = ApiService.baseUrl;

    // Find lowest confirmed offer
    StoreOffer? lowestOffer;
    for (var off in product.offers) {
      if (off.priceSar > 0 && off.isInStock) {
        if (lowestOffer == null || off.priceSar < lowestOffer.priceSar) {
          lowestOffer = off;
        }
      }
    }

    final int baselineHalalas = lowestOffer != null ? (lowestOffer.priceSar * 100).round() : 0;
    final String baselineStore = lowestOffer?.storeCode ?? 'othaim';

    try {
      final uri = Uri.parse('$baseUrl/pantry');
      final body = {
        'device_uuid': uuid,
        'product_id': product.id,
        'usual_quantity': usualQuantity,
        'baseline_price_halalas': baselineHalalas > 0 ? baselineHalalas : null,
        'baseline_store_code': baselineStore,
        'target_price_halalas': targetPriceSar != null ? (targetPriceSar * 100).round() : null,
        'is_alert_enabled': true,
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        await fetchPantrySummary();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding to pantry: $e');
    }

    // Local optimistic update if offline
    final currentList = List<PantryItemModel>.from(trackedItemsNotifier.value);
    if (!currentList.any((it) => it.productId == product.id)) {
      final newItem = PantryItemModel(
        id: DateTime.now().millisecondsSinceEpoch,
        deviceUuid: uuid,
        productId: product.id,
        productNameAr: product.nameAr,
        productNameEn: product.nameEn,
        brandAr: product.brandAr,
        packLabelAr: product.packLabelAr,
        packCount: product.packCount,
        imageUrl: product.imageUrl,
        usualQuantity: usualQuantity,
        baselinePriceSar: lowestOffer?.priceSar ?? 0.0,
        baselineStoreCode: baselineStore,
        baselineStoreName: lowestOffer?.storeNameAr ?? 'المتجر',
        lastLowestPriceSar: lowestOffer?.priceSar ?? 0.0,
        lastLowestStoreCode: baselineStore,
        lastLowestStoreName: lowestOffer?.storeNameAr ?? 'المتجر',
        targetPriceSar: targetPriceSar,
        isAlertEnabled: true,
        lastCheckedAt: DateTime.now(),
        createdAt: DateTime.now(),
        priceDropSar: 0.0,
        priceDropPercentage: 0.0,
        hasPriceDrop: false,
        isTargetMet: false,
      );
      currentList.add(newItem);
      await _saveToLocalCache(currentList);
      return true;
    }
    return false;
  }

  /// Update tracked item quantity, target price, or stores
  Future<bool> updateItem(
    int itemId, {
    int? usualQuantity,
    double? targetPriceSar,
    double? dropPercentageThreshold,
    List<String>? storeCodes,
    bool? isAlertEnabled,
  }) async {
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/pantry/$itemId');
      final body = <String, dynamic>{};
      if (usualQuantity != null) body['usual_quantity'] = usualQuantity;
      if (targetPriceSar != null) body['target_price_halalas'] = (targetPriceSar * 100).round();
      if (dropPercentageThreshold != null) body['drop_percentage_threshold'] = dropPercentageThreshold;
      if (storeCodes != null) body['store_codes'] = storeCodes;
      if (isAlertEnabled != null) body['is_alert_enabled'] = isAlertEnabled;

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        await fetchPantrySummary();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating pantry item: $e');
    }

    // Local update fallback
    final currentList = List<PantryItemModel>.from(trackedItemsNotifier.value);
    final idx = currentList.indexWhere((it) => it.id == itemId);
    if (idx >= 0) {
      final existing = currentList[idx];
      currentList[idx] = PantryItemModel(
        id: existing.id,
        deviceUuid: existing.deviceUuid,
        productId: existing.productId,
        productNameAr: existing.productNameAr,
        productNameEn: existing.productNameEn,
        brandAr: existing.brandAr,
        packLabelAr: existing.packLabelAr,
        packCount: existing.packCount,
        imageUrl: existing.imageUrl,
        usualQuantity: usualQuantity ?? existing.usualQuantity,
        baselinePriceSar: existing.baselinePriceSar,
        baselineStoreCode: existing.baselineStoreCode,
        baselineStoreName: existing.baselineStoreName,
        lastLowestPriceSar: existing.lastLowestPriceSar,
        lastLowestStoreCode: existing.lastLowestStoreCode,
        lastLowestStoreName: existing.lastLowestStoreName,
        targetPriceSar: targetPriceSar ?? existing.targetPriceSar,
        dropPercentageThreshold: dropPercentageThreshold ?? existing.dropPercentageThreshold,
        storeCodes: storeCodes ?? existing.storeCodes,
        isAlertEnabled: isAlertEnabled ?? existing.isAlertEnabled,
        lastCheckedAt: existing.lastCheckedAt,
        createdAt: existing.createdAt,
        priceDropSar: existing.priceDropSar,
        priceDropPercentage: existing.priceDropPercentage,
        hasPriceDrop: existing.hasPriceDrop,
        isTargetMet: existing.isTargetMet,
      );
      await _saveToLocalCache(currentList);
      return true;
    }
    return false;
  }

  /// Remove item from watchlist
  Future<bool> removeItem(int itemId) async {
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/pantry/$itemId');
      final res = await http.delete(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        await fetchPantrySummary();
        return true;
      }
    } catch (e) {
      debugPrint('Error removing pantry item: $e');
    }

    // Local fallback
    final currentList = List<PantryItemModel>.from(trackedItemsNotifier.value);
    currentList.removeWhere((it) => it.id == itemId);
    await _saveToLocalCache(currentList);
    return true;
  }

  /// Toggle single alert
  Future<bool> toggleAlert(int itemId) async {
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/pantry/$itemId/toggle-alert');
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        await fetchPantrySummary();
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling alert: $e');
    }

    // Local fallback
    final currentList = List<PantryItemModel>.from(trackedItemsNotifier.value);
    final idx = currentList.indexWhere((it) => it.id == itemId);
    if (idx >= 0) {
      final it = currentList[idx];
      return updateItem(itemId, isAlertEnabled: !it.isAlertEnabled);
    }
    return false;
  }

  /// Toggle all alerts
  Future<bool> toggleAllAlerts(bool enable) async {
    final uuid = await getDeviceUuid();
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/pantry/toggle-all').replace(
        queryParameters: {
          'device_uuid': uuid,
          'enable': enable.toString(),
        },
      );
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        await fetchPantrySummary();
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling all alerts: $e');
    }

    final currentList = List<PantryItemModel>.from(trackedItemsNotifier.value);
    for (int i = 0; i < currentList.length; i++) {
      final ex = currentList[i];
      currentList[i] = PantryItemModel(
        id: ex.id,
        deviceUuid: ex.deviceUuid,
        productId: ex.productId,
        productNameAr: ex.productNameAr,
        productNameEn: ex.productNameEn,
        brandAr: ex.brandAr,
        packLabelAr: ex.packLabelAr,
        packCount: ex.packCount,
        imageUrl: ex.imageUrl,
        usualQuantity: ex.usualQuantity,
        baselinePriceSar: ex.baselinePriceSar,
        baselineStoreCode: ex.baselineStoreCode,
        baselineStoreName: ex.baselineStoreName,
        lastLowestPriceSar: ex.lastLowestPriceSar,
        lastLowestStoreCode: ex.lastLowestStoreCode,
        lastLowestStoreName: ex.lastLowestStoreName,
        targetPriceSar: ex.targetPriceSar,
        dropPercentageThreshold: ex.dropPercentageThreshold,
        storeCodes: ex.storeCodes,
        isAlertEnabled: enable,
        lastCheckedAt: ex.lastCheckedAt,
        createdAt: ex.createdAt,
        priceDropSar: ex.priceDropSar,
        priceDropPercentage: ex.priceDropPercentage,
        hasPriceDrop: ex.hasPriceDrop,
        isTargetMet: ex.isTargetMet,
      );
    }
    await _saveToLocalCache(currentList);
    return true;
  }

  /// Trigger manual price re-check immediately
  Future<int> triggerManualCheck() async {
    final uuid = await getDeviceUuid();
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/pantry/trigger-check').replace(queryParameters: {'device_uuid': uuid});
      final res = await http.post(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        await fetchPantrySummary();
        await fetchNotificationHistory();
        return (data['alerts_sent'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('Error triggering manual check: $e');
    }
    return 0;
  }

  /// Notification History Log
  Future<List<NotificationLogItem>> fetchNotificationHistory() async {
    final uuid = await getDeviceUuid();
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/push/history').replace(queryParameters: {'device_uuid': uuid});
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        final items = data.map((d) => NotificationLogItem.fromJson(d as Map<String, dynamic>)).toList();
        unreadNotificationsCountNotifier.value = items.where((n) => !n.isRead).length;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyCachedNotifications, jsonEncode(data));
        return items;
      }
    } catch (e) {
      debugPrint('Error fetching notification history: $e');
    }

    // Offline cached fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyCachedNotifications);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> data = jsonDecode(raw);
        final items = data.map((d) => NotificationLogItem.fromJson(d as Map<String, dynamic>)).toList();
        unreadNotificationsCountNotifier.value = items.where((n) => !n.isRead).length;
        return items;
      }
    } catch (_) {}

    return [];
  }

  Future<void> markNotificationRead(int notificationId) async {
    final baseUrl = ApiService.baseUrl;
    try {
      final uri = Uri.parse('$baseUrl/push/history/$notificationId/read');
      await http.post(uri).timeout(const Duration(seconds: 4));
      await fetchNotificationHistory();
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }
}
