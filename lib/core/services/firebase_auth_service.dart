// lib/core/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  
  factory FirebaseAuthService() {
    return _instance;
  }
  
  FirebaseAuthService._internal();

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Sign up with email/password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("Attempting to create user with email: $email");
      
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("User created successfully with UID: ${credential.user?.uid}");
      return credential;
    } catch (e) {
      print("Error creating user: $e");
      rethrow;
    }
  }
  
  // Save user data to Firestore
  Future<void> saveUserDataToFirestore({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      print("Saving user data to Firestore for UID: $uid");
      print("User data: $userData");
      
      await _firestore.collection('Registration').doc(uid).set(userData);
      
      print("User data saved successfully");
    } catch (e) {
      print("Error saving user data: $e");
      rethrow;
    }
  }
  
  // Sign in with email/password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("Attempting to sign in user with email: $email");
      
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("User signed in successfully with UID: ${credential.user?.uid}");
      return credential;
    } catch (e) {
      print("Error signing in user: $e");
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      print("Signing out user");
      await _auth.signOut();
      print("User signed out successfully");
    } catch (e) {
      print("Error signing out user: $e");
      rethrow;
    }
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      print("Getting user data for UID: $uid");
      
      final DocumentSnapshot<Map<String, dynamic>> doc = 
          await _firestore.collection('Registration').doc(uid).get();
      
      if (doc.exists) {
        print("User data retrieved successfully");
        return doc.data();
      } else {
        print("No user data found for UID: $uid");
        return null;
      }
    } catch (e) {
      print("Error getting user data: $e");
      rethrow;
    }
  }
  
  // Register a complete user (auth + data)
  Future<User?> registerCompleteUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required double height,
    required DateTime dateOfBirth,
  }) async {
    try {
      print("Starting complete user registration process");
      
      // 1. Create auth user
      final UserCredential credential = await signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = credential.user;
      
      if (user == null) {
        print("Failed to create user - user is null");
        throw Exception("Failed to create user account");
      }
      
      // 2. Prepare user data
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'height': height,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // 3. Save user data
      await saveUserDataToFirestore(
        uid: user.uid,
        userData: userData,
      );
      
      // 4. Also add to Login collection
      await _firestore.collection('Log In').doc(user.uid).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      print("Complete user registration successful");
      return user;
    } catch (e) {
      print("Error in complete user registration: $e");
      
      // If already registered, try to sign in
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        print("Email already in use, attempting to sign in");
        
        try {
          final UserCredential credential = await signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          print("Sign in successful for existing user");
          return credential.user;
        } catch (signInError) {
          print("Error signing in existing user: $signInError");
          rethrow;
        }
      }
      
      rethrow;
    }
  }
}