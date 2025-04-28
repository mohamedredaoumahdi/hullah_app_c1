// lib/features/abayas/screens/abaya_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hullah_app/core/utils/network_helper.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';
import '../providers/abayas_provider.dart';
import '../../measurements/providers/measurements_provider.dart';
import '../../summary/providers/summary_provider.dart';
import '../../../core/widgets/reliable_network_image.dart';
import '../../../core/services/api_service.dart';

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
  bool _isApiAvailable = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbayas();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get current selected abaya IDs from provider
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    if (abayasProvider.selectedAbayaIds.isNotEmpty) {
      setState(() {
        _selectedAbayas = Set<String>.from(abayasProvider.selectedAbayaIds);
      });
    }
    
    // Check if we need to set the active summary ID
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    if (summaryProvider.activeSummaryId != null) {
      abayasProvider.setActiveSummaryId(summaryProvider.activeSummaryId);
    }
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
    
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    
    // Load abayas, strictly from Firestore
    await abayasProvider.loadRecommendedAbayas(
      bodyShape: bodyShape, 
      useFirestoreOnly: true  // Force Firestore
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = abayasProvider.errorMessage;
        _selectedAbayas = Set<String>.from(abayasProvider.selectedAbayaIds);
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
}

  Future<void> _forceRefreshAbayas() async {
    if (_debugMode) {
      print('🔄 Force refreshing abayas');
    }
    
    setState(() {
      _isRetrying = true;
    });
    
    // Reset API status to force a retry with the API
    ApiService.resetApiStatus();
    
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    
    // Clear the cache to force a reload
    abayasProvider.clearCache();
    
    // Get the current body shape
    final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
    final bodyShape = measurementsProvider.bodyShape;
    
    try {
      // Try to load abayas with a forced refresh
      await abayasProvider.retryLoadAbayas(bodyShape: bodyShape);
      
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _errorMessage = abayasProvider.errorMessage;
          _isApiAvailable = ApiService.isApiAvailable;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _errorMessage = e.toString();
          _isApiAvailable = ApiService.isApiAvailable;
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

  @override
  void dispose() {
    // Clean up any controllers or resources here
    super.dispose();
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
      confirmationMessage: 'هل أنت متأكدة من الخروج؟ سيتم فقدان العبايات المختارة',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _isRetrying ? null : _forceRefreshAbayas,
        ),
      ],
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
          
          // API Status indicator
          if (!_isApiAvailable)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[800]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'خادم API غير متاح حالياً. يتم عرض البيانات المحلية.',
                      style: TextStyle(color: Colors.amber[800], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // Error/Debug info section
          if (_errorMessage != null)
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
                    'خطأ:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 4),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _forceRefreshAbayas,
                    icon: _isRetrying 
                        ? SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.refresh),
                    label: Text(_isRetrying ? 'جاري إعادة المحاولة...' : 'إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
                    ),
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
                            onPressed: _forceRefreshAbayas,
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
                        
                        return AbayaCardItem(
                          abaya: abaya,
                          isSelected: isSelected,
                          onTap: () => _toggleSelection(abaya.id),
                          debug: _debugMode,
                          index: index,
                        );
                      },
                    ),
          ),
          
          // Bottom selection bar
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
        // Validate internet connection first
        final hasConnection = await NetworkHelper.hasInternetConnection();
        
        if (!hasConnection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Show a loading indicator
        _showSavingDialog(context);
        
        try {
          final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
          final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
          
          // Validate selected abayas exist in the recommendations
          final selectedAbayas = abayasProvider.recommendedAbayas
              .where((abaya) => _selectedAbayas.contains(abaya.id))
              .toList();
          
          if (selectedAbayas.isEmpty) {
            throw Exception('لم يتم العثور على العبايات المحددة');
          }
          
          // Save selected abayas to summary
          await abayasProvider.saveSelectedAbayasToSummary();
          
          // Update the summary
          await summaryProvider.updateSummary(selectedAbayas: selectedAbayas);
          
          if (mounted) {
            // Dismiss the loading dialog
            Navigator.pop(context);
            
            // Navigate to summary
            context.go('/summary');
          }
        } catch (e) {
          if (mounted) {
            // Dismiss the loading dialog
            Navigator.pop(context);
            
            // Use NetworkHelper to format error for user
            final formattedError = NetworkHelper.formatErrorForUser(e);
            
            // Show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل في حفظ العبايات: $formattedError'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'إغلاق',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
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
  
  void _showSavingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitCircle(color: AppTheme.primaryColor, size: 40),
              SizedBox(height: 16),
              Text('جاري حفظ العبايات المختارة...'),
            ],
          ),
        );
      },
    );
  }
}

// Extracted AbayaCardItem for cleaner code and better encapsulation
class AbayaCardItem extends StatelessWidget {
  final dynamic abaya;
  final bool isSelected;
  final VoidCallback onTap;
  final bool debug;
  final int index;

  const AbayaCardItem({
    Key? key,
    required this.abaya,
    required this.isSelected,
    required this.onTap,
    this.debug = false,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if we have valid data
    final model = abaya.model ?? 'عباية';
    final fabric = abaya.fabric ?? '';
    final color = abaya.color ?? '';
    
    if (debug) {
      print('⚙️ Building abaya card for index $index: $model');
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
                    child: _buildAbayaImage(context),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 18),
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
                    model,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fabric.isNotEmpty || color.isNotEmpty)
                    Text(
                      [if (fabric.isNotEmpty) fabric, if (color.isNotEmpty) color]
                          .join(' - '),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbayaImage(BuildContext context) {
    try {
      if (abaya.accessibleImage1Url == null || abaya.accessibleImage1Url.isEmpty) {
        if (debug) {
          print('⚠️ Empty image URL for abaya at index $index');
        }
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, color: Colors.grey[500], size: 40),
                SizedBox(height: 8),
                Text(
                  'لا توجد صورة',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }
      
      // Use the improved ReliableNetworkImage for better error handling
      return ReliableNetworkImage(
        imageUrl: abaya.accessibleImage1Url ?? abaya.image1Url ?? '',
        altText: abaya.model ?? 'عباية',
        fit: BoxFit.cover,
        showErrors: debug,
        debug: debug,
      );
    } catch (e) {
      if (debug) {
        print('❌ Error building image for abaya at index $index: $e');
      }
      return Container(
        color: Colors.red[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 40),
              SizedBox(height: 8),
              Text(
                'خطأ في تحميل الصورة',
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}