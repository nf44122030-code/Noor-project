import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// Wraps the `speech_to_text` package for continuous live transcription.
/// On Flutter Web, this uses the browser's Web Speech API internally.
class LiveTranscriptionService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isListening = false;
  static bool _isInitialized = false;
  static Function(String)? _onTranscript;
  static Function(String)? _onError;
  static String _locale = 'en-US';

  static bool get isListening => _isListening;

  /// Initialize the speech recognition engine.
  static Future<bool> initialize({String locale = 'en-US'}) async {
    if (_isInitialized) return true;
    _locale = locale;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('LiveTranscription error: ${error.errorMsg}');
          // Auto-restart on transient errors (not-allowed and aborted are fatal)
          if (_isListening &&
              error.errorMsg != 'error_not_allowed' &&
              error.errorMsg != 'error_permission') {
            Future.delayed(const Duration(seconds: 1), _restartListening);
          } else if (error.errorMsg == 'error_not_allowed' ||
              error.errorMsg == 'error_permission') {
            _onError?.call('Microphone permission denied for transcription');
            _isListening = false;
          }
        },
        onStatus: (status) {
          debugPrint('LiveTranscription status: $status');
          // Auto-restart when the browser stops listening (e.g. silence timeout)
          if (status == 'done' && _isListening) {
            Future.delayed(const Duration(milliseconds: 300), _restartListening);
          }
        },
      );
      debugPrint('LiveTranscription initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('LiveTranscription init failed: $e');
      _onError?.call('Speech recognition not available: $e');
      return false;
    }
  }

  /// Start continuous listening. [onResult] is called with each final transcript.
  static Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
    String? locale,
  }) async {
    if (locale != null) _locale = locale;
    _onTranscript = onResult;
    _onError = onError;

    if (!_isInitialized) {
      final ok = await initialize(locale: _locale);
      if (!ok) {
        _onError?.call('Could not initialize speech recognition');
        return;
      }
    }

    _isListening = true;
    _startListeningInternal();
  }

  static void _startListeningInternal() {
    if (!_isListening || !_isInitialized) return;
    if (_speech.isListening) return; // already running

    try {
      _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            debugPrint('Transcript: ${result.recognizedWords}');
            _onTranscript?.call(result.recognizedWords);
          }
        },
        localeId: _locale,
        listenMode: stt.ListenMode.dictation, // continuous mode
        cancelOnError: false,
        partialResults: false,
      );
    } catch (e) {
      debugPrint('LiveTranscription listen error: $e');
      // Try restarting after a delay
      if (_isListening) {
        Future.delayed(const Duration(seconds: 2), _restartListening);
      }
    }
  }

  static void _restartListening() {
    if (!_isListening) return;
    debugPrint('LiveTranscription: auto-restarting...');
    _startListeningInternal();
  }

  /// Stop listening and clean up.
  static Future<void> stopListening() async {
    _isListening = false;
    _onTranscript = null;
    _onError = null;
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('LiveTranscription stop error: $e');
    }
  }

  /// Check if speech recognition is available on this device/browser.
  static Future<bool> isAvailable() async {
    if (_isInitialized) return true;
    return initialize();
  }
}
