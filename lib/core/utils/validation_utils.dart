class ValidationUtils {
  // Regular expression to detect Arabic characters
  static final RegExp arabicRegex = RegExp(r'[\u0600-\u06FF]');
  
  // Validate phone number: must start with 05 and be 10 digits
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    
    if (!value.startsWith('05')) {
      return 'يجب أن يبدأ رقم الهاتف بـ 05';
    }
    
    if (value.length != 10) {
      return 'يجب أن يكون رقم الهاتف 10 أرقام';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'يجب أن يحتوي على أرقام فقط';
    }
    
    return null;
  }
  
  // Validate height: must be between 100 and 250 cm
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    
    final height = double.tryParse(value);
    if (height == null) {
      return 'يجب أن يكون رقماً';
    }
    
    if (height < 100) {
      return 'الحد الأدنى للطول 100 سم';
    }
    
    if (height > 250) {
      return 'الرجاء إدخال طول صحيح';
    }
    
    return null;
  }
  
  // Validate email/password: no Arabic characters allowed
  static String? validateLoginField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    
    if (arabicRegex.hasMatch(value)) {
      return 'يرجى استخدام أحرف إنجليزية فقط';
    }
    
    if (fieldName == 'email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    
    return null;
  }
  
  // Validate measurements: must be positive numbers within reasonable ranges
  static String? validateMeasurement(String? value, String measurementType) {
    if (value == null || value.isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    
    final measurement = double.tryParse(value);
    if (measurement == null || measurement <= 0) {
      return 'يجب أن يكون رقماً موجباً';
    }
    
    // Define reasonable ranges for different measurements
    Map<String, List<double>> ranges = {
      'chest': [50, 200],
      'waist': [40, 180],
      'hips': [60, 200],
      'shoulder': [30, 100],
      'armLength': [30, 100],
    };
    
    if (ranges.containsKey(measurementType)) {
      final range = ranges[measurementType]!;
      if (measurement < range[0]) {
        return 'القيمة صغيرة جداً (الحد الأدنى ${range[0]} سم)';
      }
      if (measurement > range[1]) {
        return 'القيمة كبيرة جداً (الحد الأقصى ${range[1]} سم)';
      }
    }
    
    return null;
  }
}