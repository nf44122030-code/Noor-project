import 'dart:js_interop';

/// Calls the JS function intellixStartSpeech(lang, callback) defined in index.html
@JS('intellixStartSpeech')
external JSBoolean _jsStartSpeech(JSString lang, JSFunction callback);

/// Calls the JS function intellixStopSpeech() defined in index.html
@JS('intellixStopSpeech')
external void _jsStopSpeech();

/// Calls the JS function intellixIsSpeechSupported() defined in index.html
@JS('intellixIsSpeechSupported')
external JSBoolean _jsIsSupported();

/// Web implementation of speech recognition using native browser APIs via JS interop.
class WebSpeechService {
  static bool _listening = false;
  static Function(String)? _onResult;
  static Function(String)? _onError;

  static bool get isListening => _listening;
  static bool get isSupported {
    try {
      return _jsIsSupported().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Start continuous speech recognition.
  /// [onResult] is called with each final transcript segment.
  /// [onError] is called if something goes wrong.
  static void start({
    required Function(String) onResult,
    Function(String)? onError,
    String lang = 'en-US',
  }) {
    _onResult = onResult;
    _onError = onError;

    // Create the JS callback that receives transcript strings
    void handleCallback(JSString text) {
      final str = text.toDart;
      if (str.startsWith('ERROR:')) {
        _onError?.call(str.substring(6));
      } else {
        _onResult?.call(str);
      }
    }

    try {
      _jsStartSpeech(lang.toJS, handleCallback.toJS);
      _listening = true;
    } catch (e) {
      _onError?.call('Failed to start speech: $e');
    }
  }

  /// Stop speech recognition.
  static void stop() {
    _listening = false;
    _onResult = null;
    _onError = null;
    try {
      _jsStopSpeech();
    } catch (_) {}
  }
}
