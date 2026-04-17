import 'dart:js_interop';

@JS('intellixRequestNotificationPermission')
external JSString _jsRequestPermission();

@JS('intellixGetNotificationPermission')
external JSString _jsGetPermission();

@JS('intellixShowNotification')
external JSBoolean _jsShowNotification(
    JSString title, JSString body, JSString icon, JSString tag);

/// Web implementation using the browser's native Notification API.
/// Shows real push notifications in the system notification bar on phones/desktops.
class PushNotificationService {
  static bool get isSupported {
    try {
      final perm = _jsGetPermission().toDart;
      return perm != 'unsupported';
    } catch (_) {
      return false;
    }
  }

  /// Initialize and request notification permission from the browser.
  static Future<void> initialize() async {
    try {
      _jsRequestPermission();
    } catch (_) {}
  }

  /// Explicitly request permission (call on a user gesture for best results).
  static void requestPermission() {
    try {
      _jsRequestPermission();
    } catch (_) {}
  }

  /// Show a system push notification.
  static void showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
  }) {
    try {
      _jsShowNotification(
        title.toJS,
        body.toJS,
        (icon ?? '/icons/Icon-192.png').toJS,
        (tag ?? 'intellix-${DateTime.now().millisecondsSinceEpoch}').toJS,
      );
    } catch (_) {}
  }
}
