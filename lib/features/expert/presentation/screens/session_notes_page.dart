import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/notes_controller.dart';
import '../../data/models/note_model.dart';

class SessionNotesPage extends StatefulWidget {
  final String sessionId;

  const SessionNotesPage({super.key, required this.sessionId});

  @override
  State<SessionNotesPage> createState() => _SessionNotesPageState();
}

class _SessionNotesPageState extends State<SessionNotesPage> {
  SessionNote? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionWithSync();
  }

  Future<void> _loadSessionWithSync() async {
    final notesController = Get.find<NotesController>();
    var session = notesController.getSessionById(widget.sessionId);

    // If session is local but missing AI content, OR session is missing entirely, try Firestore
    if (session == null || session.aiContent == null || session.aiContent!.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('bookings').doc(widget.sessionId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final aiNotes = data['ai_notes'] as String?;
          
          if (aiNotes != null && aiNotes.isNotEmpty) {
            // Use existing duration from Firestore if present, else default to 0
            final firestoreDuration = int.tryParse(data['duration']?.toString() ?? '0') ?? 0;
            
            if (session != null) {
              session = SessionNote(
                id: session.id,
                expertName: session.expertName,
                expertTitle: session.expertTitle,
                sessionDate: session.sessionDate,
                duration: session.duration > 0 ? session.duration : firestoreDuration,
                notes: session.notes,
                summary: session.summary,
                aiContent: aiNotes,
              );
            } else {
              // Create session from Firestore data
              session = SessionNote(
                id: widget.sessionId,
                expertName: data['expert_name'] ?? 'Expert',
                expertTitle: data['expert_title'] ?? 'Consultation',
                sessionDate: (data['session_date_ts'] as Timestamp?)?.toDate() ?? DateTime.now(),
                duration: firestoreDuration,
                notes: [],
                summary: 'Discussion overview from Firestore',
                aiContent: aiNotes,
              );
            }
            // Save/Update locally so it's available in Notes History next time
            await notesController.saveSession(
              id: session.id,
              expertName: session.expertName,
              expertTitle: session.expertTitle,
              duration: session.duration,
              aiContent: session.aiContent,
            );
          }
        }
      } catch (e) {
        debugPrint('Error syncing session from Firestore: $e');
      }
    }

    if (mounted) {
      setState(() {
        _session = session;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Session not found', style: TextStyle(color: colorScheme.onSurface, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Back to Home')),
            ],
          ),
        ),
      );
    }

    final session = _session!;
    final cardColor     = colorScheme.surface;
    final cardBorder    = isDark ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD);
    final textPrimary   = colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final headerGrad    = isDark
        ? [colorScheme.secondary, colorScheme.primary]
        : [colorScheme.primary, colorScheme.secondary];
    final accentBlue    = colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Curved Header ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: headerGrad,
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
            padding: const EdgeInsets.only(top: 40, bottom: 80, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SESSION NOTES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'AI Generated',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balanced alignment
              ],
            ),
          ),

          // ── Floating Check Icon ────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -48),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: cardColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.check_circle, size: 48, color: Color(0xFF10B981)),
            ),
          ),

          // ── Scrollable Content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Session Completed!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'AI has analyzed your conversation',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Session Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: headerGrad),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  session.expertName.isNotEmpty ? session.expertName.substring(0, 2).toUpperCase() : 'EX',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.expertName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    session.expertTitle,
                                    style: TextStyle(fontSize: 14, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: cardBorder),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.calendar_today,
                              DateFormat('MMM dd, yyyy').format(session.sessionDate),
                              accentBlue,
                              textSecondary,
                            ),
                            _buildInfoItem(
                              Icons.access_time,
                              _formatDuration(session.duration),
                              accentBlue,
                              textSecondary,
                            ),
                            _buildInfoItem(
                              Icons.note,
                              'Insights ready',
                              accentBlue,
                              textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Consolidated Notes Section
                  Text(
                    'Session Transcript & Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        final String rawText = session.aiContent?.isNotEmpty == true 
                            ? session.aiContent! 
                            : session.summary;
                        final String cleanedText = rawText.replaceAll('*', '').trim();

                        return Text(
                          cleanedText,
                          style: TextStyle(fontSize: 15, color: textPrimary, height: 1.6),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Done button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_rounded, color: Colors.white),
                      label: const Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color iconColor, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ],
    );
  }
}
