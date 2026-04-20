import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/email_service.dart';

class ExpertDashboardPage extends StatefulWidget {
  const ExpertDashboardPage({super.key});

  @override
  State<ExpertDashboardPage> createState() => _ExpertDashboardPageState();
}

class _ExpertDashboardPageState extends State<ExpertDashboardPage> {
  // Track which bookings are currently confirming to show loading spinners
  final Set<String> _processingBookings = {};

  Future<void> _handleConfirm(Map<String, dynamic> booking) async {
    final bookingId = booking['id'];
    setState(() => _processingBookings.add(bookingId));
    
    try {
      // 1. Confirm in Firestore — this is the critical step
      final sessionCode = await FirebaseService().confirmBooking(bookingId);
      
      // 2. Attempt to send confirmation email — fire-and-forget, never crash on failure
      unawaited(
        EmailService.sendConfirmationEmail(
          userName: booking['user_name'] ?? '',
          userEmail: booking['user_email'] ?? '',
          expertName: booking['expert_name'] ?? '',
          expertEmail: booking['expert_email'] ?? '',
          sessionDate: booking['session_date'] ?? '',
          sessionTime: booking['session_time'] ?? '',
          duration: booking['duration'] ?? '',
          sessionCode: sessionCode,
        ).catchError((e) {
          debugPrint('📧 Email send failed (non-fatal): $e');
          return false;
        }),
      );
      
      if (mounted) {
        Get.snackbar(
          'Booking Confirmed ✅', 
          'Session code: $sessionCode. Email notification sent to client.',
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('❌ Confirm error: $e');
      if (mounted) {
        Get.snackbar('Error', 'Failed to confirm booking. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _processingBookings.remove(bookingId));
      }
    }
  }

  Future<void> _handleReject(Map<String, dynamic> booking) async {
    final bookingId = booking['id'];
    final reason = await _showReasonDialog('Reject Appointment', 'Rejection reason (optional):', 'Unable to accommodate');
    if (reason == null) return;
    setState(() => _processingBookings.add(bookingId));
    try {
      await FirebaseService().rejectBooking(bookingId, reason: reason);
      unawaited(
        EmailService.sendRejectionEmail(
          userName: booking['user_name'] ?? '',
          userEmail: booking['user_email'] ?? '',
          expertName: booking['expert_name'] ?? '',
          sessionDate: booking['session_date'] ?? '',
          sessionTime: booking['session_time'] ?? '',
          reason: reason.isEmpty ? null : reason,
        ).catchError((e) { debugPrint('📧 Reject email failed: $e'); return false; }),
      );
      if (mounted) {
        Get.snackbar('Rejected', 'Booking declined. Client has been notified.',
            backgroundColor: Colors.red.shade800, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) Get.snackbar('Error', 'Failed to reject booking.');
    } finally {
      if (mounted) setState(() => _processingBookings.remove(bookingId));
    }
  }

  Future<void> _handleCancel(Map<String, dynamic> booking) async {
    final bookingId = booking['id'];
    final reason = await _showReasonDialog('Cancel Session', 'Cancellation reason (optional):', 'Unexpected schedule conflict');
    if (reason == null) return;
    setState(() => _processingBookings.add(bookingId));
    try {
      await FirebaseService().cancelBooking(bookingId, cancelledBy: 'expert', reason: reason);
      unawaited(
        EmailService.sendExpertCancellationEmail(
          userName: booking['user_name'] ?? '',
          userEmail: booking['user_email'] ?? '',
          expertName: booking['expert_name'] ?? '',
          sessionDate: booking['session_date'] ?? '',
          sessionTime: booking['session_time'] ?? '',
          reason: reason.isEmpty ? null : reason,
        ).catchError((e) { debugPrint('📧 Cancel email failed: $e'); return false; }),
      );
      if (mounted) {
        Get.snackbar('Cancelled', 'Session cancelled. Client has been notified.',
            backgroundColor: Colors.orange.shade800, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) Get.snackbar('Error', 'Failed to cancel session.');
    } finally {
      if (mounted) setState(() => _processingBookings.remove(bookingId));
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> booking) async {
    final bookingId = booking['id'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to permanently delete this session? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingBookings.add(bookingId));
    try {
      await FirebaseService().deleteBooking(bookingId);
      if (mounted) {
        Get.snackbar('Deleted', 'Session was deleted.',
            backgroundColor: Colors.grey.shade800, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) Get.snackbar('Error', 'Failed to delete session.');
    } finally {
      if (mounted) setState(() => _processingBookings.remove(bookingId));
    }
  }

  Future<String?> _showReasonDialog(String title, String label, String placeholder) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: placeholder, labelText: label),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showScheduleManager(Map<String, dynamic> expertProfile, AuthController authController) {
    final theme = Get.find<ThemeController>();
    final isDark = theme.isDarkMode;
    
    // Parse existing schedule
    final Map<String, TextEditingController> dayControllers = {
      'Monday': TextEditingController(),
      'Tuesday': TextEditingController(),
      'Wednesday': TextEditingController(),
      'Thursday': TextEditingController(),
      'Friday': TextEditingController(),
      'Saturday': TextEditingController(),
      'Sunday': TextEditingController(),
    };

    final rawSchedule = expertProfile['schedule'];
    if (rawSchedule is List) {
      for (var s in rawSchedule) {
        if (s is Map) {
          final day = s['day']?.toString();
          if (day != null && dayControllers.containsKey(day)) {
            final slots = s['slots'];
            if (slots is List) {
              dayControllers[day]!.text = slots.map((e) => e.toString()).join(', ');
            }
          }
        }
      }
    }

    bool isSavingLocal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manage Schedule', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Enter available time slots separated by commas (e.g. 09:00, 10:30, 14:00). Leave blank if unavailable.', 
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: dayControllers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: entry.value,
                            style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: entry.key,
                              labelStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                              hintText: 'e.g. 09:00, 10:00',
                              filled: true,
                              fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSavingLocal ? null : () async {
                        setModalState(() => isSavingLocal = true);
                        try {
                          List<Map<String, dynamic>> newSchedule = [];
                          for (var entry in dayControllers.entries) {
                            final slotsRaw = entry.value.text.trim();
                            if (slotsRaw.isNotEmpty) {
                              final slots = slotsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                              if (slots.isNotEmpty) {
                                newSchedule.add({'day': entry.key, 'slots': slots});
                              }
                            }
                          }

                          final expertId = expertProfile['id'] ?? expertProfile['email'];
                          if (expertId == null) throw Exception("Expert ID is missing");
                          
                          await FirebaseService().updateExpertProfileData(expertId, {'schedule': newSchedule});
                          
                          // Update active local state so UI doesn't require reload
                          final updatedProfile = Map<String, dynamic>.from(expertProfile);
                          updatedProfile['schedule'] = newSchedule;
                          authController.expertProfile.value = updatedProfile;

                          if (mounted) {
                            Navigator.pop(ctx);
                            Get.snackbar('Success', 'Availability schedule updated', 
                              backgroundColor: Colors.green.shade800, colorText: Colors.white);
                          }
                        } catch (e) {
                          if (mounted) Get.snackbar('Error', 'Failed to update schedule.');
                        } finally {
                          setModalState(() => isSavingLocal = false);
                        }
                      },
                      child: isSavingLocal 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Save Schedule', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();
    final expertProfile = authController.expertProfile;

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final name = expertProfile['name'] ?? 'Expert';
      final specialty = expertProfile['specialty'] ?? '';

      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          elevation: 0,
          title: Text(
            'Expert Portal',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_calendar_rounded,
                  color: isDark ? Colors.white70 : Colors.black54),
              tooltip: 'Manage Schedule',
              onPressed: () => _showScheduleManager(expertProfile, authController),
            ),
            IconButton(
              icon: Icon(Icons.logout,
                  color: isDark ? Colors.white70 : Colors.black54),
              onPressed: () => authController.logout(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (specialty.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    specialty,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  _buildStatCard(
                      'Total\nSessions',
                      '${expertProfile['sessions_completed'] ?? 0}',
                      Icons.videocam,
                      isDark),
                  const SizedBox(width: 16),
                  _buildStatCard(
                      'Profile\nRating',
                      '${expertProfile['rating'] ?? 'N/A'}',
                      Icons.star_rounded,
                      isDark),
                ],
              ),

              const SizedBox(height: 32),
              Text(
                'Upcoming Appointments',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseService().getExpertBookingsStream(expertProfile['email'] ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bookings = snapshot.data ?? [];
                  
                  // Filter out ringing calls to display them prominently at the top
                  final ringingCall = bookings.firstWhereOrNull((b) => b['call_status'] == 'ringing');
                  
                  final activeStatuses = ['pending', 'confirmed'];
                  final upcomingBookings = bookings.where((b) => b['id'] != ringingCall?['id'] && activeStatuses.contains(b['status'])).toList();
                  final pastBookings = bookings.where((b) => b['id'] != ringingCall?['id'] && !activeStatuses.contains(b['status'])).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (ringingCall != null) _buildIncomingCallCard(ringingCall, isDark),
                      
                      if (upcomingBookings.isEmpty && ringingCall == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No upcoming sessions',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When users book sessions with you, they will appear here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...upcomingBookings.map((booking) => _buildBookingCard(booking, isDark, false)),
                        
                      if (pastBookings.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Past Sessions',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...pastBookings.map((booking) => _buildBookingCard(booking, isDark, true)),
                      ]
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDark, bool isPast) {
    final status = booking['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isConfirmed = status == 'confirmed';
    final sessionCode = booking['session_code'];
    final isProcessing = _processingBookings.contains(booking['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking['session_date']} • ${booking['session_time']}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withValues(alpha: 0.2) : (isConfirmed ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange : (isConfirmed ? Colors.green : Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['user_name'] ?? 'Client',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      booking['user_email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['notes'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => _handleReject(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _handleConfirm(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    child: isProcessing
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          if (isConfirmed && sessionCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('Session Join Code',
                    style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 4),
                  Text(sessionCode,
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text('An email with this code has been sent to the client.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : () => _handleCancel(booking),
                icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.orange),
                label: Text('Cancel Session', style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (isPast) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: isProcessing ? null : () => _handleDelete(booking),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                label: Text('Delete Record', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomingCallCard(Map<String, dynamic> booking, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Pulsing Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  curve: Curves.easeInOut,
                  onEnd: () { /* TweenAnimationBuilder handles repeating visually if we wrap it in a repeating controller, but simple scale tween is fine here too, or just an icon. Let's keep it simple. */ },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.ring_volume, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incoming Video Call...',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['user_name'] ?? 'Client',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Answer the call
                      final bookingId = booking['id'];
                      final sessionCode = booking['session_code'];
                      await FirebaseService().answerCall(bookingId);
                      if (mounted) {
                        context.push('/video-session', extra: {
                          'expertName': booking['expert_name'],
                          'expertTitle': booking['expert_title'],
                          'initialCode': sessionCode,
                          'isExpert': true,
                        });
                      }
                    },
                    icon: const Icon(Icons.videocam),
                    label: Text('Answer Call', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
