import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'live_transcription_service.dart';
import 'vertex_ai_service.dart';

class AgoraService {
  static const String appId = "c1e946d412a4440c8fa0d51e481544c6"; 
  
  static RtcEngine? _engine;
  static final List<String> _transcriptBuffer = [];
  
  static Function(int)? onRemoteUserJoined;
  static Function(int)? onRemoteUserOffline;
  static Function(String)? onAgoraError;
  static Function(String)? onTranscriptUpdate;

  static Future<void> initialize() async {
    if (_engine != null) return;
    if (!kIsWeb) {
      await [Permission.microphone, Permission.camera].request();
    }
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine!.enableVideo();
    await _engine!.startPreview();

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Agora: Joined channel ${connection.channelId}");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Agora: User joined $remoteUid");
          if (onRemoteUserJoined != null) onRemoteUserJoined!(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Agora: User offline $remoteUid");
          if (onRemoteUserOffline != null) onRemoteUserOffline!(remoteUid);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error $err: $msg");
          if (onAgoraError != null) onAgoraError!('Agora System Error: $err - $msg');
        },
      ),
    );
  }

  static Future<void> joinChannel(String channelId, int uid) async {
    const options = ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
      publishMicrophoneTrack: true,
      publishCameraTrack: true,
      autoSubscribeAudio: true,
      autoSubscribeVideo: true,
    );

    try {
      // Try fetching a token from the deployed backend
      final tokenUrl = Uri.parse('https://noor-project-nine.vercel.app/api/agora/token');
      final response = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'channelName': channelId, 'uid': uid}),
      ).timeout(const Duration(seconds: 5));

      String token = "";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'] ?? "";
      } else {
        debugPrint("Failed to fetch token (${response.statusCode}). Using empty token.");
      }

      await _engine?.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: options,
      );
    } catch (e) {
      debugPrint("Agora token error: $e — joining with empty token");
      if (onAgoraError != null) onAgoraError!('Token fetch failed: $e');
      // Fallback: join without a token (works in Agora Testing Mode)
      await _engine?.joinChannel(
        token: "",
        channelId: channelId,
        uid: uid,
        options: options,
      );
    }
  }

  static Future<void> toggleMuteAudio(bool isMuted) async {
    await _engine?.muteLocalAudioStream(isMuted);
  }

  static Future<void> toggleMuteVideo(bool isMuted) async {
    await _engine?.muteLocalVideoStream(isMuted);
  }

  static Future<void> leaveChannel() async {
    await stopLiveTranscription();
    await _engine?.leaveChannel();
    _transcriptBuffer.clear();
  }

  static Future<void> dispose() async {
    await stopLiveTranscription();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    onRemoteUserJoined = null;
    onRemoteUserOffline = null;
    onTranscriptUpdate = null;
  }

  // ─── Live Transcription ───────────────────────────────────

  /// Start live speech-to-text using the browser's Web Speech API.
  /// Transcribed text is added to the buffer and forwarded via [onTranscriptUpdate].
  static Future<void> startLiveTranscription({String locale = 'en-US'}) async {
    await LiveTranscriptionService.startListening(
      locale: locale,
      onResult: (String text) {
        final timestamped = '[You]: $text';
        _transcriptBuffer.add(timestamped);
        if (onTranscriptUpdate != null) onTranscriptUpdate!(text);
      },
      onError: (String error) {
        debugPrint('Transcription error: $error');
        if (onAgoraError != null) onAgoraError!('STT: $error');
      },
    );
    debugPrint('Live transcription started');
  }

  /// Stop live speech-to-text.
  static Future<void> stopLiveTranscription() async {
    await LiveTranscriptionService.stopListening();
    debugPrint('Live transcription stopped');
  }

  static bool get isTranscribing => LiveTranscriptionService.isListening;

  /// Adds a snippet to the live transcript (usually called by an STT listener)
  static void addTranscriptSnippet(String text) {
    _transcriptBuffer.add(text);
  }

  /// Uses Gemini to summarize the live session and generate notes.
  static Future<String?> generateSessionNotes() async {
    if (_transcriptBuffer.isEmpty) {
      return "No conversation data captured during the session.";
    }

    final transcript = _transcriptBuffer.join("\n");
    final prompt = '''
      You are the Intellix AI Meeting Assistant. 
      Below is a transcript of a business expert consultation. 
      Please provide:
      1. A summary of the key discussion points.
      2. Action items for the user.
      3. Strategic recommendations based on the conversation.

      TRANSCRIPT:
      $transcript
    ''';

    return await VertexAiService.getMultimodalCompletion([
      {'role': 'user', 'content': prompt}
    ]);
  }

  static RtcEngine get engine {
    if (_engine == null) throw Exception("Agora engine NOT initialized");
    return _engine!;
  }
}
