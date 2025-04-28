// lib/core/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

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
  
  // Analyze measurements either from image or manual input
  static Future<Map<String, dynamic>> processMeasurements({
    required double userHeightCm,
    File? image,
    Map<String, dynamic>? manualMeasurements,
  }) async {
    try {
      if (_debugMode) {
        print('🔍 API: Processing measurements');
        print('🔍 Height: $userHeightCm cm');
        if (image != null) print('🔍 Using image file: ${image.path}');
        if (manualMeasurements != null) print('🔍 Using manual measurements with ${manualMeasurements.length} fields');
      }
      
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
      
      // Set a longer timeout for the request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Connection timeout. The server might be starting up, please try again.');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);
      
      if (_debugMode) {
        print('🔍 API response status: ${response.statusCode}');
      }
      
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
            
            // Convert any missing fields to our expected format
            if (manualMeasurements != null) {
              for (var key in manualMeasurements.keys) {
                if (measurements[key] == null) {
                  measurements[key] = manualMeasurements[key];
                }
              }
            }
          }
          
          return result;
        }
        throw Exception('No results returned from API');
      } else if (response.statusCode == 422) {
        var error = jsonDecode(response.body);
        throw Exception('Validation error: ${error['detail']}');
      } else {
        if (_debugMode) {
          print('❌ API error response: ${response.body}');
        }
        throw Exception('Failed to process measurements: ${response.statusCode}');
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error processing measurements: $e');
      }
      rethrow;
    }
  }
  
  // Get abaya recommendations based on body type
  static Future<List<Map<String, dynamic>>> recommendAbayas(String bodyShape) async {
    try {
      if (_debugMode) {
        print('🔍 API: Recommending abayas for body shape: $bodyShape');
      }
      
      // Convert Arabic body type to English for API request
      String englishBodyType = bodyTypeToEnglish[bodyShape] ?? bodyShape;
      
      if (_debugMode) {
        print('🔍 Translated body type to English: $englishBodyType');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.recommendAbaya}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'body_type': englishBodyType,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Connection timeout. The server might be starting up, please try again.');
        },
      );
      
      if (_debugMode) {
        print('🔍 API response status: ${response.statusCode}');
      }
      
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
        var error = jsonDecode(response.body);
        throw Exception('Validation error: ${error['detail']}');
      } else {
        if (_debugMode) {
          print('❌ API error response: ${response.body}');
        }
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error getting recommendations: $e');
      }
      rethrow;
    }
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
}