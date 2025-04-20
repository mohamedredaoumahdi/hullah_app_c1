import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/abayas_provider.dart';
import '../models/abaya_model.dart';

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
    final abayasProvider = Provider.of<AbayasProvider>(context, listen: false);
    await abayasProvider.loadRecommendedAbayas();
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
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('اختيار العبايات'),
        centerTitle: true,
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'اختاري العبايات المناسبة لشكل جسمك',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
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
                                  child: abaya.image1Url.startsWith('data:image')
                                      ? Image.memory(
                                          Uri.parse(abaya.image1Url.split(',')[1]).data!.contentAsBytes(),
                                          fit: BoxFit.cover,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: abaya.image1Url,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: AppTheme.greyColor,
                                            child: Icon(Icons.error, color: Colors.red),
                                          ),
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