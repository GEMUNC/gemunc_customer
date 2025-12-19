import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class InternetConnectivity {
  static Future<bool> isUserOffline() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();

    if (Platform.isIOS) {
      const bool isSimulator = bool.fromEnvironment('dart.vm.product') == false;
      if (isSimulator) {
        return false;
      }
    }

    return !connectivityResult.contains(ConnectivityResult.wifi) &&
        !connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.ethernet);
  }
}
