// Enhanced AbayaService with debugging
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/abaya_model.dart';

class AbayaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'Abayas';
  final bool _debugMode = true; // Enable debug mode

  // Get all abayas
  Future<List<AbayaModel>> getAllAbayas() async {
    if (_debugMode) {
      print('🔍 AbayaService: Getting all abayas');
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      
      if (_debugMode) {
        print('✅ Retrieved ${snapshot.docs.length} abayas from Firestore');
        // Log collection path to confirm correct collection
        print('🔍 Collection path: ${collectionName}');
      }
      
      final abayas = snapshot.docs.map((doc) {
        try {
          if (_debugMode) {
            print('🔍 Processing document ID: ${doc.id}');
            final data = doc.data() as Map<String, dynamic>;
            
            // Check for critical fields
            if (!data.containsKey('model')) {
              print('⚠️ Document ${doc.id} is missing "model" field');
            }
            if (!data.containsKey('image1Url')) {
              print('⚠️ Document ${doc.id} is missing "image1Url" field');
            } else {
              final imageUrl = data['image1Url'] as String? ?? '';
              print('🔍 Image URL for ${doc.id}: ${imageUrl.substring(0, min(imageUrl.length, 50))}...');
            }
          }
          
          return AbayaModel.fromMap({
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
          });
        } catch (e) {
          if (_debugMode) {
            print('❌ Error parsing document ${doc.id}: $e');
            print('❌ Document data: ${doc.data()}');
          }
          
          // Return placeholder model instead of throwing
          return AbayaModel(
            id: doc.id,
            model: 'Error in document',
            fabric: 'Error',
            color: 'Error',
            description: 'Error loading abaya data: ${e.toString()}',
            bodyShapeCategory: 'Unknown',
            image1Url: 'https://via.placeholder.com/300?text=Error',
          );
        }
      }).toList();
      
      if (_debugMode) {
        // Check if any abayas were returned
        if (abayas.isEmpty) {
          print('⚠️ No abayas found in the collection!');
        } else {
          print('✅ Successfully mapped ${abayas.length} abayas');
          
          // Log sample abayas for debugging
          for (int i = 0; i < min(abayas.length, 2); i++) {
            final abaya = abayas[i];
            print('🔍 Sample abaya $i: ID=${abaya.id}, Model=${abaya.model}');
            print('🔍 Image URL: ${abaya.image1Url.substring(0, min(abaya.image1Url.length, 50))}...');
          }
        }
      }
      
      return abayas;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error getting all abayas: $e');
      }
      return [];
    }
  }

  // Get abayas for a specific body shape
  Future<List<AbayaModel>> getAbayasByBodyShape(String bodyShape) async {
    if (_debugMode) {
      print('🔍 AbayaService: Getting abayas for body shape: $bodyShape');
    }
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('bodyShapeCategory', isEqualTo: bodyShape)
          .get();
      
      if (_debugMode) {
        print('✅ Retrieved ${snapshot.docs.length} abayas for body shape: $bodyShape');
        
        // If no results, this might indicate a problem
        if (snapshot.docs.isEmpty) {
          print('⚠️ No abayas found for body shape: $bodyShape');
          print('⚠️ Check if the "bodyShapeCategory" field exists and matches the query value');
          
          // Debug: get sample document to check field name
          try {
            final sampleDoc = await _firestore.collection(collectionName).limit(1).get();
            if (sampleDoc.docs.isNotEmpty) {
              final data = sampleDoc.docs.first.data() as Map<String, dynamic>;
              print('🔍 Sample document fields: ${data.keys.join(', ')}');
              
              // Check if there's a similar field that might be the body shape
              for (final key in data.keys) {
                if (key.toLowerCase().contains('body') || 
                    key.toLowerCase().contains('shape') || 
                    key.toLowerCase().contains('category')) {
                  print('🔍 Potential body shape field found: $key = ${data[key]}');
                }
              }
            }
          } catch (e) {
            print('❌ Error getting sample document: $e');
          }
        }
      }
      
      final abayas = snapshot.docs.map((doc) {
        try {
          if (_debugMode && snapshot.docs.length <= 5) {
            // For small result sets, log each document
            print('🔍 Processing document ID: ${doc.id}');
            final data = doc.data() as Map<String, dynamic>;
            print('🔍 Body shape category: ${data['bodyShapeCategory']}');
            
            if (data.containsKey('image1Url')) {
              final imageUrl = data['image1Url'] as String? ?? '';
              print('🔍 Image URL: ${imageUrl.substring(0, min(imageUrl.length, 50))}...');
            } else {
              print('⚠️ Missing image1Url field!');
            }
          }
          
          return AbayaModel.fromMap({
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
          });
        } catch (e) {
          if (_debugMode) {
            print('❌ Error parsing document ${doc.id}: $e');
          }
          
          // Return placeholder model instead of throwing
          return AbayaModel(
            id: doc.id,
            model: 'Error in document',
            fabric: 'Error',
            color: 'Error',
            description: 'Error loading abaya data',
            bodyShapeCategory: bodyShape,
            image1Url: 'https://via.placeholder.com/300?text=Error',
          );
        }
      }).toList();
      
      if (_debugMode) {
        print('✅ Successfully mapped ${abayas.length} abayas for body shape: $bodyShape');
      }
      
      return abayas;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error getting abayas by body shape: $e');
      }
      return [];
    }
  }

  // Get a single abaya by ID
  Future<AbayaModel?> getAbayaById(String id) async {
    if (_debugMode) {
      print('🔍 AbayaService: Getting abaya by ID: $id');
    }
    
    try {
      final DocumentSnapshot doc = 
          await _firestore.collection(collectionName).doc(id).get();
      
      if (doc.exists) {
        if (_debugMode) {
          print('✅ Found abaya with ID: $id');
          final data = doc.data() as Map<String, dynamic>;
          
          // Log image URL field
          if (data.containsKey('image1Url')) {
            final imageUrl = data['image1Url'] as String? ?? '';
            print('🔍 Image URL: ${imageUrl.substring(0, min(imageUrl.length, 50))}...');
          } else {
            print('⚠️ Document is missing image1Url field!');
          }
        }
        
        return AbayaModel.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      } else {
        if (_debugMode) {
          print('⚠️ No abaya found with ID: $id');
        }
        return null;
      }
    } catch (e) {
      if (_debugMode) {
        print('❌ Error getting abaya by ID: $e');
      }
      return null;
    }
  }
  
  // Debug method to inspect the collection structure
  Future<void> debugInspectCollection() async {
    if (!_debugMode) return;
    
    print('🔎 INSPECTION OF $collectionName COLLECTION 🔎');
    
    try {
      // Get total count
      final snapshot = await _firestore.collection(collectionName).get();
      print('Total documents: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ Collection is empty! Check collection name or data.');
        return;
      }
      
      // Get schema from first document
      final firstDoc = snapshot.docs.first;
      final data = firstDoc.data();
      
      print('Sample document ID: ${firstDoc.id}');
      print('Fields available:');
      data.forEach((key, value) {
        final valueType = value.runtimeType.toString();
        final valuePreview = value.toString();
        final truncatedValue = valuePreview.length > 100 
            ? valuePreview.substring(0, 100) + '...' 
            : valuePreview;
            
        print(' - $key ($valueType): $truncatedValue');
      });
      
      // Check for image URLs specifically
      print('\nChecking image fields:');
      for (var field in ['image1Url', 'image2Url', 'image3Url', 'imageUrl', 'image', 'imageURL', 'photo', 'photoUrl']) {
        if (data.containsKey(field)) {
          print('✅ Found image field: $field');
          final value = data[field];
          print('   Value: ${value.toString().substring(0, min(value.toString().length, 100))}...');
        }
      }
      
      // Check body shape field
      print('\nChecking body shape fields:');
      for (var field in ['bodyShapeCategory', 'bodyShape', 'body_shape', 'shape', 'category']) {
        if (data.containsKey(field)) {
          print('✅ Found potential body shape field: $field');
          print('   Value: ${data[field]}');
        }
      }
      
      // Get distinct body shapes
      print('\nDistinct body shape categories:');
      
      final bodyShapeField = data.containsKey('bodyShapeCategory') 
          ? 'bodyShapeCategory' 
          : (data.containsKey('bodyShape') ? 'bodyShape' : null);
          
      if (bodyShapeField != null) {
        final categories = <String, int>{};
        
        for (var doc in snapshot.docs) {
          final shape = doc.data()[bodyShapeField]?.toString() ?? 'null';
          categories[shape] = (categories[shape] ?? 0) + 1;
        }
        
        categories.forEach((shape, count) {
          print(' - $shape: $count documents');
        });
      } else {
        print('⚠️ No body shape field identified');
      }
      
    } catch (e) {
      print('❌ Error during collection inspection: $e');
    }
  }
  
  // Helper function
  int min(int a, int b) => a < b ? a : b;
}