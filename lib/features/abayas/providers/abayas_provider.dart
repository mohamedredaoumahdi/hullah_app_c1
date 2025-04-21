import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/abaya_model.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

class AbayasProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  User? _user;
  
  List<AbayaModel> _recommendedAbayas = [];
  Set<String> _selectedAbayaIds = {};
  bool _isLoading = false;
  
  List<AbayaModel> get recommendedAbayas => _recommendedAbayas;
  Set<String> get selectedAbayaIds => _selectedAbayaIds;
  bool get isLoading => _isLoading;
  
  AbayasProvider() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print('Error initializing Firebase in AbayasProvider: $e');
    }
  }
  
  // This method allows the provider to be updated when auth changes
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    notifyListeners();
  }
  
  Future<void> loadRecommendedAbayas() async {
    if (_firestore == null) {
      throw Exception('Firebase not initialized');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get user's body shape from MeasurementsProvider
      final bodyShape = await _getUserBodyShape();
      
      if (bodyShape == null) {
        _recommendedAbayas = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get recommendations from API
      final apiRecommendations = await ApiService.recommendAbayas(bodyShape);
      
      // Convert API recommendations to AbayaModel objects
      _recommendedAbayas = await _processApiRecommendations(apiRecommendations);
      
      // If no specific recommendations, load general abayas
      if (_recommendedAbayas.isEmpty) {
        final generalQuery = await _firestore!
            .collection('Abayas')
            .limit(16)
            .get();
        
        _recommendedAbayas = generalQuery.docs
            .map((doc) => AbayaModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();
      }
    } catch (e) {
      print('Error loading abayas: $e');
      _recommendedAbayas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<AbayaModel>> _processApiRecommendations(List<Map<String, dynamic>> recommendations) async {
    if (_firestore == null) return [];
    
    final List<AbayaModel> abayas = [];
    
    for (var recommendation in recommendations) {
      try {
        // Create AbayaModel from API response
        final abaya = AbayaModel(
          id: recommendation['id'].toString(),
          model: recommendation['style'] ?? 'Unknown Model',
          fabric: 'Standard Fabric', // You might want to fetch this from Firebase
          color: 'Default Color', // You might want to fetch this from Firebase
          description: 'Recommended for ${recommendation['body_type']} body type',
          bodyShapeCategory: recommendation['body_type'] ?? '',
          image1Url: _decodeBase64Image(recommendation['image_base64']),
        );
        
        abayas.add(abaya);
        
        // Also save to Firebase for persistence
        await _firestore!.collection('Abayas').doc(abaya.id).set(abaya.toMap(), SetOptions(merge: true));
      } catch (e) {
        print('Error processing recommendation: $e');
      }
    }
    
    return abayas;
  }
  
  String _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return ''; // Return empty string if no image is provided
    }
    
    try {
      // If the base64 string doesn't start with a data URI scheme, add it
      if (!base64String.startsWith('data:image')) {
        return 'data:image/jpeg;base64,$base64String';
      }
      return base64String;
    } catch (e) {
      print('Error decoding base64 image: $e');
      return '';
    }
  }
  
  Future<AbayaModel?> getAbayaById(String id) async {
    if (_firestore == null) return null;
    
    try {
      final doc = await _firestore!.collection('Abayas').doc(id).get();
      if (doc.exists) {
        return AbayaModel.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
    } catch (e) {
      print('Error getting abaya: $e');
    }
    return null;
  }
  
  void updateSelectedAbayas(Set<String> selectedIds) {
    _selectedAbayaIds = selectedIds;
    notifyListeners();
  }
  
  Future<void> saveSelectedAbayasToSummary() async {
    if (_user == null || _firestore == null) return;
    
    try {
      final List<Map<String, dynamic>> selectedAbayasData = [];
      
      for (final id in _selectedAbayaIds) {
        final abaya = _recommendedAbayas.firstWhere((a) => a.id == id);
        selectedAbayasData.add(abaya.toMap());
      }
      
      await _firestore!.collection('my summary').doc(_user!.uid).set({
        'selectedAbayas': selectedAbayasData,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving selected abayas: $e');
      rethrow;
    }
  }
  
  Future<String?> _getUserBodyShape() async {
    if (_user == null || _firestore == null) return null;
    
    try {
      final doc = await _firestore!.collection('my measurements').doc(_user!.uid).get();
      if (doc.exists && doc.data()?['bodyShape'] != null) {
        return doc.data()!['bodyShape'] as String;
      }
    } catch (e) {
      print('Error getting user body shape: $e');
    }
    return null;
  }
  
  void clearSelection() {
    _selectedAbayaIds.clear();
    notifyListeners();
  }
}