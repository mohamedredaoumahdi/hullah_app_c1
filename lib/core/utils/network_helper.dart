// lib/core/utils/network_helper.dart

import 'dart:async';
import 'dart:io';

/// Helper class for handling network operations with retry logic
class NetworkHelper {
  /// Executes an operation with retry capability
  ///
  /// [attempts] - Maximum number of retry attempts (default: 3)
  /// [delayBetweenAttempts] - Delay between retry attempts (default: 2 seconds)
  /// [operation] - The async function to execute
  /// [onRetry] - Optional callback that gets called before each retry with the attempt number
  /// [shouldRetry] - Optional function to determine if a particular exception should trigger a retry
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int attempts = 3,
    Duration delayBetweenAttempts = const Duration(seconds: 2),
    void Function(int attempt)? onRetry,
    bool Function(Exception e)? shouldRetry,
  }) async {
    int currentAttempt = 1;
    
    while (true) {
      try {
        return await operation();
      } catch (e) {
        // Default retry conditions if not specified
        final shouldAttemptRetry = shouldRetry != null
            ? e is Exception && shouldRetry(e as Exception)
            : _defaultShouldRetry(e);
        
        // Check if we've reached max attempts or shouldn't retry this exception
        if (currentAttempt >= attempts || !shouldAttemptRetry) {
          rethrow;
        }
        
        // Call the onRetry callback if provided
        if (onRetry != null) {
          onRetry(currentAttempt);
        }
        
        // Wait before next attempt with exponential backoff
        final exponentialDelay = Duration(
          milliseconds: delayBetweenAttempts.inMilliseconds * (currentAttempt * 2),
        );
        
        await Future.delayed(exponentialDelay);
        currentAttempt++;
      }
    }
  }
  
  /// Default logic to determine if an exception should trigger a retry
  static bool _defaultShouldRetry(dynamic error) {
    // Retry on common network errors
    return error is SocketException || // Connection errors
           error is TimeoutException || // Timeouts
           error is HttpException || // HTTP exceptions
           (error is IOException && error.toString().contains('Connection')); // Other IO errors
  }
  
  /// Check if the device has an active internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
  
  /// Check network connection type
  /// 
  /// Returns 'wifi', 'mobile', or 'none'
  static Future<String> getConnectionType() async {
    try {
      // This is a simplified implementation
      // In a real app, you would use connectivity package
      final hasConnection = await hasInternetConnection();
      return hasConnection ? 'unknown' : 'none';
    } catch (_) {
      return 'none';
    }
  }
  
  /// Format a network error message for user display
  static String formatErrorForUser(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
    } else if (error is SocketException) {
      return 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
    } else if (error.toString().contains('Connection refused')) {
      return 'الخادم غير متاح حاليًا. قد يكون الخادم قيد الصيانة، يرجى المحاولة لاحقًا.';
    } else {
      return 'حدث خطأ في الاتصال بالخادم. يرجى المحاولة مرة أخرى.';
    }
  }
}