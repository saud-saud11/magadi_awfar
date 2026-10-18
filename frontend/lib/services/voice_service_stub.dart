class VoiceRecognitionService {
  static bool get isSupported => false;

  static bool startListening({
    required void Function() onStart,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
    required void Function(String finalTranscript) onEnd,
  }) {
    onError('not_supported');
    return false;
  }

  static void stopListening() {}
}
