import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../../core/services/agora_service.dart';
import '../../../../core/services/vertex_ai_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/permissions_helper.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notes_controller.dart';
import '../widgets/camera_permission_dialog.dart';

class VideoSessionPage extends StatefulWidget {
  final String? expertName;
  final String? expertTitle;
  final String? initialCode;

  const VideoSessionPage({
    super.key,
    this.expertName,
    this.expertTitle,
    this.initialCode,
  });

  @override
  State<VideoSessionPage> createState() => _VideoSessionPageState();
}

class _VideoSessionPageState extends State<VideoSessionPage> with SingleTickerProviderStateMixin {
  String _sessionState = 'code-entry'; // code-entry, connecting, active
  final List<TextEditingController> _codeControllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _showChat = false;
  bool _showNotes = false;
  bool _isAgoraInitialized = false;
  bool _isTranscribing = false;
  String? _agoraError;
  final List<String> _transcriptLines = [];
  int? _remoteUid;
  String _channelId = '';

  int _sessionTime = 0;
  Timer? _timer;
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;
  late AnimationController _pulseController;
  final List<Map<String, dynamic>> _aiChatMessages = [];

  late final String _expertName;
  late final String _expertTitle;
  
  final notesController = Get.find<NotesController>();
  final themeController = Get.find<ThemeController>();
  
  final _aiChatController = TextEditingController();
  bool _isAiResponding = false;

  @override
  void initState() {
    super.initState();
    _expertName = widget.expertName ?? 'Expert Session';
    _expertTitle = widget.expertTitle ?? 'Consultation';

    // Temporarily bypass session code logic for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToSession(channelId: 'demo_channel', isClient: false);
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    AgoraService.onRemoteUserJoined = (uid) {
      if (mounted) setState(() => _remoteUid = uid);
    };
    AgoraService.onRemoteUserOffline = (uid) {
      if (mounted && _remoteUid == uid) setState(() => _remoteUid = null);
    };
    AgoraService.onAgoraError = (msg) {
      if (mounted) setState(() => _agoraError = msg);
    };
    AgoraService.onTranscriptUpdate = (text) {
      if (mounted) {
        setState(() {
          _transcriptLines.add('[${_formatTime(_sessionTime)}] $text');
          // Keep max 50 lines
          if (_transcriptLines.length > 50) _transcriptLines.removeAt(0);
        });
        // Feed to notes controller
        notesController.simulateAINoteGeneration('You', text);
      }
    };
    
    _checkPermissionsOnLoad();
  }

  Future<void> _checkPermissionsOnLoad() async {
    final hasPermissions = await PermissionsHelper.hasVideoCallPermissions();
    if (!hasPermissions && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                   const Icon(Icons.info_outline, color: Colors.white, size: 20),
                   const SizedBox(width: 12),
                  Expanded(
                    child: Text('camera_mic_needed'.tr),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF5B9FF3),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    _pulseController.dispose();
    _aiChatController.dispose();
    AgoraService.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join('');
    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('enter_5_digit_code'.tr), backgroundColor: Colors.red));
      return;
    }

    setState(() => _sessionState = 'connecting');

    try {
      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('session_code', isEqualTo: code)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        setState(() => _sessionState = 'code-entry');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_session_code'.tr), backgroundColor: Colors.red));
        return;
      }

      final doc = query.docs.first;
      final bookingId = doc.id;
      final isClient = doc.data()['user_id'] == await FirebaseService().getEffectiveUid();
      final hasPermissions = kIsWeb || await PermissionsHelper.hasVideoCallPermissions();
      
      if (!hasPermissions && mounted) {
        await showCameraPermissionDialog(
          context: context,
          onAllow: () async {
            final granted = await PermissionsHelper.requestVideoCallPermissions(context);
            if (granted) _connectToSession(channelId: bookingId, isClient: isClient);
          },
          onDemoMode: () => _connectToSession(channelId: bookingId, isDemo: true, isClient: isClient),
          onCancel: () => setState(() => _sessionState = 'code-entry'),
        );
      } else {
        _connectToSession(channelId: bookingId, isClient: isClient);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sessionState = 'code-entry');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification error: $e'), backgroundColor: Colors.red));
    }
  }

  void _connectToSession({required String channelId, bool isDemo = false, bool isClient = false}) async {
    if (isClient) {
      FirebaseService().initiateCall(channelId).catchError((e) => debugPrint('Error ringing expert: $e'));
    }

    try {
      // 1. Initialize Agora instantly to turn on the local camera
      try {
        await AgoraService.initialize();
      } catch(e) {
        if (mounted) setState(() => _agoraError = 'Init Exception: $e');
      }

      if (!mounted) return;
      setState(() {
        _isAgoraInitialized = true;
        _sessionState = 'active';
        _channelId = channelId;
      });

      // 2. Join the channel (can take a second to resolve)
      await AgoraService.joinChannel(channelId, 0);
      
      if (mounted) {
        setState(() {
          _showChat = true;
        });
        _startTimer();

        // 3. Start Agora Real-Time STT cloud agent
        try {
          await AgoraService.startSttAgent(channelId);
          if (mounted) setState(() => _isTranscribing = true);
        } catch (e) {
          debugPrint('STT agent start failed: $e');
        }

        setState(() {
          _aiChatMessages.add({
            'message': '👋 Hi! I\'m your Intellix Assistant. I can help take notes or answer questions while you talk to $_expertName.',
            'timestamp': _formatTime(0),
            'isAI': true,
          });
        });

        // 3. Listen to the booking document for disconnects
        _bookingSubscription = FirebaseFirestore.instance
            .collection('bookings')
            .doc(channelId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final status = snapshot.data()!['status'];
            if (status == 'completed' || status == 'cancelled') {
              if (mounted && _sessionState == 'active') {
                _forceEndSessionFromRemote();
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _sessionState = 'code-entry');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _sessionTime++);
    });
  }

  Future<void> _sendAiMessage() async {
    final text = _aiChatController.text.trim();
    if (text.isEmpty || _isAiResponding) return;

    setState(() {
      _aiChatMessages.add({
        'message': text,
        'timestamp': _formatTime(_sessionTime),
        'isAI': false,
      });
      _aiChatController.clear();
      _isAiResponding = true;
    });

    try {
      final contextPrompt = 'The user is current in a video call with $_expertName ($_expertTitle). Help them take notes or answer their questions.';
      final history = _aiChatMessages.map((m) => {
        'role': m['isAI'] == true ? 'assistant' : 'user',
        'content': m['message'] as String,
      }).toList();
      history.insert(0, {'role': 'system', 'content': contextPrompt});

      final response = await VertexAiService.getMultimodalCompletion(history);
      if (mounted) {
        setState(() {
          _aiChatMessages.add({
            'message': response ?? 'I couldn\'t process that right now.',
            'timestamp': _formatTime(_sessionTime),
            'isAI': true,
          });
          _isAiResponding = false;
        });
        AgoraService.addTranscriptSnippet('AI Agent: $response');
      }
    } catch (e) {
      if (mounted) setState(() => _isAiResponding = false);
    }
  }

  void _toggleAINotes() {
    final isRecording = notesController.isRecording.value;
    if (!isRecording) {
      notesController.startRecording();
      setState(() => _showNotes = true);
    } else {
      notesController.stopRecording();
      setState(() => _showNotes = false);
    }
  }

  Future<void> _endSession() async {
    setState(() => _sessionState = 'connecting'); 
    try {
      if (_channelId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('bookings').doc(_channelId).update({'status': 'completed'});
      }
      AgoraService.addTranscriptSnippet('Session ended after ${_formatTime(_sessionTime)} with $_expertName.');
      final aiNotes = await AgoraService.generateSessionNotes();
      await AgoraService.leaveChannel();
      if (mounted && aiNotes != null) {
        final savedSession = await notesController.saveSession(
          expertName: _expertName,
          expertTitle: _expertTitle,
          duration: _sessionTime,
          aiContent: aiNotes,
        );
        if (mounted) context.go('/session-notes/${savedSession.id}');
      } else if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) context.pop();
    }
  }

  Future<void> _forceEndSessionFromRemote() async {
    setState(() => _sessionState = 'connecting'); 
    try {
      AgoraService.addTranscriptSnippet('Session was ended by the other participant.');
      final aiNotes = await AgoraService.generateSessionNotes();
      await AgoraService.leaveChannel();
      if (mounted && aiNotes != null) {
         final savedSession = await notesController.saveSession(
          expertName: _expertName,
          expertTitle: _expertTitle,
          duration: _sessionTime,
          aiContent: aiNotes,
        );
        if (mounted) context.go('/session-notes/${savedSession.id}');
      } else if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) context.pop();
    }
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode;
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: Container(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          child: _buildCurrentView(isDark),
        ),
      );
    });
  }

  Widget _buildCurrentView(bool isDark) {
    switch (_sessionState) {
      case 'code-entry': return _buildCodeEntryView(isDark);
      case 'connecting': return _buildConnectingView();
      case 'active': return _buildActiveSessionView();
      default: return Container();
    }
  }

  Widget _buildCodeEntryView(bool isDark) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.gradientAppBar,
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Color(0x220EA5E9),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 60, bottom: 80, left: 24, right: 24),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
              const Expanded(child: Center(child: Text('MY SESSIONS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)))),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, 
              borderRadius: BorderRadius.circular(24), 
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              boxShadow: isDark ? [] : AppColors.cardShadow(),
            ),
            child: Column(
              children: [
                Text('Enter Session Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C3E50))),
                const SizedBox(height: 8),
                Text('Enter the 5-digit code sent to your email', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : const Color(0xFF7F8C8D))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: List.generate(5, (i) => SizedBox(
                    width: 54, 
                    height: 64, 
                    child: TextField(
                      controller: _codeControllers[i], 
                      focusNode: _focusNodes[i], 
                      textAlign: TextAlign.center, 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black
                      ), 
                      keyboardType: TextInputType.number, 
                      maxLength: 1, 
                      decoration: InputDecoration(
                        counterText: '', 
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), 
                          borderSide: isDark ? BorderSide.none : const BorderSide(color: Color(0xFFE5E7EB))
                        ), 
                        filled: true, 
                        fillColor: isDark ? AppColors.surfaceDim : const Color(0xFFF9FAFB)
                      ), 
                      onChanged: (v) { 
                        if (v.isNotEmpty && i < 4) _focusNodes[i + 1].requestFocus(); 
                        if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus(); 
                      }
                    )
                  ))
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verifyCode, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Join Video Session', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 120, height: 120, child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF5B9FF3).withValues(alpha: 0.5)))),
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF5B9FF3), child: Icon(Icons.video_call, color: Colors.white, size: 40)),
          ]),
          const SizedBox(height: 32),
          const Text('Securing Connection...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 8),
          const Text('Setting up encrypted video stream', style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D))),
        ],
      ),
    );
  }

  Widget _buildActiveSessionView() {
    return Obx(() {
      final isNotesRecording = notesController.isRecording.value;
      return Column(
        children: [
          if (_agoraError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.redAccent,
              child: Text(
                'Video Error: $_agoraError',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.black87,
                  child: Stack(
                    children: [
                      // ── Main video area (remote feed or waiting state) ──
                      if (!_isVideoOn)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
                                child: const Icon(Icons.person, color: Colors.white, size: 60),
                              ),
                              const SizedBox(height: 16),
                              const Text('Camera Off', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      else
                        SizedBox.expand(
                          child: _remoteUid != null
                              ? AgoraVideoView(
                                  controller: VideoViewController.remote(
                                    rtcEngine: AgoraService.engine,
                                    canvas: VideoCanvas(
                                      uid: _remoteUid,
                                      renderMode: RenderModeType.renderModeHidden,
                                    ),
                                    connection: RtcConnection(channelId: _channelId),
                                  ),
                                )
                              // ── Waiting for expert placeholder ──
                              : Container(
                                  color: const Color(0xFF0A1929),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 120, height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Colors.blue.shade700, Colors.cyan.shade400],
                                            ),
                                          ),
                                          child: const Icon(Icons.person, color: Colors.white, size: 64),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          _expertName,
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _expertTitle,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: 28, height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.cyan.shade400,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Waiting for expert to join...',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),

                      // ── Local camera preview (top-right) ──
                      Positioned(
                        right: 16, top: 40,
                        child: Container(
                          width: 100, height: 140,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: _isVideoOn && _isAgoraInitialized
                              ? AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: AgoraService.engine,
                                    canvas: const VideoCanvas(
                                      uid: 0,
                                      renderMode: RenderModeType.renderModeHidden,
                                    ),
                                  ),
                                )
                              : Container(color: Colors.grey[900], child: const Icon(Icons.videocam_off, color: Colors.white54)),
                        ),
                      ),

                      // ── Timer badge (top-left) ──
                      Positioned(
                        top: 40, left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(_formatTime(_sessionTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),

                      // ── Transcript overlay (bottom of video) ──
                      if (_isTranscribing)
                        Positioned(
                          bottom: 8, left: 8, right: 8,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.hearing, color: Colors.cyanAccent, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Live Transcript',
                                      style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Flexible(
                                  child: _transcriptLines.isEmpty
                                    ? Text(
                                        'Listening... speak to start transcribing',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontStyle: FontStyle.italic),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        reverse: true,
                                        itemCount: _transcriptLines.length,
                                        itemBuilder: (_, i) {
                                          final idx = _transcriptLines.length - 1 - i;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 3),
                                            child: Text(
                                              _transcriptLines[idx],
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: i == 0 ? 1.0 : 0.6),
                                                fontSize: 12,
                                                fontWeight: i == 0 ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_showChat) Positioned(right: 0, top: 0, bottom: 0, width: MediaQuery.of(context).size.width * 0.85, child: _buildAIChatPanel()),
                if (_showNotes && isNotesRecording) Positioned(right: 0, top: 0, bottom: 0, width: MediaQuery.of(context).size.width * 0.8, child: _buildNotesPanel()),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(icon: _isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : const Color(0xFF2C3E50), onPressed: () {
                  setState(() => _isMuted = !_isMuted);
                  AgoraService.toggleMuteAudio(_isMuted);
                }),
                _buildControlButton(icon: _isVideoOn ? Icons.videocam : Icons.videocam_off, color: !_isVideoOn ? Colors.red : const Color(0xFF2C3E50), onPressed: () {
                  setState(() => _isVideoOn = !_isVideoOn);
                  AgoraService.toggleMuteVideo(!_isVideoOn);
                }),
                _buildControlButton(icon: Icons.call_end, color: Colors.red, size: 56, onPressed: _endSession),
                _buildControlButton(icon: isNotesRecording ? (_showNotes ? Icons.note : Icons.note_add) : Icons.note_outlined, color: isNotesRecording ? Colors.amber : const Color(0xFF2C3E50), onPressed: _toggleAINotes, showBadge: isNotesRecording),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAIChatPanel() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(-5, 0))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF5B9FF3), Color(0xFF7DB6F7)]),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Interactive Help',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showChat = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _aiChatMessages.length,
              itemBuilder: (context, index) {
                final message = _aiChatMessages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 32, height: 32, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5B9FF3), Color(0xFF7DB6F7)]), shape: BoxShape.circle), child: const Icon(Icons.smart_toy, color: Colors.white, size: 16)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(message['isAI'] == true ? 'AI Agent' : 'You', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: message['isAI'] == true ? const Color(0xFFF0F7FF) : const Color(0xFF5B9FF3).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text(message['message'] as String, style: const TextStyle(fontSize: 14))),
                      ])),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isAiResponding) const Padding(padding: EdgeInsets.all(8), child: Text('AI is thinking...', style: TextStyle(fontSize: 12, color: Colors.blue))),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[200]!)),
            child: Row(children: [Expanded(child: TextField(controller: _aiChatController, decoration: const InputDecoration(hintText: 'Ask or take a note...'), onSubmitted: (_) => _sendAiMessage())), IconButton(icon: const Icon(Icons.send, color: Color(0xFF5B9FF3)), onPressed: _sendAiMessage)]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesPanel() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(-5, 0))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFFB74D)])),
            child: Row(children: [const Icon(Icons.auto_awesome, color: Colors.white, size: 24), const SizedBox(width: 12), const Expanded(child: Text('AI Session Notes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _showNotes = false))]),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notesController.currentSessionNotes.length,
              itemBuilder: (context, index) {
                final note = notesController.currentSessionNotes[index];
                return ListTile(title: Text(note.speaker), subtitle: Text(note.content));
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onPressed, double size = 48, bool showBadge = false}) {
    return Stack(children: [Container(width: size, height: size, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: IconButton(icon: Icon(icon, color: color, size: size * 0.5), onPressed: onPressed)), if (showBadge) Positioned(right: 0, top: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))))]);
  }
}
