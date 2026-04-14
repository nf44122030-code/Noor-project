import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  final VoidCallback? onBack;
  const NotificationPage({super.key, this.onBack});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      return StreamBuilder<List<NotificationModel>>(
        stream: _firebaseService.getNotificationsStream(),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final unreadCount = notifications.where((n) => !n.isRead).length;

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: isDarkMode
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1929), Color(0xFF0A1929)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      ),
              ),
              child: Column(
                children: [
                  // Curved Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                            )
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                            ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(top: 40, bottom: 16, left: 24, right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                              onPressed: () {
                                if (widget.onBack != null) {
                                  widget.onBack!();
                                } else if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.notifications, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Actions Bar
                  if (notifications.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (unreadCount > 0)
                            TextButton.icon(
                              onPressed: () => _firebaseService.markAllNotificationsRead(),
                              icon: Icon(
                                Icons.done_all,
                                size: 16,
                                color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                              ),
                              label: Text(
                                'Mark all as read',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          TextButton.icon(
                            onPressed: () => _firebaseService.clearAllNotifications(),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Clear all',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Notifications List
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : notifications.isEmpty
                            ? _buildEmptyState(isDarkMode)
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  ...notifications.map((notification) => _buildNotificationItem(
                                        notification,
                                        isDarkMode,
                                      )),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 48,
              color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF0A1929),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later for updates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF0284C7).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, bool isDarkMode) {
    final iconColor = _getIconColor(notification.type, isDarkMode);

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _firebaseService.deleteNotification(notification.id.toString()),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _firebaseService.markNotificationAsRead(notification.id.toString());
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.only(
            left: notification.isRead ? 16 : 20,
            right: 16,
            top: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDarkMode ? const Color(0xFF132F4C).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.7))
                : (isDarkMode ? const Color(0xFF132F4C) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? (isDarkMode ? const Color(0xFF1E4976).withValues(alpha: 0.5) : const Color(0xFFE5E7EB))
                  : (isDarkMode ? const Color(0xFF0EA5E9).withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.3)),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Stack(
            children: [
              if (!notification.isRead)
                Positioned(
                  left: -12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E4976).withValues(alpha: 0.5) : const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notification.icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconColor(NotificationType type, bool isDarkMode) {
    if (isDarkMode) {
      switch (type) {
        case NotificationType.session: return const Color(0xFF0EA5E9);
        case NotificationType.message: return const Color(0xFF4ADE80);
        case NotificationType.update: return const Color(0xFFFBBF24);
        case NotificationType.achievement: return const Color(0xFFA78BFA);
        case NotificationType.reminder: return const Color(0xFFFB923C);
      }
    } else {
      switch (type) {
        case NotificationType.session: return const Color(0xFF0284C7);
        case NotificationType.message: return const Color(0xFF10B981);
        case NotificationType.update: return const Color(0xFFF59E0B);
        case NotificationType.achievement: return const Color(0xFF8B5CF6);
        case NotificationType.reminder: return const Color(0xFFF97316);
      }
    }
  }
}
