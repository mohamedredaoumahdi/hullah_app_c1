import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/abayas_provider.dart';
import '../models/abaya_model.dart';

class AbayaDetailsScreen extends StatefulWidget {
  final String abayaId;
  
  const AbayaDetailsScreen({
    super.key,
    required this.abayaId,
  });

  @override
  State<AbayaDetailsScreen> createState() => _AbayaDetailsScreenState();
}

class _AbayaDetailsScreenState extends State<AbayaDetailsScreen> {
  AbayaModel? _abaya;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAbayaDetails();
  }

  Future<void> _loadAbayaDetails() async {
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    final abaya = await abayasProvider.getAbayaById(widget.abayaId);
    
    if (mounted) {
      setState(() {
        _abaya = abaya;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_abaya == null) {
      return Scaffold(
        body: Center(child: Text('العباية غير موجودة')),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_abaya!.model),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 400,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: _abaya!.allImageUrls.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.greyColor,
                        child: Icon(Icons.error, color: Colors.red, size: 40),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            
            // Image indicators
            if (_abaya!.allImageUrls.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _abaya!.allImageUrls.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? AppTheme.primaryColor
                          : AppTheme.greyColor,
                    ),
                  );
                }).toList(),
              ),
            
            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _abaya!.model,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Fabric and color
                  _buildDetailRow(Icons.texture, 'القماش', _abaya!.fabric),
                  _buildDetailRow(Icons.color_lens, 'اللون', _abaya!.color),
                  _buildDetailRow(Icons.accessibility, 'شكل الجسم المناسب', _abaya!.bodyShapeCategory),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'الوصف',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _abaya!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Additional info if available
                  if (_abaya!.additionalData != null && _abaya!.additionalData!.isNotEmpty) ...[
                    Text(
                      'معلومات إضافية',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    ..._abaya!.additionalData!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
              final selectedIds = Set<String>.from(abayasProvider.selectedAbayaIds);
              selectedIds.add(widget.abayaId);
              abayasProvider.updateSelectedAbayas(selectedIds);
              
              context.pop();
            },
            child: Text('إضافة إلى الاختيارات'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}