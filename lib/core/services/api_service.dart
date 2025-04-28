// lib/core/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/network_helper.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const bool _debugMode = true; // Set to false in production
  
  // Map to convert English body types to Arabic
  static const Map<String, String> bodyTypeTranslations = {
    'hourglass': 'ساعة رملية',
    'pear': 'كمثرى', 
    'inverted_triangle': 'مثلث مقلوب',
    'rectangle': 'مستطيل',
    'apple': 'تفاحة',
  };
  
  // Map to convert Arabic body types to English for API requests
  static const Map<String, String> bodyTypeToEnglish = {
    'ساعة رملية': 'hourglass',
    'كمثرى': 'pear',
    'مثلث مقلوب': 'inverted_triangle',
    'مستطيل': 'rectangle',
    'تفاحة': 'apple',
  };
  
  // Create a client with timeout settings
  static final _client = http.Client();
  
  // Status of the API
  static bool _apiAvailable = true;
  static int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static DateTime? _lastSuccessfulApiCall;
  
  // Getter for API status
  static bool get isApiAvailable => _apiAvailable;
  static DateTime? get lastSuccessfulApiCall => _lastSuccessfulApiCall;
  
  // Analyze measurements either from image or manual input
  static Future<Map<String, dynamic>> processMeasurements({
    required double userHeightCm,
    File? image,
    Map<String, dynamic>? manualMeasurements,
  }) async {
    if (_debugMode) {
      print('🔍 API: Processing measurements');
      print('🔍 Height: $userHeightCm cm');
      if (image != null) print('🔍 Using image file: ${image.path}');
      if (manualMeasurements != null) print('🔍 Using manual measurements with ${manualMeasurements.length} fields');
    }
    
    try {
      // Check if API is likely down based on consecutive failures
      if (!_apiAvailable) {
        if (_debugMode) {
          print('⚠️ API is marked as unavailable, checking if we should retry');
        }
        
        // If it's been more than 5 minutes since last check, try again
        final now = DateTime.now();
        if (_lastSuccessfulApiCall == null || 
            now.difference(_lastSuccessfulApiCall!).inMinutes > 5) {
          if (_debugMode) {
            print('🔄 Trying API again after timeout period');
          }
          _apiAvailable = true;
        } else {
          throw Exception('خادم API غير متاح حالياً. جاري استخدام البيانات المحلية بدلاً من ذلك.');
        }
      }
      
      // Create a request with retry and timeout handling
      return await NetworkHelper.withRetry(
        attempts: 3,
        onRetry: (attempt) => _debugMode ? print('🔄 Retry attempt $attempt for measurement processing') : null,
        operation: () async {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl${ApiConstants.processMeasurements}'),
          );
          
          // Add user height
          request.fields['user_height_cm'] = userHeightCm.toString();
          
          // Add image if provided
          if (image != null) {
            request.files.add(
              await http.MultipartFile.fromPath('image', image.path),
            );
          }
          
          // Add manual measurements if provided
          if (manualMeasurements != null) {
            // Convert the field names to match what the API expects
            final apiMeasurements = {
              'chest': manualMeasurements['chest'],
              'waist': manualMeasurements['waist'],
              'hips': manualMeasurements['hips'],
              'bust': manualMeasurements['chest'], // Add bust for API compatibility
              'shoulder': manualMeasurements['shoulder'],
              'armLength': manualMeasurements['armLength'],
              'height': userHeightCm,
            };
            
            request.fields['manual_measurements'] = jsonEncode(apiMeasurements);
            
            if (_debugMode) {
              print('🔍 Sending measurements to API: ${request.fields['manual_measurements']}');
            }
          }
          
          // Add common headers
          request.headers.addAll(_getCommonHeaders());
          
          // Set a longer timeout for the request
          var streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              _handleApiFailure();
              throw TimeoutException('Connection timeout. The server might be starting up, please try again.');
            },
          );
          
          var response = await http.Response.fromStream(streamedResponse);
          
          if (_debugMode) {
            print('🔍 API response status: ${response.statusCode}');
          }
          
          // Handle response
          final result = _handleMeasurementsResponse(response);
          
          // If we get here, the API call was successful
          _handleApiSuccess();
          
          return result;
        }
      );
    } on TimeoutException {
      _handleApiFailure();
      throw Exception('انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.');
    } catch (e) {
      if (_debugMode) {
        print('❌ Error processing measurements: $e');
      }
      
      // Don't mark as API failure if it's our custom exception for unavailable API
      if (e.toString().contains('خادم API غير متاح حالياً')) {
        rethrow;
      }
      
      _handleApiFailure();
      
      // Translate common error messages to Arabic
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw Exception('انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        throw Exception('فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
      }
      
      rethrow;
    }
  }
  
  // Handle measurements API response
  static Map<String, dynamic> _handleMeasurementsResponse(http.Response response) {
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (_debugMode) {
        print('🔍 API response data keys: ${data.keys.join(', ')}');
      }
      
      if (data['results'] != null && data['results'].isNotEmpty) {
        var result = data['results'][0];
        
        // Translate body type to Arabic if needed
        if (result['body_analysis'] != null && result['body_analysis']['type'] != null) {
          String bodyType = result['body_analysis']['type'];
          result['body_analysis']['type'] = bodyTypeTranslations[bodyType] ?? bodyType;
        }
        
        // Map API measurements to our app format if necessary
        var measurements = result['measurements'];
        if (measurements != null) {
          // If the API returned 'bust' instead of 'chest', map it
          if (measurements['bust'] != null && measurements['chest'] == null) {
            measurements['chest'] = measurements['bust'];
          }
        }
        
        return result;
      }
      throw Exception('لم يتم إرجاع أي نتائج من الخادم');
    } else if (response.statusCode == 422) {
      _handleApiFailure();
      var error = jsonDecode(response.body);
      throw Exception('خطأ في التحقق من البيانات: ${error['detail']}');
    } else {
      _handleApiFailure();
      if (_debugMode) {
        print('❌ API error response: ${response.body}');
      }
      throw Exception('فشل في معالجة القياسات: ${response.statusCode}');
    }
  }
  
  // Get abaya recommendations based on body type
  static Future<List<Map<String, dynamic>>> recommendAbayas(String bodyShape) async {
    if (_debugMode) {
      print('🔍 API: Recommending abayas for body shape: $bodyShape');
    }
    
    try {
      // Check if API is likely down based on consecutive failures
      if (!_apiAvailable) {
        if (_debugMode) {
          print('⚠️ API is marked as unavailable, checking if we should retry');
        }
        
        // If it's been more than 5 minutes since last check, try again
        final now = DateTime.now();
        if (_lastSuccessfulApiCall == null || 
            now.difference(_lastSuccessfulApiCall!).inMinutes > 5) {
          if (_debugMode) {
            print('🔄 Trying API again after timeout period');
          }
          _apiAvailable = true;
        } else {
          throw Exception('خادم API غير متاح حالياً. جاري استخدام البيانات المحلية بدلاً من ذلك.');
        }
      }
      
      // Convert Arabic body type to English for API request
      String englishBodyType = bodyTypeToEnglish[bodyShape] ?? bodyShape;
      
      if (_debugMode) {
        print('🔍 Translated body type to English: $englishBodyType');
      }
      
      // Use network helper with retry capability
      return await NetworkHelper.withRetry(
        attempts: 3,
        onRetry: (attempt) => _debugMode ? print('🔄 Retry attempt $attempt for abaya recommendations') : null,
        operation: () async {
          final response = await _client.post(
            Uri.parse('$baseUrl${ApiConstants.recommendAbaya}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ..._getCommonHeaders(),
            },
            body: jsonEncode({
              'body_type': englishBodyType,
            }),
          ).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              _handleApiFailure();
              throw TimeoutException('Connection timeout. The server might be starting up, please try again.');
            },
          );
          
          if (_debugMode) {
            print('🔍 API response status: ${response.statusCode}');
          }
          
          final result = _handleRecommendationsResponse(response);
          
          // If we get here, the API call was successful
          _handleApiSuccess();
          
          return result;
        }
      );
    } on TimeoutException {
      _handleApiFailure();
      throw Exception('انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.');
    } catch (e) {
      if (_debugMode) {
        print('❌ Error getting recommendations: $e');
      }
      
      // Don't mark as API failure if it's our custom exception for unavailable API
      if (e.toString().contains('خادم API غير متاح حالياً')) {
        rethrow;
      }
      
      _handleApiFailure();
      
      // Translate common error messages to Arabic
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw Exception('انتهت مهلة الاتصال. قد يستغرق بدء تشغيل الخادم بعض الوقت، يرجى المحاولة مرة أخرى.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        throw Exception('فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
      }
      
      rethrow;
    }
  }
  
  // Handle recommendations API response
  static List<Map<String, dynamic>> _handleRecommendationsResponse(http.Response response) {
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      
      if (_debugMode) {
        print('🔍 API response data keys: ${data.keys.join(', ')}');
        if (data['recommendations'] != null) {
          print('🔍 Received ${data['recommendations'].length} recommendations');
        }
      }
      
      var recommendations = List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
      
      // Process and fix the base64 images
      for (var recommendation in recommendations) {
        // Make sure image_base64 is valid
        if (recommendation['image_base64'] != null) {
          var base64Str = recommendation['image_base64'] as String;
          
          // IMPORTANT FIX: Check if the base64 string already has the data URL prefix
          if (base64Str.startsWith('data:image/')) {
            if (_debugMode) print('🔍 Image is already in data URL format');
            continue; // Already in the correct format
          }
          
          // Clean the base64 string - remove any whitespace
          base64Str = base64Str.trim();
          
          try {
            // Test if it's valid base64
            base64.decode(base64Str);
            
            // Convert to a proper data URL
            recommendation['image_base64'] = 'data:image/jpeg;base64,$base64Str';
            
            if (_debugMode) {
              final preview = base64Str.length > 20 ? base64Str.substring(0, 20) + '...' : base64Str;
              print('🔍 Converted base64 to data URL. Preview: $preview');
            }
          } catch (e) {
            if (_debugMode) {
              print('❌ Invalid base64 data: $e');
            }
            // Remove invalid base64 data
            recommendation['image_base64'] = null;
          }
        }
        
        // Translate body types back to Arabic in the response
        if (recommendation['body_type'] != null) {
          String bodyType = recommendation['body_type'];
          recommendation['body_type'] = bodyTypeTranslations[bodyType] ?? bodyType;
        }
      }
      
      return recommendations;
    } else if (response.statusCode == 422) {
      _handleApiFailure();
      var error = jsonDecode(response.body);
      throw Exception('خطأ في التحقق من البيانات: ${error['detail']}');
    } else {
      _handleApiFailure();
      if (_debugMode) {
        print('❌ API error response: ${response.body}');
      }
      throw Exception('فشل في الحصول على التوصيات: ${response.statusCode}');
    }
  }
  
  // New method to send support ticket to API (if supported by backend)
  static Future<bool> sendSupportTicket({
    required String name,
    required String email,
    required String subject,
    required String description,
  }) async {
    if (_debugMode) {
      print('🔍 API: Sending support ticket');
      print('🔍 Subject: $subject');
    }
    
    try {
      // Check if endpoint exists in API constants
      final endpoint = '/support'; // Add this to your ApiConstants class
      
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ..._getCommonHeaders(),
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'subject': subject,
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _handleApiFailure();
          throw TimeoutException('Connection timeout');
        },
      );
      
      if (_debugMode) {
        print('🔍 API response status: ${response.statusCode}');
      }
      
      final success = response.statusCode == 200 || response.statusCode == 201;
      
      if (success) {
        _handleApiSuccess();
      } else {
        _handleApiFailure();
      }
      
      return success;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error sending support ticket: $e');
      }
      
      _handleApiFailure();
      
      // Just return false on error - we already have Firestore backup
      return false;
    }
  }
  
  // Helper method to check API health/status
  static Future<bool> checkApiHealth() async {
    try {
      if (_debugMode) {
        print('🔍 Checking API health');
      }
      
      final response = await _client.get(
        Uri.parse(baseUrl),
        headers: _getCommonHeaders(),
      ).timeout(
        const Duration(seconds: 5),
      );
      
      if (_debugMode) {
        print('🔍 API health check status: ${response.statusCode}');
      }
      
      final isHealthy = response.statusCode == 200;
      
      if (isHealthy) {
        _handleApiSuccess();
      } else {
        _handleApiFailure();
      }
      
      return isHealthy;
    } catch (e) {
      if (_debugMode) {
        print('❌ API health check failed: $e');
      }
      
      _handleApiFailure();
      return false;
    }
  }
  
  // Mark API as successful
  static void _handleApiSuccess() {
    _consecutiveFailures = 0;
    _apiAvailable = true;
    _lastSuccessfulApiCall = DateTime.now();
    
    if (_debugMode) {
      print('✅ API call successful, resetting failure count');
    }
  }
  
  // Mark API as failed
  static void _handleApiFailure() {
    _consecutiveFailures++;
    
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _apiAvailable = false;
      
      if (_debugMode) {
        print('⚠️ API marked as unavailable after $_consecutiveFailures consecutive failures');
      }
    }
    
    if (_debugMode) {
      print('⚠️ API call failed, consecutive failures: $_consecutiveFailures');
    }
  }
  
  // Common headers for all requests
  static Map<String, String> _getCommonHeaders() {
    return {
      'User-Agent': 'HullahApp/1.0',
      'Accept-Language': 'ar',
      'X-Client-Version': '1.0.0',
    };
  }
  
  // Helper function to check if a string is valid base64
  static bool isValidBase64(String str) {
    try {
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Reset API status - can be called manually to force a retry
  static void resetApiStatus() {
    _apiAvailable = true;
    _consecutiveFailures = 0;
    
    if (_debugMode) {
      print('🔄 API status manually reset');
    }
  }
  
  // Dispose method to clean up resources
  static void dispose() {
    _client.close();
  }
}