class AbayaModel {
  final String id;
  final String model;
  final String fabric;
  final String color;
  final String description;
  final String bodyShapeCategory;
  final String image1Url;
  final String? image2Url;
  final String? image3Url;
  final String? image4Url;
  final String? image5Url;
  final String? image6Url;
  final String? image7Url;
  final Map<String, dynamic>? additionalData;

  AbayaModel({
    required this.id,
    required this.model,
    required this.fabric,
    required this.color,
    required this.description,
    required this.bodyShapeCategory,
    required this.image1Url,
    this.image2Url,
    this.image3Url,
    this.image4Url,
    this.image5Url,
    this.image6Url,
    this.image7Url,
    this.additionalData,
  });

  factory AbayaModel.fromMap(Map<String, dynamic> map) {
    return AbayaModel(
      id: map['id'] ?? '',
      model: map['model'] ?? '',
      fabric: map['fabric'] ?? '',
      color: map['color'] ?? '',
      description: map['description'] ?? '',
      bodyShapeCategory: map['bodyShapeCategory'] ?? '',
      image1Url: map['image1Url'] ?? '',
      image2Url: map['image2Url'],
      image3Url: map['image3Url'],
      image4Url: map['image4Url'],
      image5Url: map['image5Url'],
      image6Url: map['image6Url'],
      image7Url: map['image7Url'],
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'fabric': fabric,
      'color': color,
      'description': description,
      'bodyShapeCategory': bodyShapeCategory,
      'image1Url': image1Url,
      'image2Url': image2Url,
      'image3Url': image3Url,
      'image4Url': image4Url,
      'image5Url': image5Url,
      'image6Url': image6Url,
      'image7Url': image7Url,
      'additionalData': additionalData,
    };
  }

  List<String> get allImageUrls {
    final List<String> urls = [image1Url];
    if (image2Url != null) urls.add(image2Url!);
    if (image3Url != null) urls.add(image3Url!);
    if (image4Url != null) urls.add(image4Url!);
    if (image5Url != null) urls.add(image5Url!);
    if (image6Url != null) urls.add(image6Url!);
    if (image7Url != null) urls.add(image7Url!);
    return urls;
  }
  
  // IMPROVED: Enhanced method to handle various Google Drive URL formats
  String getAccessibleImageUrl(String originalUrl) {
    // Skip processing if empty
    if (originalUrl.isEmpty) {
      return 'https://via.placeholder.com/400x600?text=No+Image';
    }
    
    // Handle data URLs (base64)
    if (originalUrl.startsWith('data:')) {
      return originalUrl;
    }
    
    // Handle different Google Drive URL formats
    
    // Format 1: https://drive.google.com/file/d/FILE_ID/view
    if (originalUrl.contains('drive.google.com/file/d/')) {
      final regex = RegExp(r'file/d/([^/]+)');
      final match = regex.firstMatch(originalUrl);
      if (match != null) {
        final fileId = match.group(1);
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
      }
    }
    
    // Format 2: https://drive.google.com/open?id=FILE_ID
    if (originalUrl.contains('drive.google.com/open?id=')) {
      final regex = RegExp(r'open\?id=([^&]+)');
      final match = regex.firstMatch(originalUrl);
      if (match != null) {
        final fileId = match.group(1);
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
      }
    }
    
    // Format 3: https://drive.google.com/uc?id=FILE_ID
    if (originalUrl.contains('drive.google.com/uc?')) {
      final regex = RegExp(r'[?&]id=([^&]+)');
      final match = regex.firstMatch(originalUrl);
      if (match != null) {
        final fileId = match.group(1);
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
      }
    }
    
    // Format 4: Already in thumbnail format but might need size parameter
    if (originalUrl.contains('drive.google.com/thumbnail')) {
      if (!originalUrl.contains('&sz=')) {
        return originalUrl + '&sz=w800';
      }
      return originalUrl;
    }
    
    // Default: try to use as-is if it's a regular URL
    if (originalUrl.startsWith('http')) {
      return originalUrl;
    }
    
    // Fallback for unrecognized formats
    return 'https://via.placeholder.com/400x600?text=Invalid+Image+URL';
  }
  
  // Getter for the main image URL in accessible format
  String get accessibleImage1Url => getAccessibleImageUrl(image1Url);
  
  // Get all image URLs in accessible format
  List<String> get accessibleImageUrls {
    final List<String> urls = [accessibleImage1Url];
    if (image2Url != null) urls.add(getAccessibleImageUrl(image2Url!));
    if (image3Url != null) urls.add(getAccessibleImageUrl(image3Url!));
    if (image4Url != null) urls.add(getAccessibleImageUrl(image4Url!));
    if (image5Url != null) urls.add(getAccessibleImageUrl(image5Url!));
    if (image6Url != null) urls.add(getAccessibleImageUrl(image6Url!));
    if (image7Url != null) urls.add(getAccessibleImageUrl(image7Url!));
    return urls;
  }
}