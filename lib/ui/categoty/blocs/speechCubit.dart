// lib/commons/blocs/speech_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';

class SpeechCubit extends Cubit<SpeechState> {
  final SpeechToText _speechToText = SpeechToText();
  String _currentLocaleId = '';
  bool _speechEnabled = false;
  SpeechCubit() : super(SpeechInitial());

  Future<void> initSpeech() async {
    try {
      if (!_speechEnabled)
        _speechEnabled = await _speechToText.initialize(
          onError: _onError,
        );

      if (_speechEnabled) {
        var systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }

      emit(SpeechReady(enabled: _speechEnabled));
    } catch (_) {
      emit(SpeechError(failedToStartSpeechRecognitionKey));
    }
  }

  void _onError(SpeechRecognitionError error) {
    String errorMessageKey = _mapErrorToMessageKey(error.errorMsg);
    emit(SpeechError(errorMessageKey));
  }

  String _mapErrorToMessageKey(String errorCode) {
    switch (errorCode) {
      case 'error_speech_timeout':
      case 'error_speech_timeout_msg':
        return speechRecognitionFailedTryAgainKey;
      case 'error_no_match':
      case 'error_no_match_msg':
        return noSpeechDetectedSpeakClearlyKey;
      case 'error_audio':
      case 'error_audio_error':
        return speechRecognitionFailureKey;
      case 'error_permission':
      case 'error_permission_denied':
        return speechPermissionsDeniedKey;
      case 'error_busy':
      case 'error_client':
        return failedToStartSpeechRecognitionKey;
      case 'error_network':
      case 'error_network_timeout':
        return speechRecognitionFailureKey;
      case 'error_not_available':
      case 'error_service_not_available':
        return speechRecognitionNotAvailableKey;
      case 'error_cancelled':
        return speechRecognitionCancelledKey;
      default:
        return speechRecognitionFailureKey;
    }
  }

  Future<void> startListening() async {
    if (!_speechToText.isAvailable) {
      await initSpeech();
    }
    emit(SpeechListening());

    await _speechToText.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: _currentLocaleId,
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    emit(SpeechResult(
      text: result.recognizedWords,
      isFinal: result.finalResult,
    ));
  }

  void stopListening() {
    _speechToText.stop();
    emit(SpeechStopped());
  }
}

abstract class SpeechState {
  const SpeechState();
}

class SpeechInitial extends SpeechState {}

class SpeechReady extends SpeechState {
  final bool enabled;
  const SpeechReady({required this.enabled});
}

class SpeechListening extends SpeechState {}

class SpeechStopped extends SpeechState {}

class SpeechResult extends SpeechState {
  final String text;
  final bool isFinal;
  const SpeechResult({required this.text, required this.isFinal});
}

class SpeechError extends SpeechState {
  final String message;
  const SpeechError(this.message);
}
