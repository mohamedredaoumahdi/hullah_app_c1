import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  
  User? _user;
  Map<String, dynamic>? _userData;
  
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      
      _auth?.authStateChanges().listen((User? user) {
        _user = user;
        if (user != null) {
          _loadUserData();
        } else {
          _userData = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing Firebase in AuthProvider: $e');
    }
  }
  
  Future<void> _loadUserData() async {
    if (_user == null || _firestore == null) return;
    
    try {
      final doc = await _firestore!.collection('Registration').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  Future<void> login({required String email, required String password}) async {
    if (_auth == null || _firestore == null) {
      throw Exception('Firebase not initialized');
    }
    
    try {
      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Add to Log In collection
      await _firestore!.collection('Log In').doc(userCredential.user!.uid).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      await _loadUserData();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }
  
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required double height,
    required DateTime dateOfBirth,
  }) async {
    if (_auth == null || _firestore == null) {
      throw Exception('Firebase not initialized');
    }
    
    try {
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Add to Registration collection
      await _firestore!.collection('Registration').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'height': height,
        'dateOfBirth': dateOfBirth,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Also add to Log In collection
      await _firestore!.collection('Log In').doc(userCredential.user!.uid).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      await _loadUserData();
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }
  
  Future<void> logout() async {
    if (_auth == null) return;
    
    await _auth!.signOut();
    _user = null;
    _userData = null;
    notifyListeners();
  }
  
  Future<void> updateProfile({
    required String name,
    required String phone,
    required double height,
    required DateTime dateOfBirth,
  }) async {
    if (_user == null || _firestore == null) return;
    
    try {
      await _firestore!.collection('Registration').doc(_user!.uid).update({
        'name': name,
        'phone': phone,
        'height': height,
        'dateOfBirth': dateOfBirth,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _loadUserData();
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }
}