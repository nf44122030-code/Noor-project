import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../home/presentation/widgets/glowing_pill_3d.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/message.dart';

class AIAssistantPage extends StatefulWidget {
  final String? sessionId;
  final String? initialMessage;
  const AIAssistantPage({super.key, this.sessionId, this.initialMessage});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Multimodal support
  final List<XFile> _selectedFiles = [];
  bool _isPickingFile = false;
  bool _isSending = false;
  bool _isSendingAttachment = false;

  // ── Speech-to-text ──────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Persisted across navigation — survives pop/push within the same app session
  // Only cleared when the user explicitly taps "New Chat"
  static String? _persistedSessionId;
  static List<Message>? _persistedMessages;
  
  late String _sessionId;
  bool _hasText = false;
  bool _historyOpen = false;
  bool _historyEverOpened = false;

  // Suggestion chips
  static const List<Map<String, dynamic>> _suggestions = [
    {'label': 'Analyze sales trends', 'icon': Icons.trending_up_rounded},
    {'label': 'Generate revenue forecast', 'icon': Icons.bar_chart_rounded},
    {'label': 'Customer behavior insights', 'icon': Icons.people_alt_rounded},
    {'label': 'Market analysis report', 'icon': Icons.insights_rounded},
    {'label': 'Business feasibility', 'icon': Icons.lightbulb_rounded},
  ];

  final themeController = Get.find<ThemeController>();

  static const _gradBlue = [Color(0xFF2563EB), Color(0xFF0EA5E9)];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final has = _messageController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    // Pulse animation for mic button while listening
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Init speech recognition
    _initSpeech();

    // Load last session or create fresh one
    _loadOrCreateSession();
  }

  Future<void> _loadOrCreateSession() async {
    if (widget.sessionId != null) {
      if (mounted) {
        setState(() {
          _sessionId = widget.sessionId!;
          _persistedSessionId = _sessionId;
        });
      }
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendMessage(override: widget.initialMessage);
        });
      }
      return;
    }

    // Re-use the persisted session if one exists (e.g. user navigated away and came back)
    if (_persistedSessionId != null) {
      if (mounted) setState(() => _sessionId = _persistedSessionId!);
    } else {
      // First time opening AI chat — create a fresh session
      _sessionId = const Uuid().v4();
      _persistedSessionId = _sessionId;
    }

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(override: widget.initialMessage);
      });
    }
  }

  void _startNewChat() {
    setState(() {
      _persistedSessionId = null;
      _persistedMessages = null;
      _sessionId = const Uuid().v4();
      _persistedSessionId = _sessionId;
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == stt.SpeechToText.notListeningStatus || status == 'done') {
          if (mounted) {
            setState(() => _isListening = false);
            _pulseCtrl.stop();
            _pulseCtrl.reset();
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _pulseCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  // ── Voice input ─────────────────────────────────────────────────────────────
  Future<void> _toggleSpeech() async {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Speech recognition not available on this device.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF374151),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    _pulseCtrl.repeat(reverse: true);
    _focusNode.unfocus();

    await _speech.listen(
      onResult: (result) {
        // Guard: ignore late results that arrive after we stopped listening
        if (!_isListening) return;
        if (mounted) {
          setState(() {
            _messageController.text = result.recognizedWords;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
            _hasText = result.recognizedWords.isNotEmpty;
          });
        }
        // Auto-send on final result then clear the field
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          final text = result.recognizedWords.trim();
          _stopListening().then((_) async {
            if (mounted && text.isNotEmpty) {
              try {
                await _firebaseService.sendChatMessage(text,
                    sessionId: _sessionId);
                _messageController.clear();
                setState(() => _hasText = false);
                HapticFeedback.lightImpact();
                _scrollToBottom();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send message: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  // ── Multimodal ──────────────────────────────────────────────────────────────
  Future<void> _pickFiles() async {
    if (_isPickingFile) return;

    final isDark = themeController.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF132F4C) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_rounded,
                  color: isDark ? Colors.white : Colors.black),
              title: Text('Photo Gallery',
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isPickingFile = true);
                try {
                  final ImagePicker picker = ImagePicker();
                  final List<XFile> images = await picker.pickMultiImage();
                  if (images.isNotEmpty && mounted) {
                    setState(() {
                      _selectedFiles.addAll(images);
                    });
                  }
                } catch (e) {
                  debugPrint('Image picking error: $e');
                } finally {
                  if (mounted) setState(() => _isPickingFile = false);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded,
                  color: isDark ? Colors.white : Colors.black),
              title: Text('Take a Photo',
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isPickingFile = true);
                try {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null && mounted) {
                    setState(() {
                      _selectedFiles.add(image);
                    });
                  }
                } catch (e) {
                  debugPrint('Camera error: $e');
                } finally {
                  if (mounted) setState(() => _isPickingFile = false);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file_rounded,
                  color: isDark ? Colors.white : Colors.black),
              title: Text('Documents (PDF, CSV, TXT)',
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isPickingFile = true);
                try {
                  // Use FileType.any for maximum browser compatibility.
                  // Browser-level filtering (FileType.custom) is flaky on Chrome/Safari.
                  // We validate extensions ourselves inside the app instead.
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: true,
                    withData: true, // CRITICAL for Web — loads bytes into memory immediately
                  );
                  if (result != null && result.files.isNotEmpty && mounted) {
                    final allowedExtensions = ['pdf', 'txt', 'csv'];
                    int addedCount = 0;

                    for (var f in result.files) {
                      final ext = f.name.split('.').last.toLowerCase();

                      // Manual extension validation
                      if (!allowedExtensions.contains(ext)) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${f.name}" is not supported. Please use PDF, TXT, or CSV.'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        }
                        continue;
                      }

                      // Bytes MUST be present on Web (path is unavailable)
                      if (f.bytes != null && f.bytes!.isNotEmpty) {
                        setState(() {
                          _selectedFiles.add(XFile.fromData(f.bytes!, name: f.name));
                        });
                        addedCount++;
                      } else {
                        debugPrint('[FilePicker] bytes are null for ${f.name} — skipping.');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not read "${f.name}". Please try again.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }

                    // Success feedback
                    if (addedCount > 0 && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('$addedCount file${addedCount > 1 ? 's' : ''} added successfully'),
                          ]),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('[FilePicker] error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('File picker error: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isPickingFile = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  // ── Send ─────────────────────────────────────────────────────────────────────
  Future<void> _sendMessage({String? override}) async {
    if (_isSending) return;
    
    final text = override ?? _messageController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;

    final List<XFile> filesToSend = List.from(_selectedFiles);
    final hasAttachment = filesToSend.isNotEmpty;

    _messageController.clear();
    setState(() {
      _hasText = false;
      _selectedFiles.clear();
      _isSending = true;
      _isSendingAttachment = hasAttachment;
    });

    HapticFeedback.lightImpact();
    _scrollToBottom();

    try {
      // Pre-process attachments into bytes and mimeTypes
      List<Map<String, dynamic>>? processedAttachments;
      if (filesToSend.isNotEmpty) {
        processedAttachments = [];
        for (var xfile in filesToSend) {
          final bytes = await xfile.readAsBytes();
          final String fileName = xfile.name.toLowerCase();
          String mimeType = xfile.mimeType ?? 'application/octet-stream';
          
          if (mimeType == 'application/octet-stream') {
            if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
              mimeType = 'image/jpeg';
            } else if (fileName.endsWith('.png')) {
              mimeType = 'image/png';
            } else if (fileName.endsWith('.pdf')) {
              mimeType = 'application/pdf';
            } else if (fileName.endsWith('.csv')) {
              mimeType = 'text/csv';
            } else if (fileName.endsWith('.txt')) {
              mimeType = 'text/plain';
            } else if (fileName.endsWith('.heic')) {
              mimeType = 'image/heic';
            } else if (fileName.endsWith('.heif')) {
              mimeType = 'image/heif';
            } else if (fileName.endsWith('.webp')) {
              mimeType = 'image/webp';
            }
          }

          processedAttachments.add({
            'bytes': bytes,
            'mimeType': mimeType,
          });
        }
      }

      await _firebaseService.sendChatMessage(
        text,
        sessionId: _sessionId,
        attachments: processedAttachments,
      );
    } catch (e) {
      debugPrint('UI _sendMessage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isSendingAttachment = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw) ?? DateTime.now();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _relativeDate(dynamic rawTs) {
    if (rawTs == null) return '';
    DateTime? dt;
    try {
      dt = DateTime.tryParse(rawTs.toString());
    } catch (_) {}
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  void _toggleHistory() {
    setState(() {
      _historyOpen = !_historyOpen;
      if (_historyOpen) {
        _historyEverOpened = true;
        _focusNode.unfocus();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final bg = isDark ? const Color(0xFF0A1929) : const Color(0xFFF0F9FF);

      return Material(
        color: bg,
        child: Stack(
          children: [
            // ── Main chat column ──────────────────────────────────────────────
            Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    key: ValueKey(
                        _sessionId), // Force full rebuild on session change
                    stream: _firebaseService.getChatMessagesStream(
                        sessionId: _sessionId),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? _persistedMessages ?? [];
                      if (snapshot.hasData) {
                        _persistedMessages = snapshot.data;
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _scrollToBottom());
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: messages.isEmpty
                                ? _buildEmptyState(isDark)
                                : _buildMessageList(messages, isDark),
                          ),
                          _buildSuggestions(isDark, messages),
                          _buildInputBar(isDark),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── History overlay backdrop ──────────────────────────────────────
            if (_historyOpen)
              GestureDetector(
                onTap: _toggleHistory,
                child: AnimatedOpacity(
                  opacity: _historyOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),

            // ── History slide-in panel (lazy — only built after first open) ──
            if (_historyEverOpened)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: _historyOpen ? 0 : -320,
                top: 0,
                bottom: 0,
                width: 300,
                child: _buildHistoryPanel(isDark),
              ),
          ],
        ),
      );
    });
  }

  // ── History Panel ─────────────────────────────────────────────────────────────
  Widget _buildHistoryPanel(bool isDark) {
    final bgPanel = isDark ? const Color(0xFF0D2137) : Colors.white;
    final borderCol =
        isDark ? const Color(0xFF1E4976) : const Color(0xFFE5E7EB);
    final textPri = isDark ? Colors.white : const Color(0xFF111827);
    final textSec = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    const activeBlue = Color(0xFF2563EB);
    final activeBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);

    return Container(
      decoration: BoxDecoration(
        color: bgPanel,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientAppBar,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 20,
              left: 20,
              right: 12,
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chat History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // New Chat
                GestureDetector(
                  onTap: () {
                    setState(() => _historyOpen = false);
                    _startNewChat(); // Properly clears the persisted session
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('New',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Close panel
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _toggleHistory,
                ),
              ],
            ),
          ),

          // Session list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getAiSessionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2563EB), strokeWidth: 2));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Could not load history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSec, fontSize: 13)),
                    ),
                  );
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: isDark
                                ? const Color(0xFF4B5563)
                                : const Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        Text('No conversations yet',
                            style: TextStyle(fontSize: 13, color: textSec)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, indent: 16, endIndent: 16, color: borderCol),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final sid = session['id'] as String? ?? '';
                    final title = session['title'] as String? ?? 'Conversation';
                    final isActive = sid == _sessionId;
                    final dateLabel = _relativeDate(
                        session['updated_at'] ?? session['created_at']);

                    return Dismissible(
                      key: ValueKey(sid),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: const Color(0xFFEF4444),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      confirmDismiss: (_) =>
                          _confirmDeleteSession(context, title),
                      onDismissed: (_) async {
                        await _firebaseService.deleteAiSession(sid);
                        if (isActive) {
                          setState(() => _sessionId = const Uuid().v4());
                        }
                      },
                      child: InkWell(
                        onTap: () => setState(() {
                          _sessionId = sid;
                          _historyOpen = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive ? activeBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isActive
                                ? Border.all(
                                    color: activeBlue.withValues(alpha: 0.4),
                                    width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: isActive
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF2563EB),
                                            Color(0xFF0EA5E9)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isActive
                                      ? null
                                      : (isDark
                                          ? const Color(0xFF1E3A5F)
                                          : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(Icons.chat_rounded,
                                    color: isActive
                                        ? Colors.white
                                        : (isDark
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF6B7280)),
                                    size: 17),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isActive ? activeBlue : textPri,
                                      ),
                                    ),
                                    if (dateLabel.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(dateLabel,
                                          style: TextStyle(
                                              fontSize: 11, color: textSec)),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    maxWidth: 28, maxHeight: 28),
                                icon: Icon(Icons.close_rounded,
                                    size: 15,
                                    color: isDark
                                        ? const Color(0xFF4B5563)
                                        : const Color(0xFFD1D5DB)),
                                onPressed: () async {
                                  final ok = await _confirmDeleteSession(
                                      context, title);
                                  if (ok == true) {
                                    await _firebaseService.deleteAiSession(sid);
                                    if (isActive) {
                                      setState(
                                          () => _sessionId = const Uuid().v4());
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientAppBar,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x220EA5E9),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: 4,
        right: 4,
      ),
      child: Row(
        children: [
          // History toggle
          IconButton(
            tooltip: 'Chat History',
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: _toggleHistory,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Intellix AI',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
            onPressed: _showNewChatDialog,
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Conversation'),
        content: const Text('Start a fresh conversation with the AI?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewChat(); // Uses the persisted session logic
            },
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a session.
  /// Returns true if the user confirmed, false/null otherwise.
  Future<bool?> _confirmDeleteSession(BuildContext ctx, String title) {
    final isDark = themeController.isDarkMode;
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F2540) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_forever_rounded,
              color: Color(0xFFEF4444), size: 26),
        ),
        title: Text(
          'Delete conversation?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        content: Text(
          title.isNotEmpty
              ? '"$title" will be permanently deleted and cannot be recovered.'
              : 'This conversation will be permanently deleted and cannot be recovered.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E4976)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF6B7280),
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Delete',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 160,
              child: GlowingPill3D(isDarkMode: isDark),
            ),
            const SizedBox(height: 28),
            Text(
              'Your AI Business Advisor',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ask me anything about business strategy, market analysis, or your financial planning.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(bool isDark) {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final name = file.name;
          final isImage = name.toLowerCase().endsWith('.jpg') ||
              name.toLowerCase().endsWith('.jpeg') ||
              name.toLowerCase().endsWith('.png') ||
              name.toLowerCase().endsWith('.webp');

          return Container(
            width: isImage ? 80 : 150,
            margin: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: isImage ? EdgeInsets.zero : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A5F) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isImage
                        ? FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                );
                              }
                              return const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2));
                            },
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                name.toLowerCase().endsWith('.pdf')
                                    ? Icons.picture_as_pdf_rounded
                                    : name.toLowerCase().endsWith('.csv')
                                        ? Icons.table_chart_rounded
                                        : Icons.insert_drive_file_rounded,
                                color: name.toLowerCase().endsWith('.pdf')
                                    ? Colors.redAccent
                                    : Colors.blueAccent,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name.isEmpty ? 'File' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () => _removeFile(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────────
  Widget _buildMessageList(List<Message> messages, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prevMsg = index > 0 ? messages[index - 1] : null;
        final showTimestamp = prevMsg == null || msg.type != prevMsg.type;
        // The very last AI/bot message that is NOT the typing indicator gets typewriter effect
        final isLatestAI = (msg.type == 'ai' || msg.type == 'bot') &&
            msg.text != '...' &&
            index == messages.length - 1;
        return _AnimatedMessageBubble(
          key: ValueKey(msg.id),
          message: msg,
          isDark: isDark,
          showTimestamp: showTimestamp,
          formattedTime: _formatTime(msg.time),
          index: index,
          isLatestAI: isLatestAI,
        );
      },
    );
  }

  // ── Suggestion chips ───────────────────────────────────────────────────
  Widget _buildSuggestions(bool isDark, List<Message> messages) {
    if (messages.isNotEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _sendMessage(override: s['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s['icon'] as IconData,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.accent : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────────
  Widget _buildInputBar(bool isDark) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Unified Attachment Preview ──────────────────────────────────
                _buildAttachmentPreview(isDark),

                if (_isSendingAttachment && _isSending)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Analyzing your business documents...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isListening)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A0A0A)
                          : const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                        children: [
                          // Pulsing mic icon
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: child,
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: Colors.red,
                                size: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _messageController.text.isEmpty
                                  ? 'Listening… speak your message'
                                  : _messageController.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontStyle: _messageController.text.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: _messageController.text.isEmpty
                                    ? Colors.red.withValues(alpha: 0.7)
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _stopListening,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Stop',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),


            // ── Main input row ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132F4C) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isListening
                      ? Colors.red.withValues(alpha: 0.5)
                      : (isDark
                          ? const Color(0xFF1E4976)
                          : const Color(0xFFE5E7EB)),
                  width: _isListening ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? Colors.red.withValues(alpha: 0.12)
                        : const Color(0xFF2563EB)
                            .withValues(alpha: _hasText ? 0.15 : 0.05),
                    blurRadius: (_hasText || _isListening) ? 16 : 8,
                    spreadRadius: (_hasText || _isListening) ? 1 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Attachment button ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: IconButton(
                      icon: Icon(
                        _selectedFiles.isNotEmpty
                            ? Icons.add_circle_rounded
                            : Icons.add_rounded,
                        color: _selectedFiles.isNotEmpty
                            ? Colors.greenAccent
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      onPressed: _pickFiles,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening...'
                            : 'Ask or speak your question...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: _isListening
                              ? Colors.red.withValues(alpha: 0.5)
                              : (isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── Mic button (shown when no text and no files) ─────────────────────────
                  if (!_hasText && _selectedFiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _isListening ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: GestureDetector(
                          onTap: _toggleSpeech,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.red
                                  : (isDark
                                      ? const Color(0xFF1E3A5F)
                                      : const Color(0xFFEFF6FF)),
                              shape: BoxShape.circle,
                              boxShadow: _isListening
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.red.withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              _isListening
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded,
                              size: 20,
                              color: _isListening
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF60A5FA)
                                      : AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Send button (shown when text or files exist) ────────────────────
                  if (_hasText || _selectedFiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, right: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: _gradBlue),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2563EB),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Animated message bubble
// ══════════════════════════════════════════════════════════════════════════════
class _AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isDark;
  final bool showTimestamp;
  final String formattedTime;
  final int index;
  final bool isLatestAI;

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.showTimestamp,
    required this.formattedTime,
    required this.index,
    this.isLatestAI = false,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.message.type == 'user' ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: math.min(widget.index * 30, 150)),
        () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _MessageBubble(
          message: widget.message,
          isDark: widget.isDark,
          showTimestamp: widget.showTimestamp,
          formattedTime: widget.formattedTime,
          isLatestAI: widget.isLatestAI,
        ),
      ),
    );
  }
}

// ── Bubble content ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isDark;
  final bool showTimestamp;
  final String formattedTime;
  final bool isLatestAI;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.showTimestamp,
    required this.formattedTime,
    this.isLatestAI = false,
  });

  bool get _isUser => message.type == 'user';
  bool get _isTyping => !_isUser && message.text == '...';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    if (!_isTyping) {
                      Clipboard.setData(ClipboardData(text: message.text));
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(children: [
                            Icon(Icons.copy_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Copied to clipboard'),
                          ]),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF1D4ED8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: _isTyping
                      ? _TypingIndicator(isDark: isDark)
                      : _buildBubble(context),
                ),
              ),
            ],
          ),
          if (formattedTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: _isUser
                  ? const EdgeInsets.only(right: 40)
                  : const EdgeInsets.only(left: 40),
              child: Text(
                formattedTime,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color:
                      isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    if (_isUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.hasAttachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Document attached',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // AI bubble — may contain a table
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
            color: isDark ? const Color(0xFF1E4976) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: _buildAIContent(context),
      ),
    );
  }

  Widget _buildAIContent(BuildContext context) {
    // For the latest AI response (non-table), animate with typewriter
    if (!message.containsTable) {
      if (isLatestAI) {
        return _TypewriterText(
          text: message.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color:
                isDark ? const Color(0xFFE5E7EB) : AppColors.textPrimaryLight,
          ),
        );
      }
      return Text(
        message.text,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.6,
          color: isDark ? const Color(0xFFE5E7EB) : AppColors.textPrimaryLight,
        ),
      );
    }

    final segments = _splitIntoSegments(message.text);
    final textColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        if (seg.isTable) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _TableWidget(rawTable: seg.content, isDark: isDark),
          );
        }
        final trimmed = seg.content.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 4);
        // Only animate the first text segment
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            trimmed,
            style:
                GoogleFonts.inter(fontSize: 14, height: 1.6, color: textColor),
          ),
        );
      }).toList(),
    );
  }

  List<_TextSegment> _splitIntoSegments(String text) {
    final lines = text.split('\n');
    final segments = <_TextSegment>[];
    final buffer = <String>[];
    bool inTable = false;

    for (final line in lines) {
      final isTableLine =
          line.trim().startsWith('|') && line.trim().endsWith('|');
      if (isTableLine && !inTable) {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.join('\n'), isTable: false));
          buffer.clear();
        }
        inTable = true;
        buffer.add(line);
      } else if (!isTableLine && inTable) {
        segments.add(_TextSegment(buffer.join('\n'), isTable: true));
        buffer.clear();
        inTable = false;
        buffer.add(line);
      } else {
        buffer.add(line);
      }
    }
    if (buffer.isNotEmpty) {
      segments.add(_TextSegment(buffer.join('\n'), isTable: inTable));
    }
    return segments;
  }
}

class _TextSegment {
  final String content;
  final bool isTable;
  const _TextSegment(this.content, {required this.isTable});
}

// ══════════════════════════════════════════════════════════════════════════════
//  Table widget — renders pipe-table syntax as a real Flutter Table
// ══════════════════════════════════════════════════════════════════════════════
class _TableWidget extends StatelessWidget {
  final String rawTable;
  final bool isDark;
  const _TableWidget({required this.rawTable, required this.isDark});

  List<List<String>> _parse() {
    final rows = <List<String>>[];
    for (final line in rawTable.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'^\|[\s\-|:]+\|$').hasMatch(trimmed)) continue;
      final cells = trimmed
          .split('|')
          .where((c) => c.isNotEmpty)
          .map((c) => c.trim())
          .toList();
      if (cells.isNotEmpty) rows.add(cells);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _parse();
    if (rows.isEmpty) return const SizedBox.shrink();

    final headerRow = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];
    final colCount = headerRow.length;

    final headerBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);
    final evenBg = isDark ? const Color(0xFF0F2540) : const Color(0xFFF9FAFB);
    final borderCol =
        isDark ? const Color(0xFF1E4976) : const Color(0xFFE5E7EB);
    final headerTxt =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
    final bodyTxt = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderCol),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: borderCol, width: 0.8),
              verticalInside: BorderSide(color: borderCol, width: 0.8),
            ),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: headerBg),
                children: List.generate(colCount, (i) {
                  final cell = i < headerRow.length ? headerRow[i] : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text(
                      cell,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: headerTxt,
                      ),
                    ),
                  );
                }),
              ),
              // Data rows
              ...List.generate(dataRows.length, (rowIdx) {
                final row = dataRows[rowIdx];
                return TableRow(
                  decoration:
                      BoxDecoration(color: rowIdx.isEven ? evenBg : null),
                  children: List.generate(colCount, (colIdx) {
                    final cell = colIdx < row.length ? row[colIdx] : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: Text(
                        cell,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: bodyTxt,
                        ),
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Typewriter text — animates AI response character by character
// ══════════════════════════════════════════════════════════════════════════════
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _animate();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (widget.text != old.text && _charIndex < widget.text.length) {
      _animate();
    }
  }

  void _animate() {
    Future.doWhile(() async {
      if (!mounted || _charIndex >= widget.text.length) {
        return false;
      }

      // Advance word-by-word
      int nextIndex = _charIndex + 1;
      while (nextIndex < widget.text.length &&
          widget.text[nextIndex - 1] != ' ' &&
          widget.text[nextIndex - 1] != '\n') {
        nextIndex++;
      }

      final wordLength = nextIndex - _charIndex;
      // Base 20ms per char, slower after punctuation for natural pacing
      final lastChar = _charIndex > 0 ? widget.text[_charIndex - 1] : '';
      final pauseMs = (lastChar == '.' || lastChar == '!' || lastChar == '?')
          ? 220
          : (lastChar == ',') ? 120 : 20 + wordLength * 4;

      await Future.delayed(Duration(milliseconds: pauseMs));
      if (!mounted) return false;

      setState(() {
        _charIndex = nextIndex;
        _displayed = widget.text.substring(0, _charIndex);
      });
      return _charIndex < widget.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Typing indicator
// ══════════════════════════════════════════════════════════════════════════════
class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600));
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
            color: widget.isDark
                ? const Color(0xFF1E4976)
                : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Pulsing AI avatar in header
// ══════════════════════════════════════════════════════════════════════════════
class _PulsingAvatar extends StatefulWidget {
  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.gradientPrimary,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 22),
      ),
    );
  }
}
