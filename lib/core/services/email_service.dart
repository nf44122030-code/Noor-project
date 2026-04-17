import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static final _mail = FirebaseFirestore.instance.collection('mail');
  static const String _from = 'Intellix <noorfayyad25122@gmail.com>';

  // ── 1. Booking Received (to USER – pending, no session code yet) ─────────────
  static Future<bool> sendBookingReceivedEmail({
    required String userName,
    required String userEmail,
    required String expertName,
    required String sessionDate,
    required String sessionTime,
    required String duration,
    String? notes,
  }) async {
    final noteText = notes?.isNotEmpty == true ? notes! : 'No additional notes.';
    try {
      await _mail.add({
        'to': userEmail,
        'from': _from,
        'message': {
          'subject': '📋 Booking Request Received – Awaiting Expert Confirmation',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <div style="background:linear-gradient(135deg,#0284C7,#0EA5E9);padding:32px;border-radius:16px 16px 0 0;text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">📋 Request Received!</h1>
    <p style="color:rgba(255,255,255,0.85);margin:8px 0 0 0;">Your booking is pending expert confirmation</p>
  </div>
  <div style="padding:28px;background:#F8FAFC;border:1px solid #E0F2FE;border-top:none;border-radius:0 0 16px 16px;">
    <p>Hi <strong>$userName</strong>,</p>
    <p>Your session request with <strong>$expertName</strong> has been received and is awaiting their confirmation. You will receive another email with your join code once confirmed.</p>
    <table style="border-collapse:collapse;width:100%;margin:20px 0;border-radius:10px;overflow:hidden;">
      <tr style="background:#E0F2FE;"><td style="padding:10px 14px;color:#0369A1;font-weight:bold;">Expert</td><td style="padding:10px 14px;"><strong>$expertName</strong></td></tr>
      <tr style="background:#F0F9FF;"><td style="padding:10px 14px;color:#0369A1;font-weight:bold;">Date</td><td style="padding:10px 14px;">$sessionDate</td></tr>
      <tr style="background:#E0F2FE;"><td style="padding:10px 14px;color:#0369A1;font-weight:bold;">Time</td><td style="padding:10px 14px;">$sessionTime</td></tr>
      <tr style="background:#F0F9FF;"><td style="padding:10px 14px;color:#0369A1;font-weight:bold;">Duration</td><td style="padding:10px 14px;">$duration minutes</td></tr>
      <tr style="background:#E0F2FE;"><td style="padding:10px 14px;color:#0369A1;font-weight:bold;">Notes</td><td style="padding:10px 14px;">$noteText</td></tr>
    </table>
    <div style="background:#FEF3C7;border:1px solid #F59E0B;border-radius:10px;padding:14px;">
      <p style="margin:0;color:#92400E;font-size:13px;">⏳ <strong>Status: Awaiting Confirmation</strong> — The expert will confirm shortly.</p>
    </div>
    <p style="color:#6B7280;font-size:12px;margin-top:20px;">This email was sent by Intellix.</p>
  </div>
</div>''',
        },
      });
      debugPrint('📧 ✅ Booking-received email → $userEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ Booking-received email error: $e');
      return false;
    }
  }

  // ── 2. New Booking Notification (to EXPERT when user books) ──────────────────
  static Future<bool> sendNewBookingEmail({
    required String expertName,
    required String expertEmail,
    required String userName,
    required String userEmail,
    required String sessionDate,
    required String sessionTime,
    required String duration,
    String? notes,
  }) async {
    final noteText = notes?.isNotEmpty == true ? notes! : 'No additional notes.';
    try {
      await _mail.add({
        'to': expertEmail,
        'from': _from,
        'message': {
          'subject': '📅 New Session Request from $userName – $sessionDate',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <div style="background:linear-gradient(135deg,#7C3AED,#A78BFA);padding:32px;border-radius:16px 16px 0 0;text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">📅 New Booking Request</h1>
    <p style="color:rgba(255,255,255,0.85);margin:8px 0 0 0;">A client wants to book a session with you</p>
  </div>
  <div style="padding:28px;background:#F8FAFC;border:1px solid #EDE9FE;border-top:none;border-radius:0 0 16px 16px;">
    <p>Hi <strong>$expertName</strong>,</p>
    <p>You have a new session request from <strong>$userName</strong> ($userEmail). Log in to your Expert Portal to confirm or reject.</p>
    <table style="border-collapse:collapse;width:100%;margin:20px 0;border-radius:10px;overflow:hidden;">
      <tr style="background:#EDE9FE;"><td style="padding:10px 14px;color:#6D28D9;font-weight:bold;">Client</td><td style="padding:10px 14px;"><strong>$userName</strong> ($userEmail)</td></tr>
      <tr style="background:#F5F3FF;"><td style="padding:10px 14px;color:#6D28D9;font-weight:bold;">Date</td><td style="padding:10px 14px;">$sessionDate</td></tr>
      <tr style="background:#EDE9FE;"><td style="padding:10px 14px;color:#6D28D9;font-weight:bold;">Time</td><td style="padding:10px 14px;">$sessionTime</td></tr>
      <tr style="background:#F5F3FF;"><td style="padding:10px 14px;color:#6D28D9;font-weight:bold;">Duration</td><td style="padding:10px 14px;">$duration minutes</td></tr>
      <tr style="background:#EDE9FE;"><td style="padding:10px 14px;color:#6D28D9;font-weight:bold;">Notes</td><td style="padding:10px 14px;">$noteText</td></tr>
    </table>
    <p style="color:#6B7280;font-size:12px;margin-top:20px;">This email was sent by Intellix.</p>
  </div>
</div>''',
        },
      });
      debugPrint('📧 ✅ New booking email → $expertEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ New booking email error: $e');
      return false;
    }
  }

  // ── 3. Session Confirmed with Join Code (to USER) ────────────────────────────
  static Future<bool> sendConfirmationEmail({
    required String userName,
    required String userEmail,
    required String expertName,
    required String expertEmail,
    required String sessionDate,
    required String sessionTime,
    required String duration,
    required String sessionCode,
  }) async {
    try {
      await _mail.add({
        'to': userEmail,
        'from': _from,
        'message': {
          'subject': '✅ Session Confirmed – Your Join Code is Ready!',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <div style="background:linear-gradient(135deg,#059669,#10B981);padding:32px;border-radius:16px 16px 0 0;text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">✅ Session Confirmed!</h1>
    <p style="color:rgba(255,255,255,0.85);margin:8px 0 0 0;">Your appointment has been approved</p>
  </div>
  <div style="padding:28px;background:#F8FAFC;border:1px solid #D1FAE5;border-top:none;border-radius:0 0 16px 16px;">
    <p>Hi <strong>$userName</strong>,</p>
    <p>Your session with <strong>$expertName</strong> has been <strong style="color:#059669;">confirmed</strong>.</p>
    <table style="border-collapse:collapse;width:100%;margin:20px 0;border-radius:10px;overflow:hidden;">
      <tr style="background:#D1FAE5;"><td style="padding:10px 14px;color:#065F46;font-weight:bold;">Expert</td><td style="padding:10px 14px;"><strong>$expertName</strong></td></tr>
      <tr style="background:#ECFDF5;"><td style="padding:10px 14px;color:#065F46;font-weight:bold;">Date</td><td style="padding:10px 14px;">$sessionDate</td></tr>
      <tr style="background:#D1FAE5;"><td style="padding:10px 14px;color:#065F46;font-weight:bold;">Time</td><td style="padding:10px 14px;">$sessionTime</td></tr>
      <tr style="background:#ECFDF5;"><td style="padding:10px 14px;color:#065F46;font-weight:bold;">Duration</td><td style="padding:10px 14px;">$duration minutes</td></tr>
    </table>
    <div style="background:#F0FDF4;border:2px solid #059669;border-radius:14px;padding:24px;text-align:center;">
      <p style="margin:0 0 8px 0;color:#065F46;font-weight:bold;font-size:14px;">🔑 Your Session Join Code</p>
      <div style="background:white;border-radius:10px;padding:16px;display:inline-block;">
        <span style="font-size:36px;font-weight:900;color:#059669;letter-spacing:10px;">$sessionCode</span>
      </div>
      <p style="margin:12px 0 0 0;color:#6B7280;font-size:12px;">Enter this code in the Intellix app to join your session.</p>
    </div>
    <p style="color:#6B7280;font-size:12px;margin-top:20px;">This email was sent by Intellix.</p>
  </div>
</div>''',
        },
      });
      debugPrint('📧 ✅ Confirmation email → $userEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ Confirmation email error: $e');
      return false;
    }
  }

  // ── 4. Appointment Rejected (to USER when expert declines) ───────────────────
  static Future<bool> sendRejectionEmail({
    required String userName,
    required String userEmail,
    required String expertName,
    required String sessionDate,
    required String sessionTime,
    String? reason,
  }) async {
    final r = reason?.isNotEmpty == true ? reason! : 'No reason provided.';
    try {
      await _mail.add({
        'to': userEmail,
        'from': _from,
        'message': {
          'subject': '❌ Appointment Request Declined – $sessionDate at $sessionTime',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <div style="background:linear-gradient(135deg,#DC2626,#EF4444);padding:32px;border-radius:16px 16px 0 0;text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">❌ Request Declined</h1>
    <p style="color:rgba(255,255,255,0.85);margin:8px 0 0 0;">The expert was unable to accept your request</p>
  </div>
  <div style="padding:28px;background:#F8FAFC;border:1px solid #FEE2E2;border-top:none;border-radius:0 0 16px 16px;">
    <p>Hi <strong>$userName</strong>,</p>
    <p><strong>$expertName</strong> was unable to accept your request for <strong>$sessionDate at $sessionTime</strong>.</p>
    <div style="background:#FEF2F2;border:1px solid #FCA5A5;border-radius:10px;padding:14px;margin:20px 0;">
      <p style="margin:0;color:#991B1B;"><strong>Reason:</strong> $r</p>
    </div>
    <p>You can book with another expert or choose a different time slot.</p>
    <p style="color:#6B7280;font-size:12px;margin-top:20px;">This email was sent by Intellix.</p>
  </div>
</div>''',
        },
      });
      debugPrint('📧 ✅ Rejection email → $userEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ Rejection email error: $e');
      return false;
    }
  }

  // ── 5. Expert Cancelled Confirmed Session (to USER) ──────────────────────────
  static Future<bool> sendExpertCancellationEmail({
    required String userName,
    required String userEmail,
    required String expertName,
    required String sessionDate,
    required String sessionTime,
    String? reason,
  }) async {
    final r = reason?.isNotEmpty == true ? reason! : 'No reason provided.';
    try {
      await _mail.add({
        'to': userEmail,
        'from': _from,
        'message': {
          'subject': '⚠️ Session Cancelled by Expert – $sessionDate at $sessionTime',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <div style="background:linear-gradient(135deg,#D97706,#F59E0B);padding:32px;border-radius:16px 16px 0 0;text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">⚠️ Session Cancelled</h1>
    <p style="color:rgba(255,255,255,0.85);margin:8px 0 0 0;">Your confirmed session has been cancelled by the expert</p>
  </div>
  <div style="padding:28px;background:#F8FAFC;border:1px solid #FDE68A;border-top:none;border-radius:0 0 16px 16px;">
    <p>Hi <strong>$userName</strong>,</p>
    <p><strong>$expertName</strong> has had to cancel your confirmed session for <strong>$sessionDate at $sessionTime</strong>.</p>
    <div style="background:#FFFBEB;border:1px solid #F59E0B;border-radius:10px;padding:14px;margin:20px 0;">
      <p style="margin:0;color:#92400E;"><strong>Reason:</strong> $r</p>
    </div>
    <p>We apologize for the inconvenience. Please book a new session at your convenience.</p>
    <p style="color:#6B7280;font-size:12px;margin-top:20px;">This email was sent by Intellix.</p>
  </div>
</div>''',
        },
      });
      debugPrint('📧 ✅ Expert-cancellation email → $userEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ Expert-cancellation email error: $e');
      return false;
    }
  }

  // ── 6. User Cancelled Session (to EXPERT) ────────────────────────────────────
  static Future<bool> sendUserCancellationEmail({
    required String userName,
    required String userEmail,
    required String expertName,
    required String expertEmail,
    required String sessionDate,
    required String sessionTime,
    String? reason,
  }) async {
    final r = reason?.isNotEmpty == true ? reason! : 'No reason provided.';
    try {
      await _mail.add({
        'to': expertEmail,
        'from': _from,
        'message': {
          'subject': '⚠️ Session Cancelled by Client – $sessionDate at $sessionTime',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <div style="background:linear-gradient(135deg,#D97706,#F59E0B);padding:32px;border-radius:16px 16px 0 0;text-align:center;">
    <h1 style="color:white;margin:0;font-size:24px;">⚠️ Session Cancelled</h1>
    <p style="color:rgba(255,255,255,0.85);margin:8px 0 0 0;">Your client has cancelled the session</p>
  </div>
  <div style="padding:28px;background:#F8FAFC;border:1px solid #FDE68A;border-top:none;border-radius:0 0 16px 16px;">
    <p>Hi <strong>$expertName</strong>,</p>
    <p>Your client <strong>$userName</strong> ($userEmail) has cancelled the session scheduled for <strong>$sessionDate at $sessionTime</strong>.</p>
    <div style="background:#FFFBEB;border:1px solid #F59E0B;border-radius:10px;padding:14px;margin:20px 0;">
      <p style="margin:0;color:#92400E;"><strong>Reason:</strong> $r</p>
    </div>
    <p>We apologize for the inconvenience. The slot is now available for other bookings.</p>
    <p style="color:#6B7280;font-size:12px;margin-top:20px;">This email was sent by Intellix.</p>
  </div>
</div>''',
        },
      });
      debugPrint('📧 ✅ User-cancellation email → $expertEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ User-cancellation email error: $e');
      return false;
    }
  }

  // ── Aliases for backward compatibility ───────────────────────────────────────
  static Future<bool> sendBookingEmail({
    required String expertName,
    required String expertEmail,
    required String userName,
    required String userEmail,
    required String sessionDate,
    required String sessionTime,
    required String duration,
    String? notes,
  }) =>
      sendNewBookingEmail(
        expertName: expertName,
        expertEmail: expertEmail,
        userName: userName,
        userEmail: userEmail,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        duration: duration,
        notes: notes,
      );

  static Future<void> sendCancellationEmails({
    required String userName,
    required String userEmail,
    required String expertName,
    required String expertEmail,
    required String sessionDate,
    required String sessionTime,
    required String cancelledBy,
    String? reason,
  }) async {
    if (cancelledBy == 'user') {
      await sendUserCancellationEmail(
        userName: userName,
        userEmail: userEmail,
        expertName: expertName,
        expertEmail: expertEmail,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        reason: reason,
      );
    } else {
      await sendExpertCancellationEmail(
        userName: userName,
        userEmail: userEmail,
        expertName: expertName,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        reason: reason,
      );
    }
  }
}
