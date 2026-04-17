import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'push_notification_service.dart';

/// Listens to Firestore notifications and triggers browser push notifications
/// so they appear in the phone's notification bar like any other app.
class NotificationListener {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static final Set<String> _seenNotificationIds = {};
  static bool _initialized = false;

  /// Start listening for new notifications for the current user.
  static Future<void> startListening() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Request browser notification permission
    PushNotificationService.requestPermission();

    // Cancel any existing listener
    await _subscription?.cancel();

    _initialized = false;

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('user_id', isEqualTo: user.uid)
        .where('is_read', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (!_initialized) {
        // On the first snapshot, just record existing notification IDs
        // so we don't fire notifications for old ones
        for (final doc in snapshot.docs) {
          _seenNotificationIds.add(doc.id);
        }
        _initialized = true;
        debugPrint('NotificationListener: Loaded ${snapshot.docs.length} existing notifications');
        return;
      }

      // For subsequent snapshots, only fire for truly NEW notifications
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          if (_seenNotificationIds.contains(doc.id)) continue;
          _seenNotificationIds.add(doc.id);

          final data = doc.data();
          if (data == null) continue;

          final title = data['title'] as String? ?? 'Intellix';
          final body = data['description'] as String? ?? '';
          final type = data['type'] as String? ?? '';

          debugPrint('NotificationListener: New notification — $title');

          // Fire system push notification
          PushNotificationService.showNotification(
            title: title,
            body: body,
            tag: 'intellix-$type-${doc.id}',
          );
        }
      }
    }, onError: (e) {
      debugPrint('NotificationListener error: $e');
    });
  }

  /// Stop listening.
  static Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _seenNotificationIds.clear();
    _initialized = false;
  }
}
