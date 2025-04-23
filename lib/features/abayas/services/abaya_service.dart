// lib/features/abayas/services/abaya_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/abaya_model.dart';

class AbayaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'Abayas';

  // Get all abayas
  Future<List<AbayaModel>> getAllAbayas() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      
      return snapshot.docs.map((doc) {
        return AbayaModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting abayas: $e');
      return [];
    }
  }

  // Get abayas for a specific body shape
  Future<List<AbayaModel>> getAbayasByBodyShape(String bodyShape) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('bodyShapeCategory', isEqualTo: bodyShape)
          .get();
      
      return snapshot.docs.map((doc) {
        return AbayaModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting abayas by body shape: $e');
      return [];
    }
  }

  // Get a single abaya by ID
  Future<AbayaModel?> getAbayaById(String id) async {
    try {
      final DocumentSnapshot doc = 
          await _firestore.collection(collectionName).doc(id).get();
      
      if (doc.exists) {
        return AbayaModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting abaya by ID: $e');
      return null;
    }
  }
}