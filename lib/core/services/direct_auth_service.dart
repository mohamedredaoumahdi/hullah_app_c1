// lib/core/services/direct_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class DirectAuthService {
  // Private constructor for singleton
  DirectAuthService._();
  static final DirectAuthService instance = DirectAuthService._();
  
  // Direct access to Firebase instances - avoiding any abstraction layers
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      // 1. Create auth account - Use a lower-level API call
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      return credential.user;
    } catch (e) {
      print('DirectAuthService.signUp error: $e');
      return null;
    }
  }
  
  // Handle user profile creation separately
  Future<bool> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required double height,
    required DateTime dateOfBirth
  }) async {
    try {
      // Create user profile document
      await _firestore.collection('Registration').doc(userId).set({
        'name': name,
        'email': email,
        'phone': phone,
        'height': height,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'createdAt': FieldValue.serverTimestamp()
      });
      
      // Add login record
      await _firestore.collection('Log In').doc(userId).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp()
      });
      
      return true;
    } catch (e) {
      print('DirectAuthService.createUserProfile error: $e');
      return false;
    }
  }
  
  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Update login record
      if (credential.user != null) {
        await _firestore.collection('Log In').doc(credential.user!.uid).set({
          'email': email,
          'lastLogin': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
      }
      
      return credential.user;
    } catch (e) {
      print('DirectAuthService.signIn error: $e');
      return null;
    }
  }
  
  // Sign out
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      print('DirectAuthService.signOut error: $e');
      return false;
    }
  }
  
  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('Registration').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('DirectAuthService.getUserProfile error: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data
  }) async {
    try {
      await _firestore.collection('Registration').doc(userId).update(data);
      return true;
    } catch (e) {
      print('DirectAuthService.updateUserProfile error: $e');
      return false;
    }
  }
}