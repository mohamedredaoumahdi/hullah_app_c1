class ApiConstants {
  // Base URL configuration
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  // For production, use your actual server URL
  // static const String baseUrl = 'https://your-api-server.com';
  
  // API endpoints
  static const String processMeasurements = '/process-measurements';
  static const String recommendAbaya = '/recommend-abaya';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}