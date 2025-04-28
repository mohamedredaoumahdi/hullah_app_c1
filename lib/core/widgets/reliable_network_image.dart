// lib/core/widgets/reliable_network_image.dart

import 'dart:convert';
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
    // Handle empty URLs immediately
    if (imageUrl.isEmpty) {
      if (debug) print('🖼️ Empty image URL provided');
      return _buildPlaceholder(context);
    }
    
    // Handle base64 data URLs directly without using CachedNetworkImage
    if (imageUrl.startsWith('data:image')) {
      return _buildBase64Image(context);
    }
    
    // Generate a cache key that includes dimensions to avoid cache conflicts
    final cacheKey = 'img_${imageUrl.hashCode}_${width ?? 0}_${height ?? 0}';
    
    if (debug) {
      print('🖼️ Building image: $altText');
      print('🖼️ URL: ${_truncateForLog(imageUrl)}');
      print('🖼️ Cache key: $cacheKey');
    }
    
    // For Google Drive URLs, check if we need to transform them
    final effectiveUrl = _getEffectiveUrl(imageUrl);
    
    if (debug && effectiveUrl != imageUrl) {
      print('🖼️ Transformed URL: ${_truncateForLog(effectiveUrl)}');
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
          print('🖼️ Failed URL: ${_truncateForLog(url)}');
        }
        return _buildErrorWidget(context, error);
      },
      cacheKey: cacheKey,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      httpHeaders: {
        'Accept': '*/*',
        'User-Agent': 'Hullah App',
      },
    );
  }
  
  // Handle base64 images properly
  Widget _buildBase64Image(BuildContext context) {
    try {
      if (debug) {
        print('🖼️ Processing base64 image for: $altText');
      }
      
      // FIX: Handle potential duplicate data prefixes
      String processedUrl = imageUrl;
      if (imageUrl.startsWith('data:image/jpeg;base64,data:image/')) {
        // Fix by removing the duplicate prefix
        processedUrl = imageUrl.replaceFirst('data:image/jpeg;base64,', '');
        if (debug) {
          print('🖼️ Fixed duplicate data prefix in URL');
        }
      }
      
      // Extract the actual base64 string from data URL
      final dataUri = Uri.parse(processedUrl);
      final isDataScheme = dataUri.scheme == 'data';
      
      if (!isDataScheme) {
        if (debug) print('🖼️ Invalid data URI scheme');
        return _buildErrorWidget(context, 'Invalid data URI');
      }
      
      // Parse the media type and encoding
      final uriWithoutScheme = processedUrl.substring(5); // Remove 'data:'
      final commaIndex = uriWithoutScheme.indexOf(',');
      
      if (commaIndex == -1) {
        if (debug) print('🖼️ No comma in data URI');
        return _buildErrorWidget(context, 'Invalid data URI format');
      }
      
      final metadata = uriWithoutScheme.substring(0, commaIndex);
      final data = uriWithoutScheme.substring(commaIndex + 1);
      
      if (debug) {
        print('🖼️ Data URI metadata: $metadata');
        print('🖼️ Base64 length: ${data.length}');
      }
      
      // Check if this is indeed a base64 encoded image
      if (!metadata.contains('image/')) {
        if (debug) print('🖼️ Not an image data URI');
        return _buildErrorWidget(context, 'Not an image data URI');
      }
      
      // Minimum length check
      if (data.length < 10) {
        if (debug) print('🖼️ Base64 data too short');
        return _buildErrorWidget(context, 'Base64 data too short');
      }
      
      try {
        // Try to decode the base64 data
        final bytes = base64.decode(data);
        if (bytes.isEmpty) {
          if (debug) print('🖼️ Decoded base64 to empty bytes');
          return _buildErrorWidget(context, 'Empty image data');
        }
        
        // Return an image from memory
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            if (debug) {
              print('🖼️ Error displaying memory image: $error');
            }
            return _buildErrorWidget(context, error);
          },
        );
      } catch (e) {
        if (debug) {
          print('🖼️ Base64 decode error: $e');
        }
        return _buildErrorWidget(context, 'Invalid base64 data: $e');
      }
    } catch (e) {
      if (debug) {
        print('🖼️ Error processing data URI: $e');
      }
      return _buildErrorWidget(context, e);
    }
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
  
  // Helper to truncate long URLs for logging
  String _truncateForLog(String text) {
    if (text.length > 100) {
      return '${text.substring(0, 100)}...';
    }
    return text;
  }
}