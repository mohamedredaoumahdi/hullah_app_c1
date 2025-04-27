import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

class MeasurementsProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  User? _user;
  
  Map<String, dynamic>? _measurements;
  String? _bodyShape;
  double? _userHeight;
  Map<String, dynamic>? _analysisResults;
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, dynamic>? get measurements => _measurements;
  String? get bodyShape => _bodyShape;
  double? get userHeight => _userHeight;
  Map<String, dynamic>? get analysisResults => _analysisResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  MeasurementsProvider() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print('Error initializing Firebase in MeasurementsProvider: $e');
    }
  }
  
  // This method allows the provider to be updated when auth changes
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    if (_user != null) {
      _loadUserHeight();
      _loadSavedMeasurements();
    } else {
      _measurements = null;
      _bodyShape = null;
      _userHeight = null;
      _analysisResults = null;
    }
    notifyListeners();
  }
  
  Future<void> _loadUserHeight() async {
    if (_user == null || _firestore == null) return;
    
    try {
      final doc = await _firestore!.collection('Registration').doc(_user!.uid).get();
      if (doc.exists && doc.data()?['height'] != null) {
        _userHeight = doc.data()!['height'] is int ? 
          (doc.data()!['height'] as int).toDouble() : doc.data()!['height'] as double;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user height: $e');
    }
  }
  
  Future<void> _loadSavedMeasurements() async {
    if (_user == null || _firestore == null) return;
    
    try {
      final doc = await _firestore!.collection('my measurements').doc(_user!.uid).get();
      if (doc.exists) {
        _measurements = doc.data();
        _bodyShape = doc.data()?['bodyShape'] as String?;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading measurements: $e');
    }
  }
  
  Future<void> saveMeasurements({
    required double chest,
    required double waist,
    required double hips,
    required double shoulder,
    required double armLength,
  }) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final manualMeasurements = {
        'chest': chest,
        'waist': waist,
        'hips': hips,
        'shoulder': shoulder,
        'armLength': armLength,
      };
      
      // Process measurements through API
      final results = await ApiService.processMeasurements(
        userHeightCm: _userHeight ?? 160.0, // Default height if not available
        manualMeasurements: manualMeasurements,
      );
      
      _analysisResults = results;
      _measurements = results['measurements'] as Map<String, dynamic>;
      _bodyShape = results['body_analysis']['type'] as String;
      
      // Save to Firebase
      final data = {
        ...manualMeasurements,
        'height': _userHeight,
        'bodyShape': _bodyShape,
        'analysisConfidence': results['body_analysis']['confidence'],
        'ratios': results['body_analysis']['ratios'],
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore!.collection('my measurements').doc(_user!.uid).set(data);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      print('Error saving measurements: $e');
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> saveImageAnalysisResults(File imageFile) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Process image through API
      final results = await ApiService.processMeasurements(
        userHeightCm: _userHeight ?? 160.0, // Default height if not available
        image: imageFile,
      );
      
      _analysisResults = results;
      _measurements = results['measurements'] as Map<String, dynamic>;
      _bodyShape = results['body_analysis']['type'] as String;
      
      // Save to Firebase
      final data = {
        ..._measurements!,
        'height': _userHeight,
        'source': 'image_analysis',
        'bodyShape': _bodyShape,
        'analysisConfidence': results['body_analysis']['confidence'],
        'ratios': results['body_analysis']['ratios'],
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore!.collection('my measurements').doc(_user!.uid).set(data);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      print('Error saving image analysis results: $e');
      notifyListeners();
      rethrow;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}