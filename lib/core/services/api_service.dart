import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  
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
        request.fields['manual_measurements'] = jsonEncode(manualMeasurements);
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          var result = data['results'][0];
          
          // Translate body type to Arabic if needed
          if (result['body_analysis'] != null && result['body_analysis']['type'] != null) {
            String bodyType = result['body_analysis']['type'];
            result['body_analysis']['type'] = bodyTypeTranslations[bodyType] ?? bodyType;
          }
          
          return result;
        }
        throw Exception('No results returned from API');
      } else if (response.statusCode == 422) {
        var error = jsonDecode(response.body);
        throw Exception('Validation error: ${error['detail']}');
      } else {
        throw Exception('Failed to process measurements: ${response.statusCode}');
      }
    } catch (e) {
      print('Error processing measurements: $e');
      rethrow;
    }
  }
  
  // Get abaya recommendations based on body type
  static Future<List<Map<String, dynamic>>> recommendAbayas(String bodyType) async {
    try {
      // Convert Arabic body type to English for API request
      String englishBodyType = bodyTypeToEnglish[bodyType] ?? bodyType;
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.recommendAbaya}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'body_type': englishBodyType,
        }),
      );
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var recommendations = List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
        
        // Translate body types back to Arabic in the response
        for (var recommendation in recommendations) {
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
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting recommendations: $e');
      rethrow;
    }
  }
}