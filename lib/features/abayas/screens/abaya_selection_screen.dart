import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hullah_app/features/abayas/models/abaya_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/abayas_provider.dart';
import '../../measurements/providers/measurements_provider.dart';

class AbayaSelectionScreen extends StatefulWidget {
  const AbayaSelectionScreen({super.key});

  @override
  State<AbayaSelectionScreen> createState() => _AbayaSelectionScreenState();
}

class _AbayaSelectionScreenState extends State<AbayaSelectionScreen> {
  Set<String> _selectedAbayas = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRetrying = false;
  bool _debugMode = true; // Set to false in production

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbayas();
    });
  }

  Future<void> _loadAbayas() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isRetrying = false;
    });
    
    try {
      final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
      final bodyShape = measurementsProvider.bodyShape;
      
      if (_debugMode) {
        print('⚙️ Loading abayas for body shape: $bodyShape');
      }
      
      final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
      await abayasProvider.loadRecommendedAbayas(bodyShape: bodyShape);
      
      if (_debugMode) {
        print('⚙️ Loaded ${abayasProvider.recommendedAbayas.length} abayas');
        // Log the first abaya for inspection if available
        if (abayasProvider.recommendedAbayas.isNotEmpty) {
          final firstAbaya = abayasProvider.recommendedAbayas.first;
          print('⚙️ First abaya: id=${firstAbaya.id}, model=${firstAbaya.model}, image=${firstAbaya.image1Url}');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = abayasProvider.errorMessage;
          _selectedAbayas = Set<String>.from(abayasProvider.selectedAbayaIds);
        });
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error loading abayas: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _toggleSelection(String abayaId) {
    setState(() {
      if (_selectedAbayas.contains(abayaId)) {
        _selectedAbayas.remove(abayaId);
      } else {
        _selectedAbayas.add(abayaId);
      }
    });
    
    Provider.of<AbayasProvider>(context, listen: false)
        .updateSelectedAbayas(_selectedAbayas);
  }
  
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الخروج'),
        content: Text(_selectedAbayas.isNotEmpty 
          ? 'هل أنت متأكدة من الخروج؟ سيتم فقدان العبايات المختارة.' 
          : 'هل أنت متأكدة من الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final abayasProvider = Provider.of<AbayasProvider>(context);
    final measurementsProvider = Provider.of<MeasurementsProvider>(context);
    final bodyShape = measurementsProvider.bodyShape;
    
    return RTLScaffold(
      title: 'اختيار العبايات',
      showBackButton: true,
      confirmOnBack: _selectedAbayas.isNotEmpty,
      fallbackRoute: '/home',
      confirmationMessage: 'هل أنت متأكدة من الخروج؟ سيتم فقدان العبايات المختارة و القياسات المدخلة',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'اختاري العبايات المناسبة لشكل جسمك',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                if (bodyShape != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'شكل الجسم: $bodyShape',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Debug info section (only visible in debug mode)
          if (_debugMode && _errorMessage != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ Debug Error:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 4),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadAbayas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
                    ),
                    child: Text('Retry Loading'),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: _isLoading
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitCircle(color: AppTheme.primaryColor, size: 40),
                      SizedBox(height: 16),
                      Text('جاري تحميل العبايات المناسبة...'),
                      SizedBox(height: 8),
                      Text(
                        'قد يستغرق الأمر بعض الوقت في المرة الأولى',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ))
                : abayasProvider.recommendedAbayas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لم يتم العثور على عبايات',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'حدث خطأ أثناء تحميل العبايات، يرجى المحاولة مرة أخرى',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadAbayas,
                            icon: Icon(Icons.refresh),
                            label: Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: abayasProvider.recommendedAbayas.length,
                      itemBuilder: (context, index) {
                        final abaya = abayasProvider.recommendedAbayas[index];
                        final isSelected = _selectedAbayas.contains(abaya.id);
                        
                        return GestureDetector(
                          onTap: () => _toggleSelection(abaya.id),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildAbayaImage(abaya, index),
                                      ),
                                      if (_debugMode)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            color: Colors.black54,
                                            child: Text(
                                              'ID: ${abaya.id.substring(0, min(abaya.id.length, 8))}',
                                              style: TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        abaya.model,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${abaya.fabric} - ${abaya.color}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          
          Container(
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تم اختيار',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${_selectedAbayas.length} عبايات',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedAbayas.isEmpty
                        ? null
                        : () async {
                            // Save selected abayas before navigating
                            final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
                            await abayasProvider.saveSelectedAbayasToSummary();
                            
                            if (mounted) {
                              context.go('/summary');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text('عرض الملخص'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAbayaImage(AbayaModel abaya, int index) {
    if (_debugMode) {
      print('⚙️ Building image for index $index: ${abaya.image1Url}');
    }
    
    // Use the accessible image URL
    final imageUrl = abaya.accessibleImage1Url;
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        if (_debugMode) {
          print('❌ Error loading image at index $index: $error');
          print('❌ URL attempted: $url');
        }
        
        return Container(
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey[600]),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  abaya.model,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      maxHeightDiskCache: 500,
      maxWidthDiskCache: 500,
      // Implement special headers if needed
      httpHeaders: {
        'Accept': '*/*',
      },
    );
  }
  
  // Helper function
  int min(int a, int b) => a < b ? a : b;
}