import 'dart:convert';
import 'dart:js_interop';

@JS('magadiIsPushSupported')
external JSBoolean? _jsIsPushSupported();

@JS('magadiIsIos')
external JSBoolean? _jsIsIos();

@JS('magadiIsStandalone')
external JSBoolean? _jsIsStandalone();

@JS('magadiGetPermissionState')
external JSString? _jsGetPermissionState();

@JS('magadiRegisterAndSubscribe')
external JSPromise<JSString>? _jsRegisterAndSubscribe(JSString vapidPublicKey);

class PushNotificationService {
  static bool get isSupported {
    try {
      return _jsIsPushSupported()?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get isIos {
    try {
      return _jsIsIos()?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get isStandalone {
    try {
      return _jsIsStandalone()?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static String getPermissionState() {
    try {
      return _jsGetPermissionState()?.toDart ?? 'unsupported';
    } catch (_) {
      return 'unsupported';
    }
  }

  static Future<Map<String, dynamic>> registerAndSubscribe(String vapidPublicKey) async {
    try {
      final promise = _jsRegisterAndSubscribe(vapidPublicKey.toJS);
      if (promise == null) return {'success': false, 'error': 'Push not available'};
      final jsResult = await promise.toDart;
      final jsonStr = jsResult.toDart;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
