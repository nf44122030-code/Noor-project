import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notes_controller.dart';

class NotesHistoryPage extends StatelessWidget {
  const NotesHistoryPage({super.key});

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    return '${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    final notesController = Get.find<NotesController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: AppColors.gradientAppBar,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(color: Color(0x220EA5E9), blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.only(top: 52, bottom: 18, left: 8, right: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'notes_history_title'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

            // Content
            Expanded(
              child: Obx(() {
                final sessionNotes = notesController.sessionNotes;
                
              if (sessionNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Icon(
                            Icons.note_alt_rounded,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Session Notes Yet',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Enable AI Notes during your next expert session to automatically capture insights',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: sessionNotes.length,
                  itemBuilder: (context, index) {
                    final session = sessionNotes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        boxShadow: isDark ? AppColors.glowShadow(intensity: 0.06) : AppColors.cardShadow(),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/session-notes/${session.id}'),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(colors: AppColors.gradientPrimary),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              session.expertName.substring(0, 2).toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  session.expertName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.edit_note_rounded, size: 13, color: AppColors.primary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'AI Notes',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            session.expertTitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'share',
                                          child: Row(children: [
                                            Icon(Icons.share_rounded, size: 19, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                            const SizedBox(width: 12),
                                            Text('share'.tr, style: GoogleFonts.inter(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                          ]),
                                        ),
                                        PopupMenuItem(
                                          value: 'download',
                                          child: Row(children: [
                                            Icon(Icons.download_rounded, size: 19, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                            const SizedBox(width: 12),
                                            Text('download'.tr, style: GoogleFonts.inter(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                          ]),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            const Icon(Icons.delete_rounded, size: 19, color: AppColors.error),
                                            const SizedBox(width: 12),
                                            Text('delete'.tr, style: GoogleFonts.inter(color: AppColors.error)),
                                          ]),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _showDeleteDialog(context, notesController, session.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, height: 1),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildInfoChip(Icons.calendar_today_rounded, DateFormat('MMM dd, yyyy').format(session.sessionDate), isDark),
                                    _buildInfoChip(Icons.access_time_rounded, _formatDuration(session.duration), isDark),
                                    _buildInfoChip(Icons.notes_rounded, '${session.notes.length} notes', isDark),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text('AI', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.06),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          session.summary.split('\n').first,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            height: 1.5,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDim : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NotesController controller, String sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Delete Session Notes?', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('This will permanently delete all notes from this session. This action cannot be undone.', style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () {
                controller.deleteSession(sessionId);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('session_notes_deleted'.tr)));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );
  }
}
