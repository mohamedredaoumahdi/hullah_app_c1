class ApiConstants {
  // Base URL configuration
  static const String baseUrl = 'https://abaya.onrender.com';
  
  // For local development, use:
  // static const String baseUrl = 'http://127.0.0.1:8000';
  
  // API endpoints
  static const String processMeasurements = '/process-measurements';
  static const String recommendAbaya = '/recommend-abaya';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 60); // Increased timeout for slower server responses
  static const Duration receiveTimeout = Duration(seconds: 60); // Increased timeout for slower server responses
}