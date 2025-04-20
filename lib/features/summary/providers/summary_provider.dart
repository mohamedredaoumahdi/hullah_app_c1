import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../abayas/models/abaya_model.dart';

class SummaryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _summary;
  List<AbayaModel> _selectedAbayas = [];
  bool _isLoading = false;
  
  Map<String, dynamic>? get summary => _summary;
  List<AbayaModel> get selectedAbayas => _selectedAbayas;
  bool get isLoading => _isLoading;
  
  Future<void> loadSummary() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load summary data
      final summaryDoc = await _firestore.collection('my summary').doc(user.uid).get();
      if (summaryDoc.exists) {
        _summary = summaryDoc.data();
        
        // Parse selected abayas
        final selectedAbayasData = summaryDoc.data()?['selectedAbayas'] as List<dynamic>?;
        if (selectedAbayasData != null) {
          _selectedAbayas = selectedAbayasData
              .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
              .toList();
        }
      }
      
      // Load measurements
      final measurementsDoc = await _firestore.collection('my measurements').doc(user.uid).get();
      if (measurementsDoc.exists) {
        _summary = {
          ..._summary ?? {},
          'measurements': measurementsDoc.data(),
        };
      }
      
      // Load user profile
      final profileDoc = await _firestore.collection('Registration').doc(user.uid).get();
      if (profileDoc.exists) {
        _summary = {
          ..._summary ?? {},
          'profile': profileDoc.data(),
        };
      }
    } catch (e) {
      print('Error loading summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateSummary({
    required List<AbayaModel> selectedAbayas,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final selectedAbayasData = selectedAbayas.map((abaya) => abaya.toMap()).toList();
      
      final data = {
        'selectedAbayas': selectedAbayasData,
        'timestamp': FieldValue.serverTimestamp(),
        ...?additionalData,
      };
      
      await _firestore.collection('my summary').doc(user.uid).set(
        data,
        SetOptions(merge: true),
      );
      
      _selectedAbayas = selectedAbayas;
      _summary = {
        ..._summary ?? {},
        ...data,
      };
      notifyListeners();
    } catch (e) {
      print('Error updating summary: $e');
      rethrow;
    }
  }
  
  Future<void> updateMeasurements(Map<String, dynamic> measurements) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('my measurements').doc(user.uid).update(measurements);
      
      _summary = {
        ..._summary ?? {},
        'measurements': {
          ..._summary?['measurements'] ?? {},
          ...measurements,
        },
      };
      notifyListeners();
    } catch (e) {
      print('Error updating measurements: $e');
      rethrow;
    }
  }
  
  Future<File> generatePDF() async {
    final pdf = pw.Document();
    
    // Configure Arabic text
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    final arabicBoldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
    
    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Center(
              child: pw.Text(
                'ملخص العبايات المختارة',
                style: pw.TextStyle(
                  fontSize: 24,
                  font: arabicBoldFont,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          
          // User Information
          pw.Header(
            level: 1,
            child: pw.Text(
              'معلومات العميلة',
              style: pw.TextStyle(
                fontSize: 18,
                font: arabicBoldFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'الاسم: ${_summary?['profile']?['name'] ?? ''}',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'رقم الهاتف: ${_summary?['profile']?['phone'] ?? ''}',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'الطول: ${_summary?['profile']?['height']?.toString() ?? ''} سم',
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Measurements
          pw.Header(
            level: 1,
            child: pw.Text(
              'القياسات',
              style: pw.TextStyle(
                fontSize: 18,
                font: arabicBoldFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'محيط الصدر: ${_summary?['measurements']?['chest']?.toString() ?? ''} سم',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'محيط الخصر: ${_summary?['measurements']?['waist']?.toString() ?? ''} سم',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'محيط الأرداف: ${_summary?['measurements']?['hips']?.toString() ?? ''} سم',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'عرض الكتفين: ${_summary?['measurements']?['shoulder']?.toString() ?? ''} سم',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'طول الذراع: ${_summary?['measurements']?['armLength']?.toString() ?? ''} سم',
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'شكل الجسم: ${_summary?['measurements']?['bodyShape'] ?? ''}',
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(font: arabicBoldFont),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Selected Abayas
          pw.Header(
            level: 1,
            child: pw.Text(
              'العبايات المختارة',
              style: pw.TextStyle(
                fontSize: 18,
                font: arabicBoldFont,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          ..._selectedAbayas.map((abaya) => pw.Container(
            margin: pw.EdgeInsets.symmetric(vertical: 10),
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'الموديل: ${abaya.model}',
                      style: pw.TextStyle(font: arabicBoldFont),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'القماش: ${abaya.fabric}',
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'اللون: ${abaya.color}',
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'الوصف: ${abaya.description}',
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
    
    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/summary.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  void clearSummary() {
    _summary = null;
    _selectedAbayas = [];
    notifyListeners();
  }
}