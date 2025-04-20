import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';

class MeasurementsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _measurements;
  String? _bodyShape;
  double? _userHeight;
  Map<String, dynamic>? _analysisResults;
  
  Map<String, dynamic>? get measurements => _measurements;
  String? get bodyShape => _bodyShape;
  double? get userHeight => _userHeight;
  Map<String, dynamic>? get analysisResults => _analysisResults;
  
  MeasurementsProvider() {
    _loadUserHeight();
    _loadSavedMeasurements();
  }
  
  Future<void> _loadUserHeight() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('Registration').doc(user.uid).get();
      if (doc.exists && doc.data()?['height'] != null) {
        _userHeight = doc.data()!['height'] as double;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user height: $e');
    }
  }
  
  Future<void> _loadSavedMeasurements() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('my measurements').doc(user.uid).get();
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
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
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
      
      await _firestore.collection('my measurements').doc(user.uid).set(data);
      notifyListeners();
    } catch (e) {
      print('Error saving measurements: $e');
      rethrow;
    }
  }
  
  Future<void> saveImageAnalysisResults(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
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
      
      await _firestore.collection('my measurements').doc(user.uid).set(data);
      notifyListeners();
    } catch (e) {
      print('Error saving image analysis results: $e');
      rethrow;
    }
  }
  
  // The calculateBodyShape method is no longer needed as the API handles it
  // Keeping it for backward compatibility if needed
  Future<void> calculateBodyShape() async {
    // This is now handled by the API during measurement processing
    // No action needed here
  }
}