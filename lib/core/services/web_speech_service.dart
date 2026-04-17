/// Conditional export: uses stub on mobile, real JS interop on web.
export 'web_speech_service_stub.dart'
    if (dart.library.html) 'web_speech_service_web.dart';
