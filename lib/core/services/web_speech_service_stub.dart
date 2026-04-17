/// Stub implementation for non-web platforms (iOS, Android).
/// All methods are no-ops so the app compiles on mobile.
class WebSpeechService {
  static void start({
    required Function(String) onResult,
    Function(String)? onError,
    String lang = 'en-US',
  }) {
    onError?.call('Speech recognition is only available on web');
  }

  static void stop() {}

  static bool get isListening => false;
  static bool get isSupported => false;
}
