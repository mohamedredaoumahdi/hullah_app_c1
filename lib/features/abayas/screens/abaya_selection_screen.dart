import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final Set<String> _selectedAbayas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbayas();
  }

  Future<void> _loadAbayas() async {
    // Get the user's body shape first
    final measurementsProvider = Provider.of<MeasurementsProvider>(context, listen: false);
    final bodyShape = measurementsProvider.bodyShape;
    
    // Then load recommended abayas based on that body shape
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    await abayasProvider.loadRecommendedAbayas(bodyShape: bodyShape);
    
    if (mounted) {
      setState(() => _isLoading = false);
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
  Widget build(BuildContext context) {
    final abayasProvider = Provider.of<AbayasProvider>(context);
    final measurementsProvider = Provider.of<MeasurementsProvider>(context);
    final bodyShape = measurementsProvider.bodyShape;
    
    return RTLScaffold(
      title: 'اختيار العبايات',
      showBackButton: true,
      confirmOnBack: _selectedAbayas.isNotEmpty, // Confirm if abayas selected
      confirmationMessage: 'هل أنت متأكد من الخروج؟ سيتم فقدان العبايات المختارة.',
      actions: [
        if (_selectedAbayas.isNotEmpty)
          TextButton(
            onPressed: () => context.go('/summary'),
            child: Text(
              'التالي',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
      ],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                Expanded(
                  child: abayasProvider.recommendedAbayas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد عبايات متاحة حالياً',
                                style: Theme.of(context).textTheme.bodyLarge,
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: abaya.image1Url,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) {
                                            print('Image error: $error for URL: $url');
                                            return Container(
                                              color: AppTheme.greyColor,
                                              child: Icon(Icons.error, color: Colors.red),
                                            );
                                          },
                                          // Additional headers for potential CORS issues
                                          httpHeaders: {
                                            'Accept': '*/*',
                                          },
                                        ),
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
                              : () => context.go('/summary'),
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
}