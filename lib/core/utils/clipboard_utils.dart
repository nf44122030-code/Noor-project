import 'dart:async';
import 'package:flutter/services.dart';

/// Utility for safely copying sensitive text to the clipboard.
/// Automatically clears the clipboard after the specified delay (default 30s)
/// to prevent sensitive data from lingering.
class ClipboardUtils {
  static Timer? _clearTimer;

  /// Copies [text] to the clipboard and schedules a clear after [delay].
  static Future<void> copyAndScheduleClear(
    String text, {
    Duration delay = const Duration(seconds: 30),
    void Function()? onCleared,
  }) async {
    // Cancel any pending clear from a previous copy
    _clearTimer?.cancel();

    await Clipboard.setData(ClipboardData(text: text));

    _clearTimer = Timer(delay, () async {
      await Clipboard.setData(const ClipboardData(text: ''));
      onCleared?.call();
    });
  }

  /// Immediately clears the clipboard.
  static Future<void> clearNow() async {
    _clearTimer?.cancel();
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// Cancels a pending clear without clearing the clipboard.
  static void cancelScheduledClear() {
    _clearTimer?.cancel();
  }
}
