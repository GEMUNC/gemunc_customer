import 'package:app_links/app_links.dart';
import 'package:eshop_plus/commons/product/models/product.dart';
import 'package:eshop_plus/core/routes/routes.dart';
import 'package:eshop_plus/main.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  late AppLinks _appLinks;
  Uri? _lastHandledUri;
  bool _isAppInitialized = false;
  bool _isInitialized = false;

  // Queue for deep links that arrive before app is ready
  final List<Uri> _pendingDeepLinks = [];

  void init(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    _appLinks = AppLinks();

    // Handle initial link when app is launched from terminated state
    _handleInitialLink(context);

    // Handle links when app is in foreground/background
    _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri != _lastHandledUri) {
          _lastHandledUri = uri;
          _handleDeepLink(uri, context);
        }
      },
    );
  }

  /// Mark app as initialized when stores and settings are loaded
  void markAppAsInitialized() {
    _isAppInitialized = true;
    _processPendingDeepLinks();
  }

  /// Check if app is ready to handle deep links
  bool get isAppReady => _isAppInitialized;

  Future<void> _handleInitialLink(BuildContext context) async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // print('Initial deep link received: $initialUri');

        // If app is already initialized, process immediately
        if (_isAppInitialized) {
          _handleDeepLink(initialUri, context);
        } else {
          // Store in pending queue
          _pendingDeepLinks.add(initialUri);
        }
      }
    } catch (e) {}
  }

  void _handleDeepLink(Uri uri, BuildContext context) {
    // If app is not ready, queue the deep link
    if (!_isAppInitialized) {
      if (!_pendingDeepLinks.contains(uri)) {
        _pendingDeepLinks.add(uri);
      }
      return;
    }

    // Check if we're still on splash screen
    if (Get.currentRoute == Routes.splashScreen) {
      if (!_pendingDeepLinks.contains(uri)) {
        _pendingDeepLinks.add(uri);
      }
      return;
    }

    _processDeepLink(uri, context);
  }

  void _processDeepLinks() {
    if (_pendingDeepLinks.isEmpty || !_isAppInitialized) return;

    // Process the oldest pending deep link
    final uri = _pendingDeepLinks.removeAt(0);
    _lastHandledUri = uri;

    // Get the current context from navigator key
    final context = navigatorKey.currentContext;
    if (context != null) {
      _processDeepLink(uri, context);
    }
  }

  void _processDeepLink(Uri uri, BuildContext context) {
    try {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'product') {
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
      } else if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'products') {
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
      } else if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'seller') {
        final int sellerId = int.parse(uri.pathSegments[1]);
        final int storeId = int.parse(uri.pathSegments[2]);

        Utils.navigateToScreen(context, Routes.sellerDetailScreen,
            preventDuplicates: false,
            replacePrevious: Get.currentRoute == Routes.sellerDetailScreen,
            arguments: {
              'sellerId': sellerId,
              'storeId': storeId,
            });
      }
    } catch (e) {}
  }

  /// Process any pending deep links when app becomes ready
  void _processPendingDeepLinks() {
    if (_pendingDeepLinks.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _processDeepLinks();
      });
    }
  }

  /// Clear all pending deep links (useful for testing or reset)
  void clearPendingDeepLinks() {
    _pendingDeepLinks.clear();
    _lastHandledUri = null;
  }

  /// Get current pending deep links count
  int get pendingDeepLinksCount => _pendingDeepLinks.length;

  /// Check if there are any pending deep links
  bool get hasPendingDeepLinks => _pendingDeepLinks.isNotEmpty;
}
