import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

class NetworkService {
  /// Check if device has network connectivity by attempting DNS lookup
  static Future<bool> hasNetworkConnection() async {
    try {
      developer.log('Checking network connectivity via DNS lookup', name: 'NetworkService');

      // Attempt to lookup a well-known DNS (Google's)
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      developer.log('Network connection check: $hasConnection', name: 'NetworkService');
      return hasConnection;
    } catch (e) {
      developer.log(
        'Network check failed ($e) - assuming no connection',
        name: 'NetworkService',
      );
      return false;
    }
  }

  /// Wait for network connection with retry
  static Future<bool> waitForNetworkConnection({
    Duration timeout = const Duration(seconds: 15),
    Duration retryInterval = const Duration(seconds: 2),
  }) async {
    try {
      developer.log('Waiting for network connection...', name: 'NetworkService');

      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < timeout) {
        final hasConnection = await hasNetworkConnection();
        if (hasConnection) {
          developer.log('Network connection restored', name: 'NetworkService');
          return true;
        }

        developer.log(
          'No connection yet, retrying in ${retryInterval.inSeconds}s...',
          name: 'NetworkService',
        );
        await Future.delayed(retryInterval);
      }

      developer.log('Timeout waiting for network connection', name: 'NetworkService');
      return false;
    } catch (e) {
      developer.log('Error waiting for network: $e', name: 'NetworkService');
      return false;
    }
  }
}
