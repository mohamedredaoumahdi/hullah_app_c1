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
  String? _errorMessage;
  bool _debugMode = true; // Set to false in production
  
  Map<String, dynamic>? get summary => _summary;
  List<AbayaModel> get selectedAbayas => _selectedAbayas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  SummaryProvider() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error initializing Firebase in SummaryProvider: $e');
      }
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
      notifyListeners();
      
      if (_debugMode) {
        print('🔍 SummaryProvider: Loading summary for user: ${_user!.uid}');
      }
      
      // First check for selected abayas in the summary collection
      final summaryDoc = await _firestore!.collection('my summary').doc(_user!.uid).get();
      
      if (_debugMode) {
        print('🔍 Summary document exists: ${summaryDoc.exists}');
        if (summaryDoc.exists && summaryDoc.data() != null) {
          print('🔍 Summary document fields: ${summaryDoc.data()!.keys.join(', ')}');
        }
      }
      
      // Parse selected abayas
      final selectedAbayasData = summaryDoc.data()?['selectedAbayas'] as List<dynamic>?;
      
      if (_debugMode && selectedAbayasData != null) {
        print('🔍 Selected abayas count in Firestore: ${selectedAbayasData.length}');
      }
      
      if (selectedAbayasData != null) {
        _selectedAbayas = selectedAbayasData
            .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
            .toList();
            
        if (_debugMode) {
          print('🔍 Loaded ${_selectedAbayas.length} selected abayas');
          for (var abaya in _selectedAbayas) {
            print('🔍 Loaded abaya: ID=${abaya.id}, Model=${abaya.model}');
          }
        }
      } else {
        // If no selected abayas in summary, try looking in the abayas provider
        // (This would be handled in the abayas provider)
        if (_debugMode) {
          print('⚠️ No selected abayas found in summary document');
        }
        _selectedAbayas = [];
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
      notifyListeners();
      
      if (_debugMode) {
        print('✅ Summary loaded successfully');
        print('🔍 Selected abayas in provider: ${_selectedAbayas.length}');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error loading summary: $e');
      }
      
      notifyListeners();
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
      if (_debugMode) {
        print('🔍 Updating summary with ${selectedAbayas.length} abayas');
        for (var abaya in selectedAbayas) {
          print('🔍 Updating abaya: ID=${abaya.id}, Model=${abaya.model}');
        }
      }
      
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
      
      if (_debugMode) {
        print('✅ Summary updated successfully');
        print('🔍 Selected abayas after update: ${_selectedAbayas.length}');
      }
      
      notifyListeners();
    } catch (e) {
      if (_debugMode) {
        print('❌ Error updating summary: $e');
      }
      
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }
  
  Future<void> updateMeasurements(Map<String, dynamic> measurements) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      if (_debugMode) {
        print('🔍 Updating measurements: ${measurements.keys.join(', ')}');
      }
      
      await _firestore!.collection('my measurements').doc(_user!.uid).update(measurements);
      
      _summary = {
        ..._summary ?? {},
        'measurements': {
          ..._summary?['measurements'] ?? {},
          ...measurements,
        },
      };
      
      if (_debugMode) {
        print('✅ Measurements updated successfully');
      }
      
      notifyListeners();
    } catch (e) {
      if (_debugMode) {
        print('❌ Error updating measurements: $e');
      }
      
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }
  
  Future<File> generatePDF() async {
    if (_summary == null) {
      throw Exception('No summary data available');
    }
    
    if (_debugMode) {
      print('🔍 Generating PDF with ${_selectedAbayas.length} abayas');
    }
    
    try {
      final file = await PdfGenerator.generateSummaryPdf(
        summary: _summary!,
        selectedAbayas: _selectedAbayas,
      );
      
      if (_debugMode) {
        print('✅ PDF generated successfully: ${file.path}');
      }
      
      return file;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error generating PDF: $e');
      }
      
      throw e;
    }
  }
  
  void clearSummary() {
    _summary = null;
    _selectedAbayas = [];
    notifyListeners();
    
    if (_debugMode) {
      print('🔍 Summary cleared');
    }
  }
  
  // Debug method to check the selected abayas
  void debugSelectedAbayas() {
    if (!_debugMode) return;
    
    print("🛑 SUMMARY PROVIDER DEBUG 🛑");
    print("🛑 Total Selected Abayas: ${_selectedAbayas.length}");
    
    if (_selectedAbayas.isEmpty) {
      print("🛑 No abayas selected!");
    } else {
      for (int i = 0; i < _selectedAbayas.length; i++) {
        final abaya = _selectedAbayas[i];
        print("🛑 Abaya $i: ID=${abaya.id}, Model=${abaya.model}");
        print("🛑 Image URL: ${abaya.image1Url}");
        print("🛑 Accessible Image URL: ${abaya.accessibleImage1Url}");
      }
    }
    
    if (_summary != null && _summary!.containsKey('selectedAbayas')) {
      final List? rawList = _summary!['selectedAbayas'] as List?;
      print("🛑 Selected Abayas in summary data: ${rawList?.length ?? 0}");
    }
    
    // Check the user ID
    print("🛑 Current User ID: ${_user?.uid ?? 'No user logged in'}");
    
    // Check the loading state
    print("🛑 Is Loading: $_isLoading");
    
    // Check for error message
    print("🛑 Error Message: ${_errorMessage ?? 'No error'}");
  }
}