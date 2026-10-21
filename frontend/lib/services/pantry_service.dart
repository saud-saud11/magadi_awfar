import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'device_identity.dart';
import 'product_matching.dart';

class PantryService {
  static final PantryService _instance = PantryService._internal();
  factory PantryService() => _instance;
  PantryService._internal();
  final trackedItemsNotifier = ValueNotifier<List<PantryItemModel>>([]);
  final unreadNotificationsCountNotifier = ValueNotifier<int>(0);
  final statusNotifier = ValueNotifier<String>(
    'التحقق من الاتصال بخدمة المتابعة…',
  );
  List<NotificationLogItem> _notifications = [];
  List<NotificationLogItem> get cachedNotifications => _notifications;
  Map<int, int> _aliases = {};
  Set<int> _read = {};
  Future<void>? _initialization;
  Future<String> getDeviceUuid() => DeviceIdentity.id;

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw =
          jsonDecode(prefs.getString('magadi_cached_pantry_items') ?? '[]')
              as List;
      trackedItemsNotifier.value = raw
          .map((i) => PantryItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
      final aliases =
          jsonDecode(prefs.getString('magadi_product_aliases') ?? '{}') as Map;
      _aliases = aliases.map((k, v) => MapEntry(int.parse(k), v as int));
      _read = (prefs.getStringList('magadi_read_notifications') ?? [])
          .map(int.parse)
          .toSet();
    } catch (_) {}
  }

  Future<void> _save(List<PantryItemModel> items) async {
    trackedItemsNotifier.value = items;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'magadi_cached_pantry_items',
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
    await prefs.setString(
      'magadi_product_aliases',
      jsonEncode(_aliases.map((k, v) => MapEntry('$k', v))),
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    if (ApiService.baseUrl.isEmpty) {
      throw StateError(
        'خدمة المتابعة غير متصلة؛ الأصناف محفوظة على هذا الجهاز',
      );
    }
    final uri = Uri.parse(
      '${ApiService.baseUrl}$path',
    ).replace(queryParameters: query);
    final req = http.Request(method, uri)
      ..headers.addAll(await DeviceIdentity.headers);
    if (body != null) req.body = jsonEncode(body);
    final client = http.Client();
    try {
      final res = await client
          .send(req)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw StateError(
          data is Map
              ? '${data['detail'] ?? 'تعذر إتمام الطلب'}'
              : 'تعذر إتمام الطلب',
        );
      }
      return data;
    } finally {
      client.close();
    }
  }

  PantryItemModel? getTrackedItemByProductId(int productId) {
    for (final item in trackedItemsNotifier.value) {
      if (item.productId == productId || item.productId == _aliases[productId]) {
        return item;
      }
    }
    return null;
  }

  bool isProductTracked(int productId) =>
      getTrackedItemByProductId(productId) != null;
  PantrySummaryModel _summary() {
    final items = trackedItemsNotifier.value;
    return PantrySummaryModel(
      totalItems: items.length,
      activeAlertsCount: items
          .where((i) => i.serverSynced && i.isAlertEnabled)
          .length,
      itemsWithDropsCount: items
          .where((i) => i.hasVerifiedPrice && i.hasPriceDrop)
          .length,
      totalPotentialSavingsSar: items
          .where((i) => i.hasVerifiedPrice)
          .fold(0.0, (v, i) => v + i.priceDropSar * i.usualQuantity),
      items: items,
    );
  }

  Future<PantrySummaryModel?> fetchPantrySummary() async {
    try {
      final data = await _request(
        'GET',
        '/pantry',
        query: {'device_uuid': await DeviceIdentity.id},
      );
      final summary = PantrySummaryModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      final pending = trackedItemsNotifier.value.where(
        (i) =>
            !i.serverSynced &&
            !summary.items.any((s) => s.productNameAr == i.productNameAr),
      );
      await _save([...summary.items, ...pending]);
      statusNotifier.value =
          '${data['monitoring_status'] ?? 'متصل بخدمة المتابعة'} • ${pending.length} أصناف محفوظة محليًا';
    } catch (_) {
      statusNotifier.value =
          'محفوظة على هذا الجهاز • المتابعة على الخادم غير متاحة الآن';
    }
    return _summary();
  }

  Future<bool> addToPantry(
    ProductItem product, {
    int usualQuantity = 1,
    double? targetPriceSar,
  }) async {
    final current = getTrackedItemByProductId(product.id);
    if (current != null) {
      return updateItem(
        current.id,
        usualQuantity: usualQuantity,
        targetPriceSar: targetPriceSar,
      );
    }
    final best = product.lowestOffer;
    final local = PantryItemModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      deviceUuid: await DeviceIdentity.id,
      productId: product.id,
      productNameAr: product.nameAr,
      productNameEn: product.nameEn,
      brandAr: product.brandAr,
      packLabelAr: product.packLabelAr,
      packCount: product.packCount,
      imageUrl: product.imageUrl,
      normalizedSizeAmount: product.normalizedSizeAmount,
      normalizedSizeUnit: product.normalizedSizeUnit,
      usualQuantity: usualQuantity,
      baselinePriceSar: best?.priceSar ?? 0,
      baselineStoreCode: best?.storeCode,
      lastLowestPriceSar: best?.priceSar ?? 0,
      lastLowestStoreCode: best?.storeCode,
      lastLowestStoreName: best?.storeNameAr,
      targetPriceSar: targetPriceSar,
      isAlertEnabled: false,
      lastCheckedAt: best?.lastVerifiedAt,
      hasVerifiedPrice: best != null,
      createdAt: DateTime.now(),
      priceDropSar: 0,
      priceDropPercentage: 0,
      hasPriceDrop: false,
      isTargetMet: false,
    );
    await _save([...trackedItemsNotifier.value, local]);
    return syncItem(local);
  }

  Future<bool> syncItem(PantryItemModel item) async {
    try {
      var productId = item.productId;
      if (productId <= 0) {
        final data = await _request(
          'GET',
          '/search',
          query: {
            'q': item.productNameAr,
            'district': ApiService.selectedDistrict,
          },
        );
        final result = SearchResult.fromJson(Map<String, dynamic>.from(data));
        final target = item.toProductItem();
        final matches = result.matchedProducts
            .where(
              (p) =>
                  ProductMatching.sameProduct(p, target) &&
                  p.lowestOffer != null,
            )
            .toList();
        if (matches.isEmpty) {
          throw StateError('لم نحصل على سعر مطابق لتفعيل المتابعة');
        }
        productId = matches.first.id;
      }
      final data = await _request(
        'POST',
        '/pantry',
        body: {
          'device_uuid': await DeviceIdentity.id,
          'product_id': productId,
          'district_name': ApiService.selectedDistrict,
          'usual_quantity': item.usualQuantity,
          'target_price_sar': item.targetPriceSar,
          'is_alert_enabled': true,
        },
      );
      final synced = PantryItemModel.fromJson(Map<String, dynamic>.from(data));
      _aliases[item.productId] = synced.productId;
      await _save(
        trackedItemsNotifier.value
            .map((i) => i.id == item.id ? synced : i)
            .toList(),
      );
      statusNotifier.value = 'تم حفظ الصنف للمتابعة على الخادم';
      return true;
    } catch (_) {
      statusNotifier.value =
          'تم حفظ الصنف محليًا؛ تفعيل المتابعة يتطلب اتصالًا وسعرًا موثوقًا';
      return false;
    }
  }

  Future<bool> updateItem(
    int itemId, {
    int? usualQuantity,
    double? targetPriceSar,
    double? dropPercentageThreshold,
    List<String>? storeCodes,
    bool? isAlertEnabled,
  }) async {
    final found = trackedItemsNotifier.value
        .where((i) => i.id == itemId)
        .toList();
    if (found.isEmpty) return false;
    final item = found.first;
    final patch = <String, dynamic>{
      if (usualQuantity != null) 'usual_quantity': usualQuantity,
      if (targetPriceSar != null) 'target_price_sar': targetPriceSar,
      if (dropPercentageThreshold != null)
        'target_discount_percent': dropPercentageThreshold,
      if (storeCodes != null) 'specific_store_codes': storeCodes,
      if (isAlertEnabled != null) 'is_alert_enabled': isAlertEnabled,
    };
    try {
      final data = item.serverSynced
          ? await _request('PUT', '/pantry/$itemId', body: patch)
          : {...item.toJson(), ...patch};
      final updated = PantryItemModel.fromJson(Map<String, dynamic>.from(data));
      await _save(
        trackedItemsNotifier.value
            .map((i) => i.id == itemId ? updated : i)
            .toList(),
      );
      return true;
    } catch (_) {
      statusNotifier.value = 'تعذر حفظ التعديل على الخادم؛ حاول مجددًا';
      return false;
    }
  }

  Future<bool> removeItem(int itemId, {int? productId}) async {
    final items = trackedItemsNotifier.value
        .where((i) => i.id == itemId || i.productId == productId)
        .toList();
    if (items.isEmpty) return false;
    try {
      if (items.first.serverSynced) {
        await _request('DELETE', '/pantry/${items.first.id}');
      }
      await _save(
        trackedItemsNotifier.value
            .where((i) => i.id != items.first.id)
            .toList(),
      );
      return true;
    } catch (_) {
      statusNotifier.value = 'تعذر حذف الصنف من الخادم';
      return false;
    }
  }

  Future<bool> toggleAlert(int itemId, {int? productId}) async {
    final items = trackedItemsNotifier.value
        .where((i) => i.id == itemId || i.productId == productId)
        .toList();
    if (items.isEmpty) return false;
    final item = items.first;
    if (!item.serverSynced) return syncItem(item);
    return updateItem(item.id, isAlertEnabled: !item.isAlertEnabled);
  }

  Future<bool> toggleAllAlerts(bool enable) async {
    var success = true;
    for (final item in trackedItemsNotifier.value.toList()) {
      final ok = !item.serverSynced && enable
          ? await syncItem(item)
          : await updateItem(item.id, isAlertEnabled: enable);
      success = ok && success;
    }
    return success;
  }

  Future<int> triggerManualCheck() async {
    try {
      for (final item
          in trackedItemsNotifier.value
              .where((i) => !i.serverSynced)
              .take(5)
              .toList()) {
        await syncItem(item);
      }
      final data = await _request(
        'POST',
        '/pantry/trigger-check',
        query: {'device_uuid': await DeviceIdentity.id},
      );
      await fetchPantrySummary();
      await fetchNotificationHistory();
      return (data['alerts_sent'] as num?)?.toInt() ?? 0;
    } catch (_) {
      statusNotifier.value = 'تعذر فحص الأسعار الآن؛ لم يتم تأكيد تحديثها';
      return -1;
    }
  }

  Future<Map<String, dynamic>> getPushConfig() async {
    try {
      return Map<String, dynamic>.from(await _request('GET', '/push/config'));
    } catch (_) {
      return {'enabled': false};
    }
  }

  Future<bool> registerPush(Map<String, dynamic> subscription) async {
    try {
      await _request(
        'POST',
        '/push/subscribe',
        body: {
          'device_uuid': await DeviceIdentity.id,
          'platform': 'web',
          'endpoint': subscription['endpoint'],
          'p256dh_key': subscription['p256dh'],
          'auth_key': subscription['auth'],
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      await _request(
        'POST',
        '/push/test',
        query: {'device_uuid': await DeviceIdentity.id},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<NotificationLogItem>> fetchNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data =
          await _request(
                'GET',
                '/push/history',
                query: {'device_uuid': await DeviceIdentity.id},
              )
              as List;
      _notifications = data
          .map(
            (i) => NotificationLogItem.fromJson({
              ...Map<String, dynamic>.from(i),
              'is_read': _read.contains(i['id']),
            }),
          )
          .toList();
      await prefs.setString(
        'magadi_cached_notifications',
        jsonEncode(_notifications.map((i) => i.toJson()).toList()),
      );
    } catch (_) {
      final data =
          jsonDecode(prefs.getString('magadi_cached_notifications') ?? '[]')
              as List;
      _notifications = data
          .map(
            (i) => NotificationLogItem.fromJson(Map<String, dynamic>.from(i)),
          )
          .toList();
    }
    unreadNotificationsCountNotifier.value = _notifications
        .where((i) => !i.isRead)
        .length;
    return _notifications;
  }

  Future<void> markNotificationRead(int id) async {
    _read.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'magadi_read_notifications',
      _read.map((i) => '$i').toList(),
    );
    _notifications = _notifications
        .map(
          (i) => i.id == id
              ? NotificationLogItem.fromJson({...i.toJson(), 'is_read': true})
              : i,
        )
        .toList();
    await prefs.setString(
      'magadi_cached_notifications',
      jsonEncode(_notifications.map((i) => i.toJson()).toList()),
    );
    unreadNotificationsCountNotifier.value = _notifications
        .where((i) => !i.isRead)
        .length;
  }

  Future<bool> clearNotificationHistory() async {
    try {
      if (ApiService.baseUrl.isNotEmpty) {
        await _request(
          'DELETE',
          '/push/history',
          query: {'device_uuid': await DeviceIdentity.id},
        );
      }
    } catch (_) {
      statusNotifier.value = 'تعذر مسح سجل الخادم';
      return false;
    }
    _notifications = [];
    unreadNotificationsCountNotifier.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('magadi_cached_notifications');
    return true;
  }

  Future<AlertPreferencesModel> fetchAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await _request(
        'GET',
        '/push/preferences',
        query: {'device_uuid': await DeviceIdentity.id},
      );
      await prefs.setString('magadi_alert_prefs', jsonEncode(data));
      return AlertPreferencesModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return AlertPreferencesModel.fromJson(
        jsonDecode(prefs.getString('magadi_alert_prefs') ?? '{}'),
      );
    }
  }

  Future<bool> updateAlertPreferences(AlertPreferencesModel model) async {
    try {
      await _request(
        'PUT',
        '/push/preferences',
        query: {'device_uuid': await DeviceIdentity.id},
        body: model.toJson(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('magadi_alert_prefs', jsonEncode(model.toJson()));
      return true;
    } catch (_) {
      statusNotifier.value = 'تعذر حفظ تفضيلات الخادم';
      return false;
    }
  }
}
