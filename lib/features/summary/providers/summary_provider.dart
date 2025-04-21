import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hullah_app/core/utils/pdf_generator.dart';
import 'dart:io';
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
    if (_summary == null) {
      throw Exception('No summary data available');
    }
    
    return await PdfGenerator.generateSummaryPdf(
      summary: _summary!,
      selectedAbayas: _selectedAbayas,
    );
  }
  
  void clearSummary() {
    _summary = null;
    _selectedAbayas = [];
    notifyListeners();
  }
}