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
  
  // Get a more accessible version of the image URL
  String getAccessibleImageUrl(String originalUrl) {
    if (originalUrl.contains('drive.google.com') && originalUrl.contains('id=')) {
      // Extract the file ID from the Google Drive URL
      final regex = RegExp(r'id=([^&]+)');
      final match = regex.firstMatch(originalUrl);
      if (match != null) {
        final fileId = match.group(1);
        // Use the thumbnail URL format which is more reliable
        return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
      }
    }
    return originalUrl;
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