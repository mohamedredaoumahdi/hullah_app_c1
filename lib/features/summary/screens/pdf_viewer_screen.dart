// lib/features/summary/screens/pdf_viewer_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rtl_scaffold.dart';

class PdfViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfFile,
    this.title = 'عرض الملخص',
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    return RTLScaffold(
      title: widget.title,
      showBackButton: true,
      confirmOnBack: false,
      showDrawer: false,
      actions: [
        IconButton(
          icon: Icon(Icons.share),
          onPressed: _sharePdf,
          tooltip: 'مشاركة',
        ),
        IconButton(
          icon: Icon(Icons.print),
          onPressed: _printPdf,
          tooltip: 'طباعة',
        ),
        IconButton(
          icon: Icon(Icons.save_alt),
          onPressed: _savePdf,
          tooltip: 'حفظ',
        ),
      ],
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfFile.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages!;
                _isLoading = false;
              });
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
              _showErrorDialog(error.toString());
            },
            onPageError: (page, error) {
              _showErrorDialog('خطأ في صفحة $page: $error');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              setState(() {
                _pdfViewController = pdfViewController;
              });
            },
            onPageChanged: (int? page, int? total) {
              if (page != null) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
          ),
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 16),
                      Text('جاري تحميل الملف...'),
                    ],
                  ),
                )
              : const SizedBox(),
          if (!_isLoading && _totalPages > 0)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'صفحة ${_currentPage + 1} من $_totalPages',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطأ في عرض الملف'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.pdfFile.path)],
        text: 'ملخص تفصيل العباية',
      );
    } catch (e) {
      _showErrorDialog('فشل في مشاركة الملف: $e');
    }
  }

  Future<void> _printPdf() async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => widget.pdfFile.readAsBytes(),
      );
    } catch (e) {
      _showErrorDialog('فشل في طباعة الملف: $e');
    }
  }

  Future<void> _savePdf() async {
    try {
      // Create a copy in the downloads directory with a readable name
      final downloadDir = await getExternalStorageDirectory();
      if (downloadDir == null) {
        throw Exception('لم يتم العثور على مسار للتنزيل');
      }

      final fileName = 'ملخص_تفصيل_العباية_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await widget.pdfFile.copy('${downloadDir.path}/$fileName');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الملف في: ${savedFile.path}'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'حسناً',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('فشل في حفظ الملف: $e');
    }
  }
}