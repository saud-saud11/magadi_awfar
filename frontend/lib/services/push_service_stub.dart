class PushNotificationService {
  static bool get isSupported => false;
  static bool get isIos => false;
  static bool get isStandalone => false;
  static String getPermissionState() => "unsupported";

  static Future<Map<String, dynamic>> registerAndSubscribe(String vapidPublicKey) async {
    return {"success": false, "error": "Not supported on this platform"};
  }
}
