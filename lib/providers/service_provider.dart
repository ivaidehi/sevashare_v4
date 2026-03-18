import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assuming StoreAllServiceInfo is inside this file
import '../services/backend_services.dart';

class ServiceProvider with ChangeNotifier {
  // ==========================================
  // 1. STATE VARIABLES
  // ==========================================
  
  // List to store all services added by the current user
  List<Map<String, dynamic>> _myServicesList = [];
  
  // Fields for the primary/latest service (backward compatibility)
  String _fullName = "Username";
  String _profession = "Profession";
  String _profileImageUrl = "";
  String _contactNo = "";
  String _serviceCategory = "";
  String _serviceDescription = "";
  int _experienceYears = 0;
  double _hourlyRate = 0.0;
  Map<String, dynamic> _address = {};

  bool _isLoading = true;

  // Initialize your backend service
  final StoreAllServiceInfo _servicesService = StoreAllServiceInfo();

  // ==========================================
  // 2. GETTERS (To read data in UI)
  // ==========================================
  List<Map<String, dynamic>> get myServicesList => _myServicesList;
  
  String get fullName => _fullName;
  String get profession => _profession;
  String get profileImageUrl => _profileImageUrl;
  String get contactNo => _contactNo;
  String get serviceCategory => _serviceCategory;
  String get serviceDescription => _serviceDescription;
  int get experienceYears => _experienceYears;
  double get hourlyRate => _hourlyRate;
  Map<String, dynamic> get address => _address;
  bool get isLoading => _isLoading;

  // Constructor automatically starts listening to data
  ServiceProvider() {
    _listenToUserData();
  }

  // ==========================================
  // 3. READ DATA (Real-time Listener)
  // ==========================================
  void _listenToUserData() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('service_providers')
          .doc(uid)
          .collection('services')
          .orderBy('created_at', descending: true) // Sort by newest first
          .snapshots()
          .listen((snapshot) {

        // Store the full list of services
        _myServicesList = snapshot.docs.map((doc) => doc.data()).toList();

        // Update the legacy fields with the latest service data if available
        if (_myServicesList.isNotEmpty) {
          var data = _myServicesList.first;

          _fullName = data['full_name'] ?? 'No Name';
          _profession = data['profession'] ?? 'Professional';
          _profileImageUrl = data['profile_image_url'] ?? '';
          _contactNo = data['contact_no'] ?? '';
          _serviceCategory = data['service_category'] ?? '';
          _serviceDescription = data['service_description'] ?? '';
          _experienceYears = (data['experience_years'] ?? 0).toInt();
          _hourlyRate = (data['hourly_rate'] ?? 0.0).toDouble();
          _address = data['address'] ?? {};
        }

        _isLoading = false;
        notifyListeners();
      });
    }
  }

  // ==========================================
  // 4. WRITE DATA (Save new services)
  // ==========================================

  // Fetch the ID using the service layer
  String generateServiceId(String uid) {
    return _servicesService.getNewServiceId(uid);
  }

  // Wrap the save function
  Future<bool> submitServiceData(Map<String, dynamic> data, String serviceId) async {
    bool isSuccess = await _servicesService.saveServiceDetails(data, serviceId);
    return isSuccess;
  }
}
