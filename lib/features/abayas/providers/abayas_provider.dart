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
  
  // Retry mechanism
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  // Cache management
  bool _hasApiDataCache = false;
  String? _cachedBodyShape;
  String? _activeSummaryId; // ID of the active summary document
  
  List<AbayaModel> get recommendedAbayas => _recommendedAbayas;
  Set<String> get selectedAbayaIds => _selectedAbayaIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get retryCount => _retryCount;
  
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    notifyListeners();
  }
  
  // Set the active summary ID for context
  void setActiveSummaryId(String? summaryId) {
    if (_activeSummaryId != summaryId) {
      _activeSummaryId = summaryId;
      
      if (_debugMode) {
        print('🔍 Abayas Provider: Set active summary ID: $summaryId');
      }
    }
  }
  
  Future<void> loadRecommendedAbayas({
    String? bodyShape, 
    bool forceRefresh = false, 
    bool useFirestoreOnly = false
  }) async {
    if (_debugMode) {
      print('🔍 Starting loadRecommendedAbayas');
      print('🔍 Body Shape: $bodyShape');
      print('🔍 Use Firestore Only: $useFirestoreOnly');
    }

    _isLoading = true;
    _errorMessage = null;
    _recommendedAbayas.clear(); // Clear previous results
    notifyListeners();
    
    try {
      QuerySnapshot? firestoreSnapshot;
      
      // Try to get Firestore data
      try {
        if (bodyShape != null && bodyShape.isNotEmpty) {
          firestoreSnapshot = await _firestore
              .collection('Abayas')
              .where('bodyShapeCategory', isEqualTo: bodyShape)
              .get();
          
          if (_debugMode) {
            print('🔍 Firestore query for body shape: Found ${firestoreSnapshot.docs.length} documents');
          }
        }
        
        // If no specific body shape results, get all abayas
        if (firestoreSnapshot == null || firestoreSnapshot.docs.isEmpty) {
          firestoreSnapshot = await _firestore.collection('Abayas').get();
          
          if (_debugMode) {
            print('🔍 Falling back to all Abayas: Found ${firestoreSnapshot.docs.length} documents');
          }
        }
        
        // Process Firestore results
        if (firestoreSnapshot.docs.isNotEmpty) {
          _processFirestoreResults(firestoreSnapshot);
          
          if (_debugMode) {
            print('✅ Successfully loaded ${_recommendedAbayas.length} abayas from Firestore');
          }
          
          _hasApiDataCache = true;
          _cachedBodyShape = bodyShape;
          _retryCount = 0;
        } else if (useFirestoreOnly) {
          throw Exception('No Firestore data found');
        }
      } catch (firestoreError) {
        if (_debugMode) {
          print('❌ Firestore query error: $firestoreError');
        }
        
        if (useFirestoreOnly) {
          throw firestoreError; // Propagate error if forced to use only Firestore
        }
      }
      
      // If Firestore is empty and not forced to use only Firestore, try API
      if (_recommendedAbayas.isEmpty && !useFirestoreOnly) {
        try {
          final recommendations = await ApiService.recommendAbayas(bodyShape ?? '');
          
          if (recommendations.isNotEmpty) {
            _recommendedAbayas = recommendations.map((rec) {
              return AbayaModel(
                id: rec['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                model: rec['style'] ?? 'Style ${rec['id'] ?? ''}',
                fabric: 'Premium Fabric',
                color: 'Black',
                description: rec['description'] ?? '',
                bodyShapeCategory: rec['body_type'] ?? bodyShape,
                image1Url: rec['image_base64'] ?? '',
              );
            }).toList();
            
            if (_debugMode) {
              print('✅ Loaded ${_recommendedAbayas.length} abayas from API');
            }
          }
        } catch (apiError) {
          if (_debugMode) {
            print('❌ API error: $apiError');
          }
          _errorMessage = apiError.toString();
        }
      }
      
      // Final check for empty results
      if (_recommendedAbayas.isEmpty) {
        _errorMessage = 'No abayas found';
        if (_debugMode) {
          print('❌ No abayas found from any source');
        }
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Unexpected error in loadRecommendedAbayas: $e');
      }
      
      _errorMessage = e.toString();
      _recommendedAbayas.clear();
    } finally {
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
      
      _retryCount++;
      if (_retryCount < _maxRetries) {
        if (_debugMode) {
          print('🔄 Retry attempt $_retryCount for getting abaya');
        }
        
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: 2 * _retryCount));
        
        // Try again
        return getAbayaById(id);
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
  
  // Update to AbayasProvider.saveSelectedAbayasToSummary method

Future<void> saveSelectedAbayasToSummary() async {
  if (_user == null || _firestore == null) {
    if (_debugMode) {
      print('❌ Cannot save selected abayas: User is null or Firestore not initialized');
    }
    throw Exception('User not authenticated or Firestore not initialized');
  }
  
  // Reset retry count at the start of the method
  _retryCount = 0;
  
  if (_debugMode) {
    print('🔍 Saving selected abayas to summary for user: ${_user!.uid}');
    print('🔍 Selected abaya IDs: ${_selectedAbayaIds.join(', ')}');
    print('🔍 Active summary ID: $_activeSummaryId');
  }
  
  try {
    final List<Map<String, dynamic>> selectedAbayasData = [];
    
    for (final id in _selectedAbayaIds) {
      final abaya = await getAbayaById(id);
      if (abaya != null) {
        selectedAbayasData.add(abaya.toMap());
      } else {
        if (_debugMode) {
          print('⚠️ Abaya with ID $id not found');
        }
      }
    }
    
    if (selectedAbayasData.isEmpty) {
      if (_debugMode) {
        print('⚠️ No valid abayas to save');
      }
      throw Exception('No valid abayas found to save');
    }
    
    if (_debugMode) {
      print('🔍 Prepared ${selectedAbayasData.length} abaya objects for saving');
    }
    
    // Ensure we have a summary ID
    if (_activeSummaryId == null) {
      _activeSummaryId = DateTime.now().millisecondsSinceEpoch.toString();
      if (_debugMode) {
        print('🔍 Generated new active summary ID: $_activeSummaryId');
      }
    }
    
    // First get the current document
    final docRef = _firestore.collection('my summary').doc(_user!.uid);
    final docSnapshot = await docRef.get();
    
    final currentTimestamp = DateTime.now().toUtc().toIso8601String();
    
    if (docSnapshot.exists) {
      final data = docSnapshot.data() ?? {};
      List<dynamic> summaries = List.from(data['summaries'] ?? []);
      
      // Find the index of the existing summary with this ID
      final existingIndex = summaries.indexWhere((s) => s['id'] == _activeSummaryId);
      
      if (existingIndex >= 0) {
        // Update the existing summary
        final updatedSummary = {
          ...summaries[existingIndex] as Map<String, dynamic>,
          'selectedAbayas': selectedAbayasData,
          'timestamp': currentTimestamp,
        };
        
        summaries[existingIndex] = updatedSummary;
      } else {
        // Create a new summary if not found
        final newSummary = {
          'id': _activeSummaryId,
          'userId': _user!.uid,
          'selectedAbayas': selectedAbayasData,
          'timestamp': currentTimestamp,
        };
        
        summaries.add(newSummary);
      }
      
      // Update the document with the updated summaries array
      await docRef.update({
        'summaries': summaries,
        'timestamp': currentTimestamp,
      });
      
      if (_debugMode) {
        print('✅ Successfully saved selected abayas to existing summary document');
      }
    } else {
      // Create a new document with the summary
      await docRef.set({
        'userId': _user!.uid,
        'summaries': [
          {
            'id': _activeSummaryId,
            'userId': _user!.uid,
            'selectedAbayas': selectedAbayasData,
            'timestamp': currentTimestamp,
          }
        ],
        'timestamp': currentTimestamp,
      });
      
      if (_debugMode) {
        print('✅ Successfully created new summary document');
      }
    }
  } catch (e, stackTrace) {
    if (_debugMode) {
      print('❌ Error saving selected abayas: $e');
      print('❌ Stack trace: $stackTrace');
    }
    
    // Re-throw the error to be handled by the caller
    rethrow;
  }
}
// Load selected abayas for a specific summary within the array
Future<void> loadSelectedAbayasForSummary(String summaryId) async {
  if (_user == null) {
    if (_debugMode) {
      print('❌ Cannot load selected abayas: User is null');
    }
    return;
  }
  
  try {
    _isLoading = true;
    notifyListeners();
    
    if (_debugMode) {
      print('🔍 Loading selected abayas for summary ID: $summaryId');
    }
    
    // Get the summary document using the user's ID
    final doc = await _firestore.collection('my summary').doc(_user!.uid).get();
    
    if (!doc.exists) {
      throw Exception('Summary document not found');
    }
    
    final data = doc.data()!;
    final summariesArray = data['summaries'] as List<dynamic>? ?? [];
    
    // Find the specific summary by ID
    final summary = summariesArray.firstWhere(
      (s) => s['id'] == summaryId,
      orElse: () => null,
    );
    
    if (summary == null) {
      throw Exception('Summary with ID $summaryId not found');
    }
    
    final selectedAbayasData = summary['selectedAbayas'] as List<dynamic>?;
    
    if (_debugMode) {
      print('🔍 Found summary with ${selectedAbayasData?.length ?? 0} selected abayas');
    }
    
    // Set the active summary ID
    _activeSummaryId = summaryId;
    
    // Clear previous selection
    _selectedAbayaIds.clear();
    
    // Add IDs from the summary
    if (selectedAbayasData != null) {
      for (final abayaData in selectedAbayasData) {
        final id = abayaData['id'] as String?;
        if (id != null) {
          _selectedAbayaIds.add(id);
        }
      }
    }
    
    if (_debugMode) {
      print('✅ Loaded ${_selectedAbayaIds.length} selected abaya IDs for summary $summaryId');
    }
    
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    if (_debugMode) {
      print('❌ Error loading selected abayas for summary: $e');
    }
    
    _isLoading = false;
    _errorMessage = e.toString();
    
    _retryCount++;
    if (_retryCount < _maxRetries) {
      if (_debugMode) {
        print('🔄 Retry attempt $_retryCount for loading selected abayas');
      }
      
      // Wait a bit before retrying
      await Future.delayed(Duration(seconds: 2 * _retryCount));
      
      // Try again
      await loadSelectedAbayasForSummary(summaryId);
      return;
    }
    
    notifyListeners();
  }
}
  
  // Clear the cache to force a reload of data
  void clearCache() {
    _hasApiDataCache = false;
    _cachedBodyShape = null;
    _retryCount = 0;
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
    _retryCount = 0;
    notifyListeners();
  }
  
  // Method to retry loading after failure
  Future<void> retryLoadAbayas({String? bodyShape}) async {
    if (_debugMode) {
      print('🔄 Manually retrying to load abayas');
    }
    
    _retryCount = 0;
    _errorMessage = null;
    clearCache(); // Clear cache to force refresh
    
    await loadRecommendedAbayas(bodyShape: bodyShape, forceRefresh: true);
  }
  
  // Helper function for min
  int min(int a, int b) => a < b ? a : b;
}