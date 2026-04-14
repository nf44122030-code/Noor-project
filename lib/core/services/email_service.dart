import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  EmailService  –  Sends transactional emails via the
///  "Trigger Email from Firestore" Firebase Extension.
///
///  All methods write a document to the [mail] collection.
///  The extension picks it up automatically and sends it via Gmail SMTP.
/// ─────────────────────────────────────────────────────────────────────────────
class EmailService {
  static final _mail = FirebaseFirestore.instance.collection('mail');

  static const String _from = 'Intellix <noorfayyad25122@gmail.com>';

  // ════════════════════════════════════════════════════════════════════════
  //  1 – New Booking Notification  (to Expert)
  // ════════════════════════════════════════════════════════════════════════
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
    final noteText =
        notes?.isNotEmpty == true ? notes! : 'No additional notes.';
    try {
      await _mail.add({
        'to': expertEmail,
        'from': _from,
        'message': {
          'subject': '📅 New Session Booking – $sessionDate at $sessionTime',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <h2 style="color:#0284C7;">New Session Booking</h2>
  <p>Hi <strong>$expertName</strong>,</p>
  <p>You have a new session booking from <strong>$userName</strong> ($userEmail).</p>
  <table style="border-collapse:collapse;width:100%;margin:16px 0;">
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Date</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$sessionDate</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Time</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$sessionTime</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Duration</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$duration minutes</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Notes</td>
        <td style="padding:8px;border:1px solid #E0F2FE;">$noteText</td></tr>
  </table>
  <p style="color:#6B7280;font-size:12px;">This email was sent by Intellix.</p>
</div>
''',
        },
      });
      debugPrint('📧 ✅ New booking email → $expertEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ New booking email error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  2 – Booking Confirmation  (to User)
  // ════════════════════════════════════════════════════════════════════════
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
          'subject': '✅ Session Confirmed – $sessionDate at $sessionTime',
          'html': '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <h2 style="color:#0284C7;">Session Confirmed!</h2>
  <p>Hi <strong>$userName</strong>,</p>
  <p>Your session with <strong>$expertName</strong> has been confirmed.</p>
  <table style="border-collapse:collapse;width:100%;margin:16px 0;">
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Expert</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$expertName</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Date</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$sessionDate</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Time</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$sessionTime</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Duration</td>
        <td style="padding:8px;border:1px solid #E0F2FE;"><strong>$duration minutes</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #E0F2FE;color:#6B7280;">Join Code</td>
        <td style="padding:8px;border:1px solid #E0F2FE;background-color:#F0F9FF;text-align:center;">
          <strong style="font-size:24px;color:#0284C7;letter-spacing:4px;">$sessionCode</strong>
        </td></tr>
  </table>
  <p>We look forward to your session!</p>
  <p style="color:#6B7280;font-size:12px;">This email was sent by Intellix.</p>
</div>
''',
        },
      });
      debugPrint('📧 ✅ Confirmation email → $userEmail');
      return true;
    } catch (e) {
      debugPrint('📧 ❌ Confirmation email error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  3 – Cancellation Notice  (to both User and Expert)
  // ════════════════════════════════════════════════════════════════════════
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
    final r = reason?.isNotEmpty == true ? reason! : 'No reason provided.';
    final cancellerLabel = cancelledBy == 'user' ? userName : expertName;

    String buildHtml(String recipientName, String otherParty) => '''
<div style="font-family:sans-serif;max-width:600px;margin:auto;">
  <h2 style="color:#DC2626;">Session Cancelled</h2>
  <p>Hi <strong>$recipientName</strong>,</p>
  <p>Unfortunately your session with <strong>$otherParty</strong> has been cancelled.</p>
  <table style="border-collapse:collapse;width:100%;margin:16px 0;">
    <tr><td style="padding:8px;border:1px solid #FEE2E2;color:#6B7280;">Date</td>
        <td style="padding:8px;border:1px solid #FEE2E2;"><strong>$sessionDate</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #FEE2E2;color:#6B7280;">Time</td>
        <td style="padding:8px;border:1px solid #FEE2E2;"><strong>$sessionTime</strong></td></tr>
    <tr><td style="padding:8px;border:1px solid #FEE2E2;color:#6B7280;">Cancelled by</td>
        <td style="padding:8px;border:1px solid #FEE2E2;">$cancellerLabel</td></tr>
    <tr><td style="padding:8px;border:1px solid #FEE2E2;color:#6B7280;">Reason</td>
        <td style="padding:8px;border:1px solid #FEE2E2;">$r</td></tr>
  </table>
  <p style="color:#6B7280;font-size:12px;">This email was sent by Intellix.</p>
</div>
''';

    try {
      // To user
      await _mail.add({
        'to': userEmail,
        'from': _from,
        'message': {
          'subject': '❌ Session Cancelled – $sessionDate at $sessionTime',
          'html': buildHtml(userName, expertName),
        },
      });
      debugPrint('📧 ✅ Cancellation email → $userEmail');
    } catch (e) {
      debugPrint('📧 ❌ Cancellation email (user) error: $e');
    }

    try {
      // To expert
      await _mail.add({
        'to': expertEmail,
        'from': _from,
        'message': {
          'subject': '❌ Session Cancelled – $sessionDate at $sessionTime',
          'html': buildHtml(expertName, userName),
        },
      });
      debugPrint('📧 ✅ Cancellation email → $expertEmail');
    } catch (e) {
      debugPrint('📧 ❌ Cancellation email (expert) error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Alias – keeps existing call sites working without changes
  // ════════════════════════════════════════════════════════════════════════
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
}
