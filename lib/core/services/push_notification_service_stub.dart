/// Stub for non-web platforms.
class PushNotificationService {
  static Future<void> initialize() async {}
  static void requestPermission() {}
  static void showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
  }) {}
  static bool get isSupported => false;
}
