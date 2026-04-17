import 'package:flutter/foundation.dart';
import 'web_speech_service.dart';

/// Wraps WebSpeechService for live transcription during video calls.
/// Uses the browser's native SpeechRecognition API via JS interop.
class LiveTranscriptionService {
  static bool get isListening => WebSpeechService.isListening;

  /// Start continuous listening. [onResult] fires with each transcribed sentence.
  static Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
    String? locale,
  }) async {
    if (!WebSpeechService.isSupported) {
      debugPrint('LiveTranscription: Speech recognition not supported');
      onError?.call('Speech recognition not supported in this browser');
      return;
    }

    WebSpeechService.start(
      onResult: onResult,
      onError: onError,
      lang: locale ?? 'en-US',
    );
    debugPrint('LiveTranscription: started with locale ${locale ?? "en-US"}');
  }

  /// Stop listening.
  static Future<void> stopListening() async {
    WebSpeechService.stop();
    debugPrint('LiveTranscription: stopped');
  }
}
