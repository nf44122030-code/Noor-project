import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vertex_ai_service.dart';

class AgoraService {
  static const String appId = "c1e946d412a4440c8fa0d51e481544c6"; 
  
  static RtcEngine? _engine;
  static final List<String> _transcriptBuffer = [];

  static Future<void> initialize() async {
    if (_engine != null) return;

    await [Permission.microphone, Permission.camera].request();

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
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Agora: User offline $remoteUid");
        },
        // In a real production app, we would use Agora's Speech-to-Text (STT) 
        // extensions to populate the transcriptBuffer in real-time.
      ),
    );
  }

  static Future<void> joinChannel(String channelId, int uid) async {
    await _engine?.joinChannel(
      token: "", // In production, generate this on your backend
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  static Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
    _transcriptBuffer.clear();
  }

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
