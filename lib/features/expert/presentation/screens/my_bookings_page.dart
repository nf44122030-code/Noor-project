import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/email_service.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  final _themeController = Get.find<ThemeController>();

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _firebaseService.getMyBookings();
      setState(() { _bookings = bookings; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(String tab) {
    if (tab == 'All') return _bookings;
    return _bookings.where((b) => (b['status'] ?? '') == tab.toLowerCase()).toList();
  }

  // ── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String status) => switch (status) {
    'confirmed'  => const Color(0xFF059669),
    'completed'  => const Color(0xFF2563EB),
    'cancelled'  => const Color(0xFFDC2626),
    _            => const Color(0xFFF59E0B),     // pending
  };

  IconData _statusIcon(String status) => switch (status) {
    'confirmed'  => Icons.check_circle_rounded,
    'completed'  => Icons.task_alt_rounded,
    'cancelled'  => Icons.cancel_rounded,
    _            => Icons.hourglass_top_rounded, // pending
  };

  String _statusLabel(String status) => switch (status) {
    'confirmed'  => 'Confirmed',
    'completed'  => 'Completed',
    'cancelled'  => 'Cancelled',
    _            => 'Pending',
  };

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _confirm(Map<String, dynamic> b) async {
    final code = await _firebaseService.confirmBooking(b['id']);
    await EmailService.sendConfirmationEmail(
      userName:    b['user_name'] ?? '',
      userEmail:   b['user_email'] ?? '',
      expertName:  b['expert_name'] ?? '',
      expertEmail: b['expert_email'] ?? '',
      sessionDate: b['session_date'] ?? '',
      sessionTime: b['session_time'] ?? '',
      duration:    (b['duration'] ?? '60').toString(),
      sessionCode: code,
    );
    _showSnack('✅ Booking confirmed! Confirmation email sent.', const Color(0xFF059669));
    _loadBookings();
  }

  Future<void> _cancel(Map<String, dynamic> b) async {
    String? reason;
    final confirmed = await _showCancelDialog((r) => reason = r);
    if (!confirmed) return;

    await _firebaseService.cancelBooking(b['id'], cancelledBy: 'user', reason: reason);
    await EmailService.sendCancellationEmails(
      userName:    b['user_name'] ?? '',
      userEmail:   b['user_email'] ?? '',
      expertName:  b['expert_name'] ?? '',
      expertEmail: b['expert_email'] ?? '',
      sessionDate: b['session_date'] ?? '',
      sessionTime: b['session_time'] ?? '',
      cancelledBy: 'user',
      reason:      reason,
    );
    _showSnack('❌ Booking cancelled. Both parties have been notified.', const Color(0xFFDC2626));
    _loadBookings();
  }

  Future<void> _complete(Map<String, dynamic> b) async {
    await _firebaseService.completeBooking(b['id']);
    _showSnack('🎉 Session marked as completed!', const Color(0xFF2563EB));
    _loadBookings();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  Future<bool> _showCancelDialog(void Function(String?) onReason) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
          SizedBox(width: 8),
          Text('Cancel Booking'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Are you sure you want to cancel this session?'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Booking')),
          ElevatedButton(
            onPressed: () { onReason(controller.text.trim()); Navigator.pop(ctx, true); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _themeController.isDarkMode;
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF0A1929), Color(0xFF0A1929)])
                : const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)]),
          ),
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                      : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)]),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                ),
                padding: const EdgeInsets.only(top: 48, bottom: 0, left: 16, right: 16),
                child: Column(
                  children: [
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop()),
                      const Expanded(
                        child: Center(child: Text('MY BOOKINGS',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                color: Colors.white, letterSpacing: 2.5)))),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        onPressed: _loadBookings),
                    ]),
                    const SizedBox(height: 8),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: _tabs.map((tab) {
                          final list = _filtered(tab);
                          if (list.isEmpty) {
                            return Center(
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.calendar_today_outlined, size: 64,
                                    color: isDark ? Colors.white24 : Colors.black12),
                                const SizedBox(height: 16),
                                Text('No ${tab.toLowerCase()} bookings',
                                    style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontSize: 16)),
                              ]),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                              itemCount: list.length,
                              itemBuilder: (_, i) => _buildCard(list[i], isDark),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCard(Map<String, dynamic> b, bool isDark) {
    final status    = b['status'] ?? 'pending';
    final statusClr = _statusColor(status);
    final canCancel  = status == 'pending' || status == 'confirmed';
    final canConfirm = status == 'pending';
    final canComplete = status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E4976) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header with status ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusClr.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: statusClr.withValues(alpha: 0.2))),
            ),
            child: Row(children: [
              Icon(_statusIcon(status), color: statusClr, size: 18),
              const SizedBox(width: 8),
              Text(_statusLabel(status),
                  style: TextStyle(color: statusClr, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text(b['session_date'] ?? '',
                  style: TextStyle(fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
            ]),
          ),

          // ── Card body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Expert name
              Row(children: [
                const Icon(Icons.person_rounded, size: 16, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(b['expert_name'] ?? 'Expert',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827))),
                ),
              ]),
              const SizedBox(height: 10),

              // Details row
              Wrap(spacing: 12, runSpacing: 8, children: [
                _infoChip(Icons.access_time_rounded, b['session_time'] ?? '', isDark),
                _infoChip(Icons.timer_rounded, '${b['duration'] ?? 60} min', isDark),
              ]),

              if ((b['notes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(b['notes'],
                          style: TextStyle(fontSize: 12,
                              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))),
                    ),
                  ]),
                ),
              ],

              // ── Action buttons ──────────────────────────────────────
              if (canCancel || canComplete) ...[
                const SizedBox(height: 14),
                Row(children: [
                  if (canConfirm) ...[
                    Expanded(
                      child: _actionButton(
                        label: 'Confirm',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF059669),
                        onTap: () => _confirm(b),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (canComplete)
                    Expanded(
                      child: _actionButton(
                        label: 'Mark Done',
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF2563EB),
                        onTap: () => _complete(b),
                      ),
                    ),
                  if (canComplete || canConfirm) const SizedBox(width: 10),
                  if (canCancel)
                    Expanded(
                      child: _actionButton(
                        label: 'Cancel',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFDC2626),
                        onTap: () => _cancel(b),
                        outlined: true,
                      ),
                    ),
                ]),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF1E4976) : const Color(0xFFBFDBFE)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))),
      ]),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
