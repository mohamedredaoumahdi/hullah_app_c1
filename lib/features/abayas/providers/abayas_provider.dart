import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/abaya_model.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

class AbayasProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  
  List<AbayaModel> _recommendedAbayas = [];
  Set<String> _selectedAbayaIds = {};
  bool _isLoading = false;
  
  List<AbayaModel> get recommendedAbayas => _recommendedAbayas;
  Set<String> get selectedAbayaIds => _selectedAbayaIds;
  bool get isLoading => _isLoading;
  
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    notifyListeners();
  }
  
  // Load abayas with optional body shape filtering
  Future<void> loadRecommendedAbayas({String? bodyShape}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      QuerySnapshot snapshot;
      
      // If bodyShape is provided, filter by it
      if (bodyShape != null && bodyShape.isNotEmpty) {
        print('Loading abayas for body shape: $bodyShape');
        snapshot = await _firestore
            .collection('Abayas')
            .where('bodyShapeCategory', isEqualTo: bodyShape)
            .get();
            
        // If no results for this body shape, get all abayas
        if (snapshot.docs.isEmpty) {
          print('No abayas found for body shape: $bodyShape. Loading all abayas.');
          snapshot = await _firestore.collection('Abayas').get();
        }
      } else {
        // No body shape filter, get all abayas
        print('Loading all abayas');
        snapshot = await _firestore.collection('Abayas').get();
      }
      
      _recommendedAbayas = snapshot.docs.map((doc) => 
        AbayaModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        })
      ).toList();
      
      print('Loaded ${_recommendedAbayas.length} abayas');
    } catch (e) {
      print('Error loading abayas: $e');
      _recommendedAbayas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<AbayaModel?> getAbayaById(String id) async {
    try {
      // First check cached list
      final cachedAbaya = _recommendedAbayas.firstWhere(
        (abaya) => abaya.id == id,
        orElse: () => AbayaModel(
          id: '',
          model: '',
          fabric: '',
          color: '',
          description: '',
          bodyShapeCategory: '',
          image1Url: ''
        ),
      );
      
      if (cachedAbaya.id.isNotEmpty) {
        return cachedAbaya;
      }
      
      // Otherwise fetch from Firestore
      final doc = await _firestore.collection('Abayas').doc(id).get();
      if (doc.exists) {
        return AbayaModel.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
    } catch (e) {
      print('Error getting abaya by id $id: $e');
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
        final abaya = await getAbayaById(id);
        if (abaya != null) {
          selectedAbayasData.add(abaya.toMap());
        }
      }
      
      await _firestore.collection('my summary').doc(_user!.uid).set({
        'selectedAbayas': selectedAbayasData,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving selected abayas: $e');
      rethrow;
    }
  }
  
  // Method to get user's body shape - could be used if needed
  Future<String?> _getUserBodyShape() async {
    if (_user == null) return null;
    
    try {
      final doc = await _firestore.collection('my measurements').doc(_user!.uid).get();
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