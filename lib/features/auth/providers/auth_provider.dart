// lib/features/auth/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _guestMode = false;
  
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _user != null || _guestMode;
  bool get isGuest => _guestMode;
  
  AuthProvider() {
    _initializeAuth();
  }
  
  void _initializeAuth() {
    try {
      print("Starting auth state listener");
      // Listen for auth state changes
      _auth.authStateChanges().listen((User? user) {
        print("Auth state changed: user=${user?.uid}");
        _user = user;
        if (user != null) {
          _loadUserData();
        } else {
          _userData = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing auth in AuthProvider: $e');
    }
  }
  
  Future<void> _loadUserData() async {
    if (_user == null) return;
    
    try {
      print("Loading user data for uid: ${_user!.uid}");
      final doc = await _firestore.collection('Registration').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        print("User data loaded: ${_userData?.keys.join(', ')}");
        notifyListeners();
      } else {
        print("No user data found");
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  Future<void> login({required String email, required String password}) async {
    try {
      print("Attempting login for email: $email");
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("Login successful, user ID: ${userCredential.user?.uid}");
      
      // Add to Log In collection
      await _firestore.collection('Log In').doc(userCredential.user!.uid).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      print("Added login record to Firestore");
      await _loadUserData();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }
  
  // Enable guest mode
  void enableGuestMode() {
    _guestMode = true;
    
    // Create dummy user data for guest
    _userData = {
      'name': 'زائر',
      'email': 'guest@example.com',
      'phone': '05XXXXXXXX',
      'height': 170.0,
      'dateOfBirth': Timestamp.fromDate(DateTime(2000, 1, 1)),
      'isGuest': true,
    };
    
    notifyListeners();
    print("Guest mode enabled");
  }
  
  // Disable guest mode
  void disableGuestMode() {
    _guestMode = false;
    if (_user == null) {
      _userData = null;
    }
    notifyListeners();
    print("Guest mode disabled");
  }
  
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required double height,
    required DateTime dateOfBirth,
  }) async {
    try {
      print("Starting registration process for email: $email");
      
      // Step 1: Create user in Firebase Auth
      print("Step 1: Creating auth user");
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception("Failed to create user account");
      }
      
      final uid = credential.user!.uid;
      print("User created with UID: $uid");
      
      // Step 2: Convert data for Firestore
      print("Step 2: Preparing user data for Firestore");
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'height': height,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Step 3: Store additional data in Firestore
      print("Step 3: Storing user data in Registration collection");
      await _firestore.collection('Registration').doc(uid).set(userData);
      
      // Step 4: Also add to Login collection
      print("Step 4: Adding login record");
      await _firestore.collection('Log In').doc(uid).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      // Step 5: Set local data and notify
      print("Step 5: Updating local state");
      _user = credential.user;
      _userData = userData;
      notifyListeners();
      
      print("Registration completed successfully");
    } catch (e) {
      print('Registration error detailed: ${e.toString()}');
      print('Registration error runtimeType: ${e.runtimeType}');
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      print("Logging out");
      
      // If in guest mode, just disable it
      if (_guestMode) {
        disableGuestMode();
        return;
      }
      
      // Otherwise, log out properly
      await _auth.signOut();
      _user = null;
      _userData = null;
      notifyListeners();
      print("Logout successful");
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
  
  Future<void> updateProfile({
    required String name,
    required String phone,
    required double height,
    required DateTime dateOfBirth,
  }) async {
    // If guest mode, just update the local data
    if (_guestMode) {
      _userData = {
        ..._userData ?? {},
        'name': name,
        'phone': phone,
        'height': height,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'isGuest': true,
      };
      notifyListeners();
      return;
    }
    
    if (_user == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      print("Updating profile for user: ${_user!.uid}");
      final updateData = {
        'name': name,
        'phone': phone,
        'height': height,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('Registration').doc(_user!.uid).update(updateData);
      
      print("Profile updated in Firestore");
      if (_userData != null) {
        _userData!.addAll(updateData);
        notifyListeners();
      } else {
        await _loadUserData();
      }
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }
}