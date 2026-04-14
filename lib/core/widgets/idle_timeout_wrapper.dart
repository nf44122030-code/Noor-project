import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/auth/presentation/providers/auth_controller.dart';

/// Wraps the entire app and tracks user interaction.
/// If no touch is detected for [timeout], the user is automatically
/// logged out and redirected to the login screen.
class IdleTimeoutWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const IdleTimeoutWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 15),
  });

  @override
  State<IdleTimeoutWrapper> createState() => _IdleTimeoutWrapperState();
}

class _IdleTimeoutWrapperState extends State<IdleTimeoutWrapper>
    with WidgetsBindingObserver {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
    } else if (state == AppLifecycleState.paused) {
      // When app goes to background, accelerate timeout to 2 minutes
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(minutes: 2), _triggerLogout);
    }
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.timeout, _triggerLogout);
  }

  Future<void> _triggerLogout() async {
    final authController = Get.find<AuthController>();
    if (authController.isAuthenticated) {
      await authController.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      onScaleStart: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
