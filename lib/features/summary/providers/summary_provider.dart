// lib/features/summary/providers/summary_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hullah_app/core/utils/pdf_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../abayas/models/abaya_model.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;

class SummaryProvider with ChangeNotifier {
  FirebaseFirestore? _firestore;
  User? _user;
  
  // Current active summary data
  Map<String, dynamic>? _summary;
  List<AbayaModel> _selectedAbayas = [];
  String? _activeSummaryId; // ID of the active summary within the array
  
  // All user summaries for listing - now stored in a single document
  List<Map<String, dynamic>> _allUserSummaries = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _debugMode = true; // Set to false in production
  
  Map<String, dynamic>? get summary => _summary;
  List<AbayaModel> get selectedAbayas => _selectedAbayas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get activeSummaryId => _activeSummaryId;
  List<Map<String, dynamic>> get allUserSummaries => _allUserSummaries;
  
  SummaryProvider() {
    _initializeFirebase();
  }
  
  void _initializeFirebase() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error initializing Firebase in SummaryProvider: $e');
      }
    }
  }
  
  void updateAuth(app_auth.AuthProvider authProvider) {
    _user = authProvider.user;
    if (_user != null) {
      loadAllUserSummaries();
    } else {
      _summary = null;
      _selectedAbayas = [];
      _allUserSummaries = [];
    }
  }
  
  // Load all summaries for the current user - adapted for security rules
  Future<void> loadAllUserSummaries() async {
    if (_user == null || _firestore == null) return;
    
    try {
      // Avoid calling setState during build
      if (_isLoading) return;
      
      _isLoading = true;
      notifyListeners();
      
      if (_debugMode) {
        print('🔍 SummaryProvider: Loading all summaries for user: ${_user!.uid}');
      }
      
      // With the current security rules, we need to access the document directly
      // using the user's ID as the document ID
      final docRef = _firestore!.collection('my summary').doc(_user!.uid);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};
        
        // Extract the summaries array from the document
        final summariesData = data['summaries'] as List<dynamic>? ?? [];
        
        if (_debugMode) {
          print('🔍 Found ${summariesData.length} summaries in user document');
        }
        
        // Create a list to hold unique summaries
        final List<Map<String, dynamic>> uniqueSummaries = [];
        final Set<String> processedIds = {};
        
        // Process summaries and filter out duplicates
        for (var summary in summariesData) {
          final Map<String, dynamic> summaryMap = Map<String, dynamic>.from(summary);
          final String? summaryId = summaryMap['id']?.toString();
          
          // Only add summaries with unique IDs
          if (summaryId != null && !processedIds.contains(summaryId)) {
            processedIds.add(summaryId);
            uniqueSummaries.add(summaryMap);
            
            if (_debugMode) {
              print('🔍 Added unique summary with ID: $summaryId');
            }
          } else if (_debugMode && summaryId != null) {
            print('⚠️ Skipping duplicate summary with ID: $summaryId');
          }
        }
        
        _allUserSummaries = uniqueSummaries;
        
        // Sort by timestamp if available
        _allUserSummaries.sort((a, b) {
          final aTimestampStr = a['timestamp'] as String?;
          final bTimestampStr = b['timestamp'] as String?;
          
          // Parse ISO date strings to DateTime for comparison
          try {
            if (aTimestampStr == null && bTimestampStr == null) return 0;
            if (aTimestampStr == null) return 1;
            if (bTimestampStr == null) return -1;
            
            final aDate = DateTime.parse(aTimestampStr);
            final bDate = DateTime.parse(bTimestampStr);
            
            return bDate.compareTo(aDate); // Descending order
          } catch (e) {
            // Fallback if there's an error parsing dates
            return 0;
          }
        });
        
        // If we don't have an active summary, set the first one as active
        if (_summary == null && _allUserSummaries.isNotEmpty) {
          await setActiveSummary(_allUserSummaries.first);
        }
        
        if (_debugMode) {
          print('✅ Successfully loaded ${_allUserSummaries.length} unique summaries');
        }
      } else {
        // No document exists yet - create an empty document
        await docRef.set({
          'userId': _user!.uid,
          'summaries': [],
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
        
        _allUserSummaries = [];
      }
      
      _isLoading = false;
      notifyListeners();
      
      if (_debugMode) {
        print('✅ Successfully loaded all user summaries');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error loading all summaries: $e');
      }
      
      notifyListeners();
    }
  }
  
  // Set the active summary from a data object
  Future<void> setActiveSummary(Map<String, dynamic> summaryData) async {
    if (_user == null || _firestore == null) return;
    
    try {
      if (_debugMode) {
        print('🔍 Setting active summary: ${summaryData['id']}');
      }
      
      _activeSummaryId = summaryData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      _summary = summaryData;
      
      // Parse selected abayas
      final selectedAbayasData = summaryData['selectedAbayas'] as List<dynamic>?;
      
      if (selectedAbayasData != null) {
        _selectedAbayas = selectedAbayasData
            .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
            .toList();
            
        if (_debugMode) {
          print('🔍 Loaded ${_selectedAbayas.length} selected abayas for active summary');
        }
      } else {
        _selectedAbayas = [];
      }
      
      notifyListeners();
      
      if (_debugMode) {
        print('✅ Active summary set successfully');
      }
    } catch (e) {
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error setting active summary: $e');
      }
      
      notifyListeners();
    }
  }
  
  // Load the default summary
  Future<void> loadSummary() async {
    if (_user == null || _firestore == null) return;
    
    try {
      // Avoid calling setState during build
      if (_isLoading) return;
      
      _isLoading = true;
      notifyListeners();
      
      if (_debugMode) {
        print('🔍 SummaryProvider: Loading summary for user: ${_user!.uid}');
      }
      
      // Access document directly using user ID
      final summaryDoc = await _firestore!.collection('my summary').doc(_user!.uid).get();
      
      if (_debugMode) {
        print('🔍 Summary document exists: ${summaryDoc.exists}');
        if (summaryDoc.exists && summaryDoc.data() != null) {
          print('🔍 Summary document fields: ${summaryDoc.data()!.keys.join(', ')}');
        }
      }
      
      // If we have an active summary ID, load that summary from the array
      if (summaryDoc.exists) {
        final data = summaryDoc.data() ?? {};
        final summariesArray = data['summaries'] as List<dynamic>? ?? [];
        
        if (_activeSummaryId != null) {
          // Find the active summary in the array
          final activeSummary = summariesArray.firstWhere(
            (summary) => summary['id'] == _activeSummaryId,
            orElse: () => summariesArray.isNotEmpty ? summariesArray.first : null,
          );
          
          if (activeSummary != null) {
            _summary = Map<String, dynamic>.from(activeSummary);
            
            // Parse selected abayas
            final selectedAbayasData = _summary!['selectedAbayas'] as List<dynamic>?;
            
            if (selectedAbayasData != null) {
              _selectedAbayas = selectedAbayasData
                  .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
                  .toList();
            } else {
              _selectedAbayas = [];
            }
          } else {
            // No active summary found, create a new one
            _summary = {};
            _selectedAbayas = [];
          }
        } else if (summariesArray.isNotEmpty) {
          // No active summary ID, use the first one
          _summary = Map<String, dynamic>.from(summariesArray.first);
          _activeSummaryId = _summary!['id'];
          
          // Parse selected abayas
          final selectedAbayasData = _summary!['selectedAbayas'] as List<dynamic>?;
          
          if (selectedAbayasData != null) {
            _selectedAbayas = selectedAbayasData
                .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
                .toList();
          } else {
            _selectedAbayas = [];
          }
        } else {
          // No summaries exist yet
          _summary = {};
          _selectedAbayas = [];
        }
      } else {
        // No document exists, create a new one
        _summary = {};
        _selectedAbayas = [];
      }
      
      // Fetch measurements
      final measurementsDoc = await _firestore!.collection('my measurements').doc(_user!.uid).get();
      
      // Fetch profile
      final profileDoc = await _firestore!.collection('Registration').doc(_user!.uid).get();
      
      // Merge with latest profile and measurements data
      if (_summary == null || _summary!.isEmpty) {
        _summary = {
          'measurements': measurementsDoc.data() ?? {},
          'profile': profileDoc.data() ?? {},
          'selectedAbayas': [],
        };
      } else {
        // Make sure we have the latest measurements and profile
        _summary!['measurements'] = measurementsDoc.data() ?? _summary!['measurements'] ?? {};
        _summary!['profile'] = profileDoc.data() ?? _summary!['profile'] ?? {};
      }
      
      _isLoading = false;
      notifyListeners();
      
      if (_debugMode) {
        print('✅ Summary loaded successfully');
        print('🔍 Selected abayas in provider: ${_selectedAbayas.length}');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error loading summary: $e');
      }
      
      notifyListeners();
    }
  }
  
  Future<void> createNewSummary() async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      if (_debugMode) {
        print('🔍 Creating new summary for user: ${_user!.uid}');
      }
      
      // Clear existing summary data
      _summary = {};
      _selectedAbayas = [];
      
      // Generate a unique ID for this summary
      _activeSummaryId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Fetch measurements
      final measurementsDoc = await _firestore!.collection('my measurements').doc(_user!.uid).get();
      
      // Fetch profile
      final profileDoc = await _firestore!.collection('Registration').doc(_user!.uid).get();
      
      // Current timestamp as string instead of FieldValue.serverTimestamp()
      final timestamp = DateTime.now().toUtc().toIso8601String();
      
      // Create new summary
      _summary = {
        'id': _activeSummaryId,
        'userId': _user!.uid,
        'measurements': measurementsDoc.data() ?? {},
        'profile': profileDoc.data() ?? {},
        'selectedAbayas': [],
        'timestamp': timestamp,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Save right away to ensure it's in the list
      await saveSummary();
      
      notifyListeners();
      
      if (_debugMode) {
        print('✅ New summary created successfully with ID: $_activeSummaryId');
      }
    } catch (e, stackTrace) {
      if (_debugMode) {
        print('❌ Error creating new summary: $e');
        print('❌ Stack trace: $stackTrace');
      }
      
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }
  
  // Duplicate an existing summary
  Future<void> duplicateSummary(Map<String, dynamic> sourceSummary) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      if (_debugMode) {
        print('🔍 Duplicating summary for user: ${_user!.uid}');
      }
      
      // Generate a unique ID for the duplicated summary
      _activeSummaryId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Current timestamp as string
      final timestamp = DateTime.now().toUtc().toIso8601String();
      
      // Create a copy of the source summary
      _summary = {
        'id': _activeSummaryId,
        'userId': _user!.uid,
        'measurements': sourceSummary['measurements'] ?? {},
        'profile': sourceSummary['profile'] ?? {},
        'selectedAbayas': sourceSummary['selectedAbayas'] ?? [],
        'timestamp': timestamp,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isDuplicate': true,
        'duplicatedFrom': sourceSummary['id'],
      };
      
      // Parse selected abayas
      final selectedAbayasData = sourceSummary['selectedAbayas'] as List<dynamic>?;
      
      if (selectedAbayasData != null) {
        _selectedAbayas = selectedAbayasData
            .map((data) => AbayaModel.fromMap(data as Map<String, dynamic>))
            .toList();
            
        if (_debugMode) {
          print('🔍 Duplicated ${_selectedAbayas.length} selected abayas');
        }
      } else {
        _selectedAbayas = [];
      }
      
      // Save right away
      await saveSummary();
      
      notifyListeners();
      
      if (_debugMode) {
        print('✅ Summary duplicated successfully with ID: $_activeSummaryId');
      }
    } catch (e) {
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error duplicating summary: $e');
      }
      
      notifyListeners();
      throw e;
    }
  }
  
  // Save or update the current summary
  Future<void> saveSummary() async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      if (_debugMode) {
        print('🔍 Saving summary for user: ${_user!.uid}');
      }
      
      if (_summary == null) {
        throw Exception('No summary data to save');
      }
      
      // Ensure the summary has an ID
      if (_activeSummaryId == null) {
        _activeSummaryId = DateTime.now().millisecondsSinceEpoch.toString();
        _summary!['id'] = _activeSummaryId;
      }
      
      // Include user ID and timestamp as ISO string, not FieldValue.serverTimestamp()
      _summary!['userId'] = _user!.uid;
      _summary!['timestamp'] = DateTime.now().toUtc().toIso8601String();
      
      // First get the current document
      final docRef = _firestore!.collection('my summary').doc(_user!.uid);
      final docSnapshot = await docRef.get();
      
      final currentTimestamp = DateTime.now().toUtc().toIso8601String();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};
        List<dynamic> summaries = List.from(data['summaries'] ?? []);
        
        // Look for existing summary with this ID
        final existingIndex = summaries.indexWhere((s) => s['id'] == _activeSummaryId);
        
        if (existingIndex >= 0) {
          // Update existing summary
          summaries[existingIndex] = _summary;
          
          if (_debugMode) {
            print('🔍 Updating existing summary at index $existingIndex');
          }
        } else {
          // Add new summary
          summaries.add(_summary);
          
          if (_debugMode) {
            print('🔍 Adding new summary to array');
          }
        }
        
        // Deduplicate summaries before saving
        final uniqueSummaries = <Map<String, dynamic>>[];
        final processedIds = <String>{};
        
        for (final summary in summaries) {
          final summaryMap = summary as Map<String, dynamic>;
          final summaryId = summaryMap['id']?.toString();
          
          if (summaryId != null && !processedIds.contains(summaryId)) {
            processedIds.add(summaryId);
            uniqueSummaries.add(summaryMap);
            
            if (_debugMode) {
              print('🔍 Adding unique summary with ID $summaryId to save list');
            }
          }
        }
        
        // Update the document
        await docRef.update({
          'summaries': uniqueSummaries,
          'timestamp': currentTimestamp,
        });
        
        if (_debugMode) {
          print('✅ Updated document with ${uniqueSummaries.length} unique summaries');
        }
      } else {
        // Create new document with this summary
        await docRef.set({
          'userId': _user!.uid,
          'summaries': [_summary],
          'timestamp': currentTimestamp,
        });
        
        if (_debugMode) {
          print('✅ Created new document with summary');
        }
      }
      
      // Refresh the list of all summaries
      await loadAllUserSummaries();
      
      if (_debugMode) {
        print('✅ Summary saved successfully');
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error saving summary: $e');
      }
      
      notifyListeners();
      throw e;
    }
  }
  
  // Delete a summary
  Future<void> deleteSummary(Map<String, dynamic> summaryToDelete) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      final summaryId = summaryToDelete['id'];
      
      if (summaryId == null) {
        throw Exception('Invalid summary ID');
      }
      
      if (_debugMode) {
        print('🔍 Deleting summary with ID: $summaryId');
      }
      
      // Get the current document
      final docRef = _firestore!.collection('my summary').doc(_user!.uid);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};
        List<dynamic> summaries = List.from(data['summaries'] ?? []);
        
        // Remove the summary with this ID
        summaries.removeWhere((s) => s['id'] == summaryId);
        
        // Update the document with timestamp as string
        final currentTimestamp = DateTime.now().toUtc().toIso8601String();
        
        await docRef.update({
          'summaries': summaries,
          'timestamp': currentTimestamp,
        });
        
        // If we just deleted the active summary, clear it
        if (_activeSummaryId == summaryId) {
          _summary = null;
          _selectedAbayas = [];
          _activeSummaryId = null;
        }
        
        // Refresh the list
        await loadAllUserSummaries();
        
        if (_debugMode) {
          print('✅ Summary deleted successfully');
        }
      } else {
        if (_debugMode) {
          print('⚠️ No document found to delete summary from');
        }
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      
      if (_debugMode) {
        print('❌ Error deleting summary: $e');
      }
      
      notifyListeners();
      throw e;
    }
  }
  
  Future<void> updateSummary({
    required List<AbayaModel> selectedAbayas,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      if (_debugMode) {
        print('🔍 Updating summary with ${selectedAbayas.length} abayas');
      }
      
      final selectedAbayasData = selectedAbayas.map((abaya) => abaya.toMap()).toList();
      
      // If we don't have a summary yet, create a new one
      if (_summary == null) {
        await createNewSummary();
      }
      
      // Ensure we have an active summary ID
      if (_activeSummaryId == null) {
        _activeSummaryId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      // Update the active summary
      _selectedAbayas = selectedAbayas;
      _summary = {
        ..._summary ?? {},
        'id': _activeSummaryId,
        'selectedAbayas': selectedAbayasData,
        'timestamp': DateTime.now().toUtc().toIso8601String(), // String timestamp, not Firestore FieldValue
        ...?additionalData,
      };
      
      // Save to Firestore
      await saveSummary();
      
      if (_debugMode) {
        print('✅ Summary updated successfully');
        print('🔍 Selected abayas after update: ${_selectedAbayas.length}');
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      if (_debugMode) {
        print('❌ Error updating summary: $e');
        print('❌ Stack trace: $stackTrace');
      }
      
      // More detailed error handling
      String errorMessage = 'Unknown error occurred';
      if (e is FirebaseException) {
        errorMessage = 'Firebase error: ${e.message ?? "Unknown Firebase error"}';
      } else if (e is Exception) {
        errorMessage = e.toString();
      }
      
      _errorMessage = errorMessage;
      notifyListeners();
      
      // Rethrow to allow caller to handle the error
      throw Exception(errorMessage);
    }
  }
  
  Future<void> updateMeasurements(Map<String, dynamic> measurements) async {
    if (_user == null || _firestore == null) {
      throw Exception('User not authenticated or Firebase not initialized');
    }
    
    try {
      if (_debugMode) {
        print('🔍 Updating measurements: ${measurements.keys.join(', ')}');
      }
      
      // Update measurements collection
      await _firestore!.collection('my measurements').doc(_user!.uid).update(measurements);
      
      // If we don't have a summary yet, create a new one
      if (_summary == null) {
        await createNewSummary();
      }
      
      // Update the active summary
      _summary = {
        ..._summary ?? {},
        'measurements': {
          ..._summary?['measurements'] ?? {},
          ...measurements,
        },
      };
      
      // Ensure the summary has an ID
      if (_activeSummaryId == null) {
        _activeSummaryId = DateTime.now().millisecondsSinceEpoch.toString();
        _summary!['id'] = _activeSummaryId;
      } else {
        _summary!['id'] = _activeSummaryId;
      }
      
      // Save to Firestore
      await saveSummary();
      
      if (_debugMode) {
        print('✅ Measurements updated successfully');
      }
      
      notifyListeners();
    } catch (e) {
      if (_debugMode) {
        print('❌ Error updating measurements: $e');
      }
      
      _errorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }
  
  Future<File> generatePDF() async {
    if (_summary == null) {
      throw Exception('No summary data available');
    }
    
    if (_debugMode) {
      print('🔍 Generating PDF with ${_selectedAbayas.length} abayas');
    }
    
    try {
      // Generate the PDF file
      final file = await PdfGenerator.generateSummaryPdf(
        summary: _summary!,
        selectedAbayas: _selectedAbayas,
      );
      
      if (_debugMode) {
        print('✅ PDF generated successfully: ${file.path}');
      }
      
      // Save a copy to a more accessible location for the user (optional)
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'ملخص_تفصيل_العباية_$timestamp.pdf';
        final savedFile = await file.copy('${appDocDir.path}/$fileName');
        
        if (_debugMode) {
          print('✅ PDF saved to accessible location: ${savedFile.path}');
        }
      } catch (e) {
        // Don't throw an error here, just log it
        if (_debugMode) {
          print('⚠️ Could not save PDF copy to accessible location: $e');
        }
      }
      
      return file;
    } catch (e) {
      if (_debugMode) {
        print('❌ Error generating PDF: $e');
      }
      
      throw e;
    }
  }
  
  void clearSummary() {
    _summary = null;
    _selectedAbayas = [];
    _activeSummaryId = null;
    notifyListeners();
    
    if (_debugMode) {
      print('🔍 Summary cleared');
    }
  }
  
  // Debug method to check the selected abayas
  void debugSelectedAbayas() {
    if (!_debugMode) return;
    
    print("🛑 SUMMARY PROVIDER DEBUG 🛑");
    print("🛑 Total Selected Abayas: ${_selectedAbayas.length}");
    
    if (_selectedAbayas.isEmpty) {
      print("🛑 No abayas selected!");
    } else {
      for (int i = 0; i < _selectedAbayas.length; i++) {
        final abaya = _selectedAbayas[i];
        print("🛑 Abaya $i: ID=${abaya.id}, Model=${abaya.model}");
        print("🛑 Image URL: ${abaya.image1Url}");
        print("🛑 Accessible Image URL: ${abaya.accessibleImage1Url}");
      }
    }
    
    if (_summary != null && _summary!.containsKey('selectedAbayas')) {
      final List? rawList = _summary!['selectedAbayas'] as List?;
      print("🛑 Selected Abayas in summary data: ${rawList?.length ?? 0}");
    }
    
    // Check the user ID
    print("🛑 Current User ID: ${_user?.uid ?? 'No user logged in'}");
    
    // Check the loading state
    print("🛑 Is Loading: $_isLoading");
    
    // Check for error message
    print("🛑 Error Message: ${_errorMessage ?? 'No error'}");
  }
}