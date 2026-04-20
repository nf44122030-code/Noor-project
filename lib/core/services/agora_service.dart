import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vertex_ai_service.dart';

class AgoraService {
  static const String appId = "c1e946d412a4440c8fa0d51e481544c6"; 
  static const int _pubBotUid = 88222; // STT agent publisher UID
  
  static RtcEngine? _engine;
  static final List<String> _transcriptBuffer = [];
  static String? _sttAgentId;
  
  static Function(int)? onRemoteUserJoined;
  static Function(int)? onRemoteUserOffline;
  static Function(String)? onAgoraError;
  static Function(String)? onTranscriptUpdate;       // final transcript line
  static Function(String)? onPartialTranscript;      // live partial (typing) text

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
          // Don't show STT bot as a remote user in the UI
          if (remoteUid != _pubBotUid && remoteUid != 47091) {
            if (onRemoteUserJoined != null) onRemoteUserJoined!(remoteUid);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Agora: User offline $remoteUid");
          if (remoteUid != _pubBotUid && remoteUid != 47091) {
            if (onRemoteUserOffline != null) onRemoteUserOffline!(remoteUid);
          }
        },
        // Fires when a user's video becomes available — catches users ALREADY in the channel
        // NOTE: We only call onRemoteUserJoined here. We do NOT call onRemoteUserOffline
        // for Stopped/Failed because those states fire transiently during connection setup
        // and would race with onUserJoined, hiding the remote feed. Only onUserOffline
        // (actual disconnection) should clear the remote view.
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          debugPrint("📹 Agora onRemoteVideoStateChanged: uid=$remoteUid state=$state");
          if (remoteUid == _pubBotUid || remoteUid == 47091) return;
          if (state == RemoteVideoState.remoteVideoStateDecoding || state == RemoteVideoState.remoteVideoStateStarting) {
            if (onRemoteUserJoined != null) onRemoteUserJoined!(remoteUid);
          }
          // Do NOT clear remoteUid on Stopped/Failed — onUserOffline handles true disconnection
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error $err: $msg");
          if (onAgoraError != null) onAgoraError!('Agora System Error: $err - $msg');
        },
        // ─── Receive STT transcription data from the pubBot ───
        onStreamMessage: (RtcConnection connection, int remoteUid, int streamId, Uint8List data, int length, int sentTs) {
          debugPrint("Agora: Received stream message from $remoteUid (streamId: $streamId), data length: $length");
          _handleSttData(data);
        },
        onStreamMessageError: (RtcConnection connection, int remoteUid, int streamId, ErrorCodeType code, int missed, int cached) {
          debugPrint("Agora: Stream message error from $remoteUid: $code");
        },
      ),
    );
  }

  static Future<void> joinChannel(String channelId, int uid) async {
    debugPrint('🔑 AgoraService.joinChannel — channelId="$channelId" uid=$uid');
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
    await stopSttAgent();
    await _engine?.leaveChannel();
    _transcriptBuffer.clear();
  }

  static Future<void> dispose() async {
    await stopSttAgent();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    onRemoteUserJoined = null;
    onRemoteUserOffline = null;
    onTranscriptUpdate = null;
    onPartialTranscript = null;
  }

  // ─── Agora Real-Time STT (Cloud Service) ──────────────────

  /// Start the Agora Real-Time STT cloud agent for a channel.
  static Future<void> startSttAgent(String channelName) async {
    try {
      final url = Uri.parse('https://noor-project-nine.vercel.app/api/agora/stt');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'start', 'channelName': channelName}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sttAgentId = data['agentId'];
        debugPrint('STT Agent started: $_sttAgentId');
      } else if (response.statusCode == 409) {
        // 409 = Conflict: an STT agent is already running for this channel.
        // This happens when both participants call startSttAgent. Treat as success.
        debugPrint('STT Agent already running for this channel (409) — OK, continuing.');
        // We don't have the existing agentId, so we won't be able to stop it
        // explicitly; it will auto-expire via maxIdleTime.
      } else {
        debugPrint('STT start failed: ${response.body}');
        if (onAgoraError != null) onAgoraError!('STT start failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('STT start error: $e');
      if (onAgoraError != null) onAgoraError!('STT start error: $e');
    }
  }

  /// Stop the Agora Real-Time STT cloud agent.
  static Future<void> stopSttAgent() async {
    if (_sttAgentId == null) return;
    try {
      final url = Uri.parse('https://noor-project-nine.vercel.app/api/agora/stt');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'stop', 'agentId': _sttAgentId}),
      ).timeout(const Duration(seconds: 5));
      debugPrint('STT Agent stopped: $_sttAgentId');
      _sttAgentId = null;
    } catch (e) {
      debugPrint('STT stop error: $e');
      _sttAgentId = null;
    }
  }

  static bool get isTranscribing => _sttAgentId != null;

  /// Parse protobuf STT data from the onStreamMessage callback.
  /// Agora sends the Text protobuf message. We extract the words field.
  static void _handleSttData(Uint8List data) {
    try {
      final result = _parseProtobufText(data);
      if (result != null && result['text'] != null && (result['text'] as String).trim().isNotEmpty) {
        final text = (result['text'] as String).trim();
        final isFinal = result['isFinal'] as bool;
        final uid = result['uid'] as int;

        if (isFinal) {
          // Determine speaker label
          final speaker = uid == 0 ? 'You' : 'Speaker $uid';
          final entry = '[$speaker]: $text';
          _transcriptBuffer.add(entry);
          debugPrint('STT Final: $entry');
          if (onTranscriptUpdate != null) onTranscriptUpdate!(text);
          // Clear the partial line after final
          if (onPartialTranscript != null) onPartialTranscript!('');
        } else {
          // Emit partial result for real-time typing effect
          if (onPartialTranscript != null) onPartialTranscript!(text);
        }
      }
    } catch (e) {
      debugPrint('STT parse error: $e');
    }
  }

  /// Minimal protobuf Text message parser (proto3 wire format).
  /// Extracts: uid (field 4), words.text (field 10 -> sub field 1),
  /// words.is_final (field 10 -> sub field 4)
  static Map<String, dynamic>? _parseProtobufText(Uint8List data) {
    int pos = 0;
    int uid = 0;
    String fullText = '';
    bool isFinal = false;

    while (pos < data.length) {
      if (pos >= data.length) break;
      // Read field tag (varint)
      final tagResult = _readVarint(data, pos);
      if (tagResult == null) break;
      final tag = tagResult.value;
      pos = tagResult.nextPos;

      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      if (wireType == 0) {
        // Varint
        final varint = _readVarint(data, pos);
        if (varint == null) break;
        pos = varint.nextPos;
        if (fieldNumber == 4) uid = varint.value; // uid field
      } else if (wireType == 2) {
        // Length-delimited
        final lenResult = _readVarint(data, pos);
        if (lenResult == null) break;
        final len = lenResult.value;
        pos = lenResult.nextPos;
        
        if (pos + len > data.length) break;
        final subData = data.sublist(pos, pos + len);

        if (fieldNumber == 10) {
          // Word message — parse sub-fields
          final word = _parseWord(Uint8List.fromList(subData));
          if (word != null) {
            if (fullText.isNotEmpty) fullText += ' ';
            fullText += word['text'] ?? '';
            if (word['isFinal'] == true) isFinal = true;
          }
        } else if (fieldNumber == 13) {
          // data_type string — skip, not needed
        } else if (fieldNumber == 15) {
          // culture string — skip
        }

        pos += len;
      } else if (wireType == 5) {
        // 32-bit fixed
        pos += 4;
      } else if (wireType == 1) {
        // 64-bit fixed
        pos += 8;
      } else {
        break; // unknown wire type
      }
    }

    if (fullText.isEmpty) return null;
    return {'text': fullText, 'isFinal': isFinal, 'uid': uid};
  }

  /// Parse a Word sub-message: text (field 1), is_final (field 4)
  static Map<String, dynamic>? _parseWord(Uint8List data) {
    int pos = 0;
    String text = '';
    bool isFinal = false;

    while (pos < data.length) {
      final tagResult = _readVarint(data, pos);
      if (tagResult == null) break;
      final tag = tagResult.value;
      pos = tagResult.nextPos;

      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      if (wireType == 0) {
        final varint = _readVarint(data, pos);
        if (varint == null) break;
        pos = varint.nextPos;
        if (fieldNumber == 4) isFinal = varint.value != 0;
      } else if (wireType == 2) {
        final lenResult = _readVarint(data, pos);
        if (lenResult == null) break;
        final len = lenResult.value;
        pos = lenResult.nextPos;
        if (pos + len > data.length) break;

        if (fieldNumber == 1) {
          text = utf8.decode(data.sublist(pos, pos + len));
        }
        pos += len;
      } else if (wireType == 5) {
        pos += 4;
      } else if (wireType == 1) {
        pos += 8;
      } else {
        break;
      }
    }

    return {'text': text, 'isFinal': isFinal};
  }

  /// Read a varint from the data at the given position.
  static _VarintResult? _readVarint(Uint8List data, int pos) {
    int result = 0;
    int shift = 0;
    while (pos < data.length) {
      final byte = data[pos];
      result |= (byte & 0x7F) << shift;
      pos++;
      if ((byte & 0x80) == 0) {
        return _VarintResult(result, pos);
      }
      shift += 7;
      if (shift > 35) return null; // too many bytes for a 32-bit varint
    }
    return null;
  }

  /// Adds a snippet to the live transcript
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

class _VarintResult {
  final int value;
  final int nextPos;
  _VarintResult(this.value, this.nextPos);
}
