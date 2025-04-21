import 'package:flutter/services.dart' show rootBundle;
import 'package:hullah_app/features/abayas/models/abaya_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<File> generateSummaryPdf({
    required Map<String, dynamic> summary,
    required List<AbayaModel> selectedAbayas,
  }) async {
    final pdf = pw.Document();
    
    // Load Arabic font
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    final arabicBoldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
    
    // Create pages
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'تفصيل العباية',
                  style: pw.TextStyle(
                    font: arabicBoldFont,
                    fontSize: 24,
                    color: PdfColors.pink,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.pink),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.pink),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تاريخ الإصدار: ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'ملخص الطلب',
              style: pw.TextStyle(
                font: arabicBoldFont,
                fontSize: 26,
                color: PdfColors.pink,
              ),
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Customer Information Section
          _buildSectionHeader('معلومات العميلة', arabicBoldFont),
          pw.SizedBox(height: 10),
          _buildInfoCard(
            summary['profile'] ?? {},
            [
              {'الاسم': summary['profile']?['name'] ?? ''},
              {'رقم الهاتف': summary['profile']?['phone'] ?? ''},
              {'الطول': '${summary['profile']?['height']?.toString() ?? ''} سم'},
            ],
            arabicFont,
            arabicBoldFont,
          ),
          pw.SizedBox(height: 30),
          
          // Measurements Section
          _buildSectionHeader('القياسات', arabicBoldFont),
          pw.SizedBox(height: 10),
          _buildMeasurementsTable(summary['measurements'] ?? {}, arabicFont, arabicBoldFont),
          pw.SizedBox(height: 30),
          
          // Selected Abayas Section
          _buildSectionHeader('العبايات المختارة', arabicBoldFont),
          pw.SizedBox(height: 10),
          ...selectedAbayas.map((abaya) => _buildAbayaCard(abaya, arabicFont, arabicBoldFont)),
          
          // Footer Message
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'شكراً لاختيارك تفصيل العباية',
              style: pw.TextStyle(
                font: arabicBoldFont,
                fontSize: 18,
                color: PdfColors.pink,
              ),
            ),
          ),
        ],
      ),
    );
    
    // Save PDF
    final output = await getTemporaryDirectory();
    final fileName = 'summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    // Upload to Firebase Storage (optional)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('summaries')
            .child(user.uid)
            .child(fileName);
        await ref.putFile(file);
      }
    } catch (e) {
      print('Error uploading PDF to Firebase: $e');
    }
    
    return file;
  }
  
  static pw.Widget _buildSectionHeader(String title, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.pink50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: font,
          fontSize: 18,
          color: PdfColors.pink,
        ),
      ),
    );
  }
  
  static pw.Widget _buildInfoCard(
    Map<String, dynamic> data,
    List<Map<String, String>> fields,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: fields.map((field) {
          final key = field.keys.first;
          final value = field.values.first;
          return pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  value,
                  style: pw.TextStyle(font: regularFont, fontSize: 14),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  '$key:',
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  static pw.Widget _buildMeasurementsTable(
    Map<String, dynamic> measurements,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final measurementsList = [
      {'محيط الصدر': '${measurements['chest']?.toString() ?? ''} سم'},
      {'محيط الخصر': '${measurements['waist']?.toString() ?? ''} سم'},
      {'محيط الأرداف': '${measurements['hips']?.toString() ?? ''} سم'},
      {'عرض الكتفين': '${measurements['shoulder']?.toString() ?? ''} سم'},
      {'طول الذراع': '${measurements['armLength']?.toString() ?? ''} سم'},
      {'شكل الجسم': measurements['bodyShape']?.toString() ?? ''},
    ];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: measurementsList.map((measurement) {
        final key = measurement.keys.first;
        final value = measurement.values.first;
        return pw.TableRow(
          children: [
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(
                value,
                style: pw.TextStyle(font: regularFont, fontSize: 14),
              ),
            ),
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              color: PdfColors.grey100,
              child: pw.Text(
                key,
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  static pw.Widget _buildAbayaCard(
    AbayaModel abaya,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.pink100),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            abaya.model,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: PdfColors.pink,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildAbayaInfoRow('القماش', abaya.fabric, regularFont, boldFont),
          _buildAbayaInfoRow('اللون', abaya.color, regularFont, boldFont),
          _buildAbayaInfoRow('شكل الجسم المناسب', abaya.bodyShapeCategory, regularFont, boldFont),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              abaya.description,
              style: pw.TextStyle(font: regularFont, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildAbayaInfoRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 14),
          ),
          pw.Text(
            ' : ',
            style: pw.TextStyle(font: regularFont, fontSize: 14),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  static String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'ar');
    return formatter.format(date);
  }
}