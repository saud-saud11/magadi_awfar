// Web Speech API Bridge for Magadi Awfar
(function() {
  var recognition = null;
  var isListening = false;
  var lastTranscript = '';
  var hasSpoken = false;

  function getSpeechRecognition() {
    return window.SpeechRecognition || 
           window.webkitSpeechRecognition || 
           window.mozSpeechRecognition || 
           window.msSpeechRecognition || null;
  }

  window.magadiIsVoiceSupported = function() {
    return !!getSpeechRecognition();
  };

  window.magadiStartVoice = function(onStart, onResult, onError, onEnd) {
    var SpeechRecognitionClass = getSpeechRecognition();
    if (!SpeechRecognitionClass) {
      if (onError) onError('not_supported');
      return false;
    }

    try {
      if (recognition) {
        try { recognition.abort(); } catch(e) {}
      }

      recognition = new SpeechRecognitionClass();
      recognition.lang = 'ar-SA';
      recognition.continuous = false;
      recognition.interimResults = true;
      recognition.maxAlternatives = 1;

      lastTranscript = '';
      hasSpoken = false;

      recognition.onstart = function() {
        isListening = true;
        if (onStart) onStart();
      };

      recognition.onresult = function(event) {
        var interim = '';
        var finalTranscript = '';
        for (var i = event.resultIndex; i < event.results.length; ++i) {
          var item = event.results[i];
          if (item.isFinal) {
            finalTranscript += item[0].transcript;
          } else {
            interim += item[0].transcript;
          }
        }
        var transcript = (finalTranscript || interim).trim();
        if (transcript.length > 0) {
          lastTranscript = transcript;
          hasSpoken = true;
          if (onResult) {
            onResult(transcript, finalTranscript.trim().length > 0);
          }
        }
      };

      recognition.onerror = function(event) {
        isListening = false;
        var err = event.error || 'unknown';
        if (onError) onError(err);
      };

      recognition.onend = function() {
        isListening = false;
        if (onEnd) {
          var finalResult = hasSpoken ? lastTranscript : '';
          onEnd(finalResult);
        }
      };

      recognition.start();
      return true;
    } catch(err) {
      isListening = false;
      if (onError) onError(err.toString());
      return false;
    }
  };

  window.magadiStopVoice = function() {
    if (recognition && isListening) {
      try {
        recognition.stop();
      } catch(e) {}
    }
    isListening = false;
  };
})();
