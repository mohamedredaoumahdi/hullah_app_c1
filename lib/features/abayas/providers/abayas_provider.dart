// lib/features/abayas/providers/abayas_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/abaya_model.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;
import '../../../core/services/api_service.dart';

class AbayasProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  
  List<AbayaModel> _recommendedAbayas = [];
  Set<String> _selectedAbayaIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _debugMode = true; // Enable debug mode
  
  // Cache management
  bool _hasApiDataCache = false;
  String? _cachedBodyShape;
  
  List<AbayaModel> get recommendedAbayas => _recommendedAbayas;
  Set<String> get selectedAbayaIds => _selectedAbayaIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    notifyListeners();
  }
  
  // Load abayas with optional body shape filtering
  Future<void> loadRecommendedAbayas({String? bodyShape}) async {
    // If we already have API data cached for this body shape, use it
    if (_hasApiDataCache && _recommendedAbayas.isNotEmpty && 
        bodyShape != null && _cachedBodyShape == bodyShape) {
      if (_debugMode) {
        print('📦 Using cached abayas data for body shape: $bodyShape');
      }
      // Just notify listeners that we're using cached data
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify listeners to show loading state
    
    try {
      if (_debugMode) {
        print('⚙️ Loading abayas for body shape: $bodyShape');
        print('🔍 User ID: ${_user?.uid}');
        print('🔍 Body shape filter: $bodyShape');
      }
      
      if (bodyShape != null && bodyShape.isNotEmpty) {
        print('Loading abayas for body shape: $bodyShape');
        
        // First try to get recommendations from the API
        try {
          if (_debugMode) print('🔍 Attempting to get recommendations from API...');
          
          final recommendations = await ApiService.recommendAbayas(bodyShape);
          
          if (_debugMode) {
            print('🔍 API returned ${recommendations.length} recommendations');
            if (recommendations.isNotEmpty) {
              print('🔍 First API recommendation: ${recommendations[0]}');
            }
          }
          
          if (recommendations.isNotEmpty) {
            // Process and create AbayaModel objects
            _recommendedAbayas = recommendations.map((rec) {
              // Get the image URL directly without creating additional prefixes
              String imageUrl = rec['image_base64'] ?? '';
                            
              // Create AbayaModel with the correct URL
              final model = AbayaModel(
                id: rec['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                model: rec['style'] ?? 'Style ${rec['id'] ?? ''}',
                fabric: 'Premium Fabric', // Default values
                color: 'Black', // Default values
                description: rec['description'] ?? '',
                bodyShapeCategory: rec['body_type'] ?? bodyShape,
                image1Url: imageUrl,
              );
              
              if (_debugMode) {
                print('🔍 Created AbayaModel from API data:');
                print('🔍 ID: ${model.id}, Model: ${model.model}');
                
                // Just print a short preview of the image URL to avoid flooding logs
                final imagePreview = imageUrl.length > 50 ? 
                  imageUrl.substring(0, 50) + '...' : 
                  imageUrl;
                print('🔍 Image URL: $imagePreview');
              }
              
              return model;
            }).toList();
            
            // Set the cache flag and remember the body shape
            _hasApiDataCache = true;
            _cachedBodyShape = bodyShape;
            
            if (_debugMode) {
              print('📦 Caching API data for body shape: $bodyShape');
              print('✅ Successfully loaded ${_recommendedAbayas.length} abayas from API');
            }
            
            _isLoading = false;
            notifyListeners();
            return;
          }
        } catch (apiError) {
          if (_debugMode) {
            print('❌ Error from API: $apiError');
            print('🔍 Falling back to Firestore');
          }
          // If API fails, we'll fall back to Firestore
        }
        
        // Fallback to Firestore if API didn't work
        if (_debugMode) print('🔍 Querying Firestore for body shape: $bodyShape');
        
        try {
          QuerySnapshot snapshot = await _firestore
              .collection('Abayas')
              .where('bodyShapeCategory', isEqualTo: bodyShape)
              .get();
              
          if (_debugMode) {
            print('🔍 Firestore returned ${snapshot.docs.length} documents for body shape: $bodyShape');
          }
          
          // If no results for this body shape, get all abayas
          if (snapshot.docs.isEmpty) {
            if (_debugMode) {
              print('🔍 No abayas found for body shape: $bodyShape. Loading all abayas.');
            }
            
            snapshot = await _firestore.collection('Abayas').get();
            
            if (_debugMode) {
              print('🔍 Firestore returned ${snapshot.docs.length} total abayas');
            }
          }
          
          // Process Firestore results
          _processFirestoreResults(snapshot);
          
          // If Firestore succeeded, cache the body shape
          _cachedBodyShape = bodyShape;
          
        } catch (firestoreError) {
          if (_debugMode) {
            print('❌ Firestore query error: $firestoreError');
          }
          throw firestoreError; // Rethrow to be caught by outer try/catch
        }
      } else {
        // No body shape filter, get all abayas
        if (_debugMode) print('🔍 No body shape filter, loading all abayas');
        
        try {
          final snapshot = await _firestore.collection('Abayas').get();
          
          if (_debugMode) {
            print('🔍 Firestore returned ${snapshot.docs.length} total abayas');
          }
          
          // Process Firestore results
          _processFirestoreResults(snapshot);
          
        } catch (firestoreError) {
          if (_debugMode) {
            print('❌ Firestore query error: $firestoreError');
          }
          throw firestoreError; // Rethrow to be caught by outer try/catch
        }
      }
      
    } catch (e) {
      if (_debugMode) {
        print('❌ Error in loadRecommendedAbayas: $e');
      }
      
      _errorMessage = e.toString();
      _recommendedAbayas = [];
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper to process Firestore query results
  void _processFirestoreResults(QuerySnapshot snapshot) {
    try {
      if (_debugMode) {
        print('🔍 Processing ${snapshot.docs.length} Firestore documents');
      }
      
      _recommendedAbayas = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (_debugMode) {
          print('🔍 Processing document ID: ${doc.id}');
          print('🔍 Document data keys: ${data.keys.join(', ')}');
          
          // Check for important fields
          if (!data.containsKey('model')) print('⚠️ Missing "model" field in document ${doc.id}');
          if (!data.containsKey('image1Url')) print('⚠️ Missing "image1Url" field in document ${doc.id}');
          if (!data.containsKey('bodyShapeCategory')) print('⚠️ Missing "bodyShapeCategory" field in document ${doc.id}');
          
          // Log image URL if available
          if (data.containsKey('image1Url')) {
            final url = data['image1Url'] as String? ?? '';
            print('🔍 Image URL for ${doc.id}: ${url.substring(0, min(url.length, 50))}...');
          }
        }
        
        // Create AbayaModel with error handling
        try {
          return AbayaModel.fromMap({
            'id': doc.id,
            ...data,
          });
        } catch (parseError) {
          if (_debugMode) {
            print('❌ Error parsing document ${doc.id}: $parseError');
            print('❌ Document data: $data');
          }
          
          // Return a placeholder model instead of throwing
          return AbayaModel(
            id: doc.id,
            model: 'Error: ${parseError.toString().substring(0, min(parseError.toString().length, 20))}...',
            fabric: 'Error',
            color: 'Error',
            description: 'Error loading abaya data',
            bodyShapeCategory: 'Unknown',
            image1Url: 'https://via.placeholder.com/300?text=Error',
          );
        }
      }).toList();
      
      if (_debugMode) {
        print('✅ Successfully processed ${_recommendedAbayas.length} abayas from Firestore');
        
        // Log the first few abayas for debugging
        for (int i = 0; i < min(_recommendedAbayas.length, 3); i++) {
          final abaya = _recommendedAbayas[i];
          print('🔍 Abaya $i: ID=${abaya.id}, Model=${abaya.model}');
          print('🔍 Image: ${abaya.image1Url.substring(0, min(abaya.image1Url.length, 50))}...');
        }
      }
      
    } catch (e) {
      if (_debugMode) {
        print('❌ Error in _processFirestoreResults: $e');
      }
      throw e; // Rethrow to be caught by outer try/catch
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<AbayaModel?> getAbayaById(String id) async {
    if (_debugMode) {
      print('🔍 Getting abaya by ID: $id');
    }
    
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
        if (_debugMode) {
          print('✅ Found abaya in cache: ${cachedAbaya.id}');
        }
        return cachedAbaya;
      }
      
      // Otherwise fetch from Firestore
      if (_debugMode) {
        print('🔍 Abaya not in cache, fetching from Firestore');
      }
      
      final doc = await _firestore.collection('Abayas').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        
        if (_debugMode) {
          print('✅ Found abaya in Firestore: ${doc.id}');
          print('🔍 Document data keys: ${data.keys.join(', ')}');
        }
        
        return AbayaModel.fromMap({
          'id': doc.id,
          ...data,
        });
      } else {
        if (_debugMode) {
          print('❌ Abaya not found in Firestore: $id');
        }
        return null;
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error getting abaya by id $id: $e');
      }
      return null;
    }
  }
  
  void updateSelectedAbayas(Set<String> selectedIds) {
    if (_debugMode) {
      print('🔍 Updating selected abayas: ${selectedIds.join(', ')}');
    }
    
    _selectedAbayaIds = selectedIds;
    notifyListeners();
  }
  
  Future<void> saveSelectedAbayasToSummary() async {
    if (_user == null) {
      if (_debugMode) {
        print('❌ Cannot save selected abayas: User is null');
      }
      return;
    }
    
    if (_debugMode) {
      print('🔍 Saving selected abayas to summary for user: ${_user!.uid}');
      print('🔍 Selected abaya IDs: ${_selectedAbayaIds.join(', ')}');
    }
    
    try {
      final List<Map<String, dynamic>> selectedAbayasData = [];
      
      for (final id in _selectedAbayaIds) {
        final abaya = await getAbayaById(id);
        if (abaya != null) {
          selectedAbayasData.add(abaya.toMap());
        }
      }
      
      if (_debugMode) {
        print('🔍 Prepared ${selectedAbayasData.length} abaya objects for saving');
      }
      
      await _firestore.collection('my summary').doc(_user!.uid).set({
        'selectedAbayas': selectedAbayasData,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (_debugMode) {
        print('✅ Successfully saved selected abayas to Firestore');
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error saving selected abayas: $e');
      }
      throw e;
    }
  }
  
  // Clear the cache to force a reload of data
  void clearCache() {
    _hasApiDataCache = false;
    _cachedBodyShape = null;
    if (_debugMode) {
      print('📦 Abaya data cache cleared');
    }
  }
  
  void clearSelection() {
    if (_debugMode) {
      print('🔍 Clearing selected abayas');
    }
    
    _selectedAbayaIds.clear();
    notifyListeners();
  }
  
  void clearError() {
    if (_debugMode) {
      print('🔍 Clearing error message');
    }
    
    _errorMessage = null;
    notifyListeners();
  }
  
  // Helper function for min
  int min(int a, int b) => a < b ? a : b;
}