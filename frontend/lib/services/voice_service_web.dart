import 'dart:js_interop';

@JS('magadiIsVoiceSupported')
external bool _jsIsVoiceSupported();

@JS('magadiStartVoice')
external bool _jsStartVoice(
  JSFunction onStart,
  JSFunction onResult,
  JSFunction onError,
  JSFunction onEnd,
);

@JS('magadiStopVoice')
external void _jsStopVoice();

class VoiceRecognitionService {
  static bool get isSupported {
    try {
      return _jsIsVoiceSupported();
    } catch (_) {
      return false;
    }
  }

  static bool startListening({
    required void Function() onStart,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
    required void Function(String finalTranscript) onEnd,
  }) {
    try {
      final jsOnStart = (() {
        onStart();
      }).toJS;

      final jsOnResult = ((JSString text, JSBoolean isFinal) {
        onResult(text.toDart, isFinal.toDart);
      }).toJS;

      final jsOnError = ((JSString err) {
        onError(err.toDart);
      }).toJS;

      final jsOnEnd = ((JSString text) {
        onEnd(text.toDart);
      }).toJS;

      return _jsStartVoice(jsOnStart, jsOnResult, jsOnError, jsOnEnd);
    } catch (e) {
      onError(e.toString());
      return false;
    }
  }

  static void stopListening() {
    try {
      _jsStopVoice();
    } catch (_) {}
  }
}
