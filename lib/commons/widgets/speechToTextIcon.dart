import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/main.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/ui/search/blocs/searchProductCubit.dart';
import 'package:eshop_plus/commons/blocs/storesCubit.dart';
import 'package:eshop_plus/ui/search/models/searchedProduct.dart';
import 'package:eshop_plus/commons/product/repositories/productRepository.dart';
import 'package:eshop_plus/ui/explore/screens/exploreScreen.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextIcon extends StatefulWidget {
  final SpeechToText speechToText;
  final Function callback;
  final StateSetter setState;
  const SpeechToTextIcon(
      {Key? key,
      required this.speechToText,
      required this.callback,
      required this.setState})
      : super(key: key);

  @override
  _SpeechToTextIconState createState() => _SpeechToTextIconState();
}

class _SpeechToTextIconState extends State<SpeechToTextIcon> {
  bool _isListening = false;
  String _currentLocaleId = '';
  bool _speechEnabled = false;
  String _lastWords = '';

  /// This has to happen only once per app
  Future<bool> _initSpeech() async {
    try {
      if (_speechEnabled) return true;

      debugPrint('Initializing speech recognition...');
      var speechEnabled = await widget.speechToText.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );

      if (speechEnabled) {
        var systemLocale = await widget.speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
        debugPrint(
            'Speech initialized successfully with locale: $_currentLocaleId');
      } else {
        debugPrint('Speech initialization failed - speech not enabled');
      }

      if (!mounted) return false;

      setState(() {
        _speechEnabled = speechEnabled;
      });

      return speechEnabled;
    } catch (e) {
      debugPrint('Speech recognition initialization failed: ${e.toString()}');
      if (mounted) {
        setState(() {
          _speechEnabled = false;
        });
      }
      return false;
    }
  }

  void errorListener(SpeechRecognitionError error) {
    _stopListening();
    debugPrint(
        'Speech recognition error: ${error.errorMsg}, permanent: ${error.permanent}');

    if (mounted) {
      String message = speechRecognitionFailedTryAgainKey;

      // Provide more specific error messages
      if (error.errorMsg.contains('not-allowed') ||
          error.errorMsg.contains('permission')) {
        message = microphonePermissionRequiredKey;
      } else if (error.errorMsg.contains('network')) {
        message = networkErrorCheckConnectionKey;
      } else if (error.errorMsg.contains('no-speech')) {
        message = noSpeechDetectedSpeakClearlyKey;
      } else if (error.errorMsg.contains('aborted')) {
        message = speechRecognitionCancelledKey;
      }

      Utils.showSnackBar(
          message: message, context: navigatorKey.currentContext!);
    }
  }

  void statusListener(String status) {
    debugPrint(
        'Received listener status: $status, listening: ${widget.speechToText.isListening}');
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    try {
      FocusScope.of(context).unfocus();

      // First check and request permissions
      bool hasPermission = await Utils.requestMicrophonePermission(context);
      if (!hasPermission) {
        return;
      }

      // Initialize speech if not already done
      if (!_speechEnabled) {
        bool initialized = await _initSpeech();
        if (!initialized) {
          if (mounted) {
            Utils.showSnackBar(
                message: speechRecognitionFailureKey,
                context: context);
          }
          return;
        }
      }

      // Check if speech to text is available after initialization
      if (!widget.speechToText.isAvailable) {
        if (mounted) {
          Utils.showSnackBar(
              message: speechRecognitionNotAvailableKey,
              context: context);
        }
        return;
      }

      // Set listening state
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }

      // Start listening
      await widget.speechToText.listen(
        onResult: resultListener,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenMode: ListenMode.confirmation),
        localeId: _currentLocaleId.isNotEmpty ? _currentLocaleId : null,
        onSoundLevelChange: _onSoundLevelChange,
      );

      debugPrint('Started listening for speech');
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        Utils.showSnackBar(
            message: '$failedToStartSpeechRecognitionKey: ${e.toString()}',
            context: context);
      }
    }
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    debugPrint(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    if (mounted)
      setState(() {
        _lastWords = result.recognizedWords;
      });
    if (_lastWords.isNotEmpty) {
      widget.callback(_lastWords);
      getProducts(search: _lastWords);
    }
  }

  /// Restart listening when silent
  void _onSoundLevelChange(double level) {
    if (level < 0.2 && widget.speechToText.isNotListening) {
      _startListening();
    }
  }

  void _stopListening() {
    widget.speechToText.stop();
    widget.setState(() => _isListening = false);
  }

  getProducts({required String search}) {
    context.read<SearchProductCubit>().searchProducts(
        storeId: context.read<StoresCubit>().getDefaultStore().id!,
        query: search);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchProductCubit, SearchProductState>(
      listener: (context, state) {
        if (state is SearchProductFetchSuccess && _isListening) {
          _stopListening();
          ProductRepository().addSearchInLocalHistory(_lastWords);
          navigatoToExploreScreen(state);
        }
        if (state is SearchProductFetchFailure) {
          
          if (_isListening) {
            _stopListening();
          }
        }
      },
      builder: (context, state) {
        return IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.46),
          ),
          onPressed: _isListening ? _stopListening : _startListening,
        );
      },
    );
  }

  navigatoToExploreScreen(SearchProductFetchSuccess state) {
    List<SearchedProduct> regularProducts = state.searchProducts
        .where((element) => element.type == 'products')
        .toList();
    List<SearchedProduct> comboProducts = state.searchProducts
        .where((element) => element.type == 'combo_products')
        .toList();

    Utils.navigateToScreen(
      navigatorKey.currentContext!,
      Routes.exploreScreen,
      arguments: ExploreScreen.buildArguments(
          title: _lastWords,
          productIds: regularProducts.map((e) => e.productId!).toList(),
          comboProductIds: comboProducts.isNotEmpty
              ? comboProducts.map((e) => e.productId!).toList()
              : [],
          fromSearchScreen: true),
      preventDuplicates: false,
    );
  }
}
