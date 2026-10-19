import 'dart:convert';
import 'dart:js_interop';

@JS('magadiIsPushSupported')
external bool _jsIsPushSupported();

@JS('magadiIsIos')
external bool _jsIsIos();

@JS('magadiIsStandalone')
external bool _jsIsStandalone();

@JS('magadiGetPermissionState')
external JSString _jsGetPermissionState();

@JS('magadiRegisterAndSubscribe')
external JSPromise<JSString> _jsRegisterAndSubscribe(JSString vapidPublicKey);

class PushNotificationService {
  static bool get isSupported {
    try {
      return _jsIsPushSupported();
    } catch (_) {
      return false;
    }
  }

  static bool get isIos {
    try {
      return _jsIsIos();
    } catch (_) {
      return false;
    }
  }

  static bool get isStandalone {
    try {
      return _jsIsStandalone();
    } catch (_) {
      return false;
    }
  }

  static String getPermissionState() {
    try {
      return _jsGetPermissionState().toDart;
    } catch (_) {
      return 'unsupported';
    }
  }

  static Future<Map<String, dynamic>> registerAndSubscribe(String vapidPublicKey) async {
    try {
      final promise = _jsRegisterAndSubscribe(vapidPublicKey.toJS);
      final jsResult = await promise.toDart;
      final jsonStr = jsResult.toDart;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
