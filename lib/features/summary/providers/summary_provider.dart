import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hullah_app/core/utils/pdf_generator.dart';
import 'dart:io';
import '../../abayas/models/abaya_model.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

class SummaryProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  User? _user;
  
  Map<String, dynamic>? _summary;
  List<AbayaModel> _selectedAbayas = [];
  bool _isLoading = false;
  
  Map<String, dynamic>? get summary => _summary;
  List<AbayaModel> get selectedAbayas => _selectedAbayas;
  bool get isLoading => _isLoading;
  
  SummaryProvider() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print('Error initializing Firebase in SummaryProvider: $e');
    }
  }
  
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    if (_user != null) {
      loadSummary();
    } else {
      _summary = null;
      _selectedAbayas = [];
    }
  }
  
  Future<void> loadSummary() async {
    if (_user == null || _firestore == null) return;
    
    try {
      // Avoid calling setState during build
      if (_isLoading) return;
      
      _isLoading = true;
      
      // Fetch summary data
      final summaryDoc = await _firestore!.collection('my summary').doc(_user!.uid).get();
      
      // Parse selected abayas
      final selectedAbayasData = summaryDoc.data()?['selectedAbayas'] as List<dynamic>?;
      if (selectedAbayasData != null) {
        _selectedAbayas = selectedAbayasData
            .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
            .toList();
      }
      
      // Fetch measurements
      final measurementsDoc = await _firestore!.collection('my measurements').doc(_user!.uid).get();
      
      // Fetch profile
      final profileDoc = await _firestore!.collection('Registration').doc(_user!.uid).get();
      
      // Compile summary
      _summary = {
        'measurements': measurementsDoc.data() ?? {},
        'profile': profileDoc.data() ?? {},
        'selectedAbayas': selectedAbayasData ?? [],
      };
      
      _isLoading = false;
      
      // Use a microtask to avoid setState during build
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      print('Error loading summary: $e');
      _isLoading = false;
      Future.microtask(() {
        notifyListeners();
      });
    }
  }
  
  Future<void> updateSummary({
    required List<AbayaModel> selectedAbayas,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      final selectedAbayasData = selectedAbayas.map((abaya) => abaya.toMap()).toList();
      
      final data = {
        'selectedAbayas': selectedAbayasData,
        'timestamp': FieldValue.serverTimestamp(),
        ...?additionalData,
      };
      
      await _firestore!.collection('my summary').doc(_user!.uid).set(
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
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      await _firestore!.collection('my measurements').doc(_user!.uid).update(measurements);
      
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