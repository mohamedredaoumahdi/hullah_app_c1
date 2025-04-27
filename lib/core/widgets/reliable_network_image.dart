// lib/core/widgets/reliable_network_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ReliableNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String altText;
  final bool showErrors;
  final bool debug;

  const ReliableNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.altText = '',
    this.showErrors = false,
    this.debug = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate a cache key that includes dimensions to avoid cache conflicts
    final cacheKey = 'img_${imageUrl.hashCode}_${width ?? 0}_${height ?? 0}';
    
    if (debug) {
      print('🖼️ Building image: $altText');
      print('🖼️ URL: $imageUrl');
      print('🖼️ Cache key: $cacheKey');
    }
    
    // Handle empty URLs immediately
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }
    
    // For Google Drive URLs, check if we need to transform them
    final effectiveUrl = _getEffectiveUrl(imageUrl);
    
    if (debug && effectiveUrl != imageUrl) {
      print('🖼️ Transformed URL: $effectiveUrl');
    }

    return CachedNetworkImage(
      imageUrl: effectiveUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => _buildLoadingIndicator(context),
      errorWidget: (context, url, error) {
        if (debug) {
          print('🖼️ Error loading image: $error');
          print('🖼️ Failed URL: $url');
        }
        return _buildErrorWidget(context, error);
      },
      // Advanced caching options
      cacheKey: cacheKey,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 1200,
      httpHeaders: {
        'Accept': '*/*',
        'User-Agent': 'Hullah App',
      },
    );
  }
  
  // Helper to transform Google Drive URLs
  String _getEffectiveUrl(String url) {
    // Already a data URL (base64)
    if (url.startsWith('data:')) {
      return url;
    }
    
    // Placeholder URLs
    if (url.contains('via.placeholder.com')) {
      return url;
    }
    
    // Handle Google Drive URLs
    if (url.contains('drive.google.com')) {
      // Format: drive.google.com/file/d/FILE_ID/view
      if (url.contains('/file/d/')) {
        final regex = RegExp(r'file/d/([^/]+)');
        final match = regex.firstMatch(url);
        if (match != null) {
          final fileId = match.group(1);
          return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
        }
      }
      
      // Format: drive.google.com/open?id=FILE_ID
      if (url.contains('open?id=')) {
        final regex = RegExp(r'open\?id=([^&]+)');
        final match = regex.firstMatch(url);
        if (match != null) {
          final fileId = match.group(1);
          return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
        }
      }
      
      // Format: drive.google.com/uc?id=FILE_ID or drive.google.com/whatever?id=FILE_ID
      if (url.contains('id=')) {
        final regex = RegExp(r'[?&]id=([^&]+)');
        final match = regex.firstMatch(url);
        if (match != null) {
          final fileId = match.group(1);
          return 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
        }
      }
    }
    
    // Return original URL if no transformations needed
    return url;
  }
  
  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40),
            SizedBox(height: 8),
            if (altText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  altText,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (showErrors)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  error.toString(),
                  style: TextStyle(color: Colors.red, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.grey[400], size: 40),
            if (altText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  altText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}