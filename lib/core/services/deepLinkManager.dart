import 'package:app_links/app_links.dart';
import 'package:eshop_plus/commons/product/models/product.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/main.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Simplified deep link manager that handles all scenarios correctly
class DeepLinkManager {
  static final DeepLinkManager _instance = DeepLinkManager._internal();
  factory DeepLinkManager() => _instance;
  DeepLinkManager._internal();

  late AppLinks _appLinks;
  Uri? _lastHandledUri;
  bool _isInitialized = false;
  bool _isAppReady = false;
  bool _isNavigatorReady = false;

  // Only queue deep links that arrive during cold start
  final List<Uri> _coldStartDeepLinks = [];
  bool _isColdStart = true;

  /// Initialize the deep link manager
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _appLinks = AppLinks();

    // Handle initial link when app is launched from terminated state
    _handleInitialLink();

    // Handle links when app is in foreground/background
    _appLinks.uriLinkStream.listen(_onDeepLinkReceived);
  }

  /// Mark app as ready (called after stores and settings are loaded)
  void markAppAsReady() {
    if (_isAppReady) return;

    _isAppReady = true;
    // print('DeepLinkManager: App is ready');

    // Process any cold start deep links
    _processColdStartDeepLinks();
  }

  /// Mark navigator as ready (called when main screen is loaded)
  void markNavigatorReady() {
    if (_isNavigatorReady) return;

    _isNavigatorReady = true;
    // print('DeepLinkManager: Navigator is ready');

    // Mark cold start as complete
    _isColdStart = false;

    // Process any remaining cold start deep links
    _processColdStartDeepLinks();
  }

  /// Check if app can handle deep links immediately
  bool get canHandleDeepLinks => _isAppReady && _isNavigatorReady;

  /// Check if there are cold start deep links pending
  bool get hasColdStartDeepLinks => _coldStartDeepLinks.isNotEmpty;

  /// Check if there are any deep links pending (including initial link)
  bool get hasPendingDeepLinks =>
      _coldStartDeepLinks.isNotEmpty || _lastHandledUri != null;

  /// Check if there are pending deep links before app is ready
  bool get hasInitialDeepLink => _lastHandledUri != null;

  /// Get the initial deep link URI
  Uri? get initialDeepLink => _lastHandledUri;

  /// Get count of cold start deep links
  int get coldStartDeepLinksCount => _coldStartDeepLinks.length;

  Future<void> _handleInitialLink() async {
    try {
      // final Uri? initialUri = await _appLinks.getInitialLink();
      // if (initialUri != null) {
      //   print('DeepLinkManager: Initial deep link received: $initialUri');
      //   _handleDeepLink(initialUri);
      // }
      _appLinks.uriLinkStream.listen((uri) {
        final initialUri = uri;
        if (initialUri != _lastHandledUri) {
          _lastHandledUri = initialUri; // Track it so it's not handled again
          _handleDeepLink(initialUri);
        }
      });
    } catch (e) {
      // print('DeepLinkManager: Error getting initial deep link: $e');
    }
  }

  void _onDeepLinkReceived(Uri uri) {
    // if (uri != _lastHandledUri) {
    _lastHandledUri = uri;
    // print('DeepLinkManager: Deep link received: $uri');
    _handleDeepLink(uri);
    // }
  }

  void _handleDeepLink(Uri uri) {
    // If app can handle deep links immediately, process now
    if (canHandleDeepLinks) {
      // print(
      //     'DeepLinkManager: App ready, processing deep link immediately: $uri');
      _processDeepLink(uri);
    } else {
      // App not ready, queue for cold start processing
      // print('DeepLinkManager: App not ready, queuing for cold start: $uri');
      // if (!_coldStartDeepLinks.contains(uri)) {
      _coldStartDeepLinks.add(uri);
      // }
    }
  }

  void _processColdStartDeepLinks() {
    if (_coldStartDeepLinks.isEmpty || !canHandleDeepLinks) return;

    // print(
    //     'DeepLinkManager: Processing ${_coldStartDeepLinks.length} cold start deep links');

    // Process the oldest cold start deep link
    final uri = _coldStartDeepLinks.removeAt(0);
    _processDeepLink(uri);
  }

  void _processDeepLink(Uri uri) {
    // print('DeepLinkManager: Processing deep link: $uri');

    // Get the current context from navigator key
    final context = navigatorKey.currentContext;
    if (context != null) {
      _executeDeepLink(uri, context);
    } else {
      // print('DeepLinkManager: No context available, re-queuing deep link');
      if (_isColdStart) {
        _coldStartDeepLinks.insert(0, uri);
      }
    }
  }

  void _executeDeepLink(Uri uri, BuildContext context) {
    try {
      // Check if we're still on splash screen
      if (Get.currentRoute == Routes.splashScreen) {
        // print('DeepLinkManager: Still on splash screen, re-queuing deep link');
        if (_isColdStart) {
          _coldStartDeepLinks.insert(0, uri);
        }
        return;
      }

      // print('DeepLinkManager: Executing deep link: $uri');

      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'product') {
        _handleProductDeepLink(uri, context);
      } else if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'products') {
        _handleProductsDeepLink(uri, context);
      } else if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'seller') {
        _handleSellerDeepLink(uri, context);
      }

      // print('DeepLinkManager: Deep link executed successfully: $uri');
    } catch (e) {
      // print('DeepLinkManager: Error executing deep link: $e');
      // Re-queue the deep link if there was an error and still in cold start
      if (_isColdStart) {
        _coldStartDeepLinks.insert(0, uri);
      }
    }
  }

  void _handleProductDeepLink(Uri uri, BuildContext context) {
    try {
      final int productId = int.parse(uri.pathSegments[1]);
      final int storeId = int.parse(uri.pathSegments[2]);
      final String productType = uri.pathSegments[3];

      Utils.navigateToScreen(
        context,
        Routes.productDetailsScreen,
        preventDuplicates: false,
        replacePrevious: Get.currentRoute == Routes.productDetailsScreen,
        arguments: {
          'storeId': storeId,
          'product': Product(id: productId, type: productType),
          'isComboProduct': productType == comboProductType,
          'productIds': [productId]
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  void _handleProductsDeepLink(Uri uri, BuildContext context) {
    try {
      final String slug =
          uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
      final String reference = uri.queryParameters['ref'] ?? '';

      Utils.navigateToScreen(
        context,
        Routes.productDetailsScreen,
        preventDuplicates: false,
        replacePrevious: Get.currentRoute == Routes.productDetailsScreen,
        arguments: {
          'slug': slug,
          'product': Product(slug: slug),
          'affiliateReference': reference,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  void _handleSellerDeepLink(Uri uri, BuildContext context) {
    try {
      final int sellerId = int.parse(uri.pathSegments[1]);
      final int storeId = int.parse(uri.pathSegments[2]);

      Utils.navigateToScreen(context, Routes.sellerDetailScreen,
          preventDuplicates: false,
          replacePrevious: Get.currentRoute == Routes.sellerDetailScreen,
          arguments: {
            'sellerId': sellerId,
            'storeId': storeId,
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cold start deep links (useful for testing or reset)
  void clearColdStartDeepLinks() {
    _coldStartDeepLinks.clear();
    _lastHandledUri = null;
  }

  /// Force process cold start deep links (useful for debugging)
  void forceProcessColdStartDeepLinks() {
    if (canHandleDeepLinks) {
      // print('DeepLinkManager: Force processing cold start deep links');
      _processColdStartDeepLinks();
    }
  }

  /// Get detailed status for debugging
  Map<String, dynamic> get debugStatus => {
        'isInitialized': _isInitialized,
        'isAppReady': _isAppReady,
        'isNavigatorReady': _isNavigatorReady,
        'isColdStart': _isColdStart,
        'canHandleDeepLinks': canHandleDeepLinks,
        'coldStartDeepLinksCount': _coldStartDeepLinks.length,
        'coldStartDeepLinks':
            _coldStartDeepLinks.map((uri) => uri.toString()).toList(),
        'lastHandledUri': _lastHandledUri?.toString(),
      };
}
