import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Assuming StoreAllServiceInfo is inside this file
import '../services/backend_services.dart';

class ServiceProvider with ChangeNotifier {

  // 1. STATE VARIABLES
  List<Map<String, dynamic>> _myServicesList = [];
  List<Map<String, dynamic>> _allServicesList = [];
  
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
  bool _isAllProvidersLoading = true;

  StreamSubscription? _myServicesSubscription;
  StreamSubscription? _allServicesSubscription;
  StreamSubscription? _authSubscription;

  // Initialize your backend service
  final StoreAllServiceInfo _servicesService = StoreAllServiceInfo();

  // 2. GETTERS
  List<Map<String, dynamic>> get myServicesList => _myServicesList;
  List<Map<String, dynamic>> get allServicesList => _allServicesList;
  
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
  bool get isAllProvidersLoading => _isAllProvidersLoading;

  ServiceProvider() {
    _listenToAuthChanges();
    _listenToAllServices();
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToMyServices(user.uid);
      } else {
        _myServicesSubscription?.cancel();
        _myServicesList = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _listenToMyServices(String uid) {
    _myServicesSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _myServicesSubscription = FirebaseFirestore.instance
        .collection('service_providers')
        .doc(uid)
        .collection('services')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {

      _myServicesList = snapshot.docs.map((doc) => doc.data()).toList();

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
    }, onError: (error) {
      print("Error fetching my services: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToAllServices() {
    _allServicesSubscription?.cancel();
    _allServicesSubscription = FirebaseFirestore.instance
        .collectionGroup('services')
        .snapshots()
        .listen((snapshot) {
      
      _allServicesList = snapshot.docs.map((doc) => doc.data()).toList();
      _allServicesList.sort((a, b) {
        String nameA = (a['full_name'] ?? '').toString().toLowerCase();
        String nameB = (b['full_name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      
      _isAllProvidersLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error fetching all services: $error");
      _isAllProvidersLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _myServicesSubscription?.cancel();
    _allServicesSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  String generateServiceId(String uid) {
    return _servicesService.getNewServiceId(uid);
  }

  Future<bool> submitServiceData(Map<String, dynamic> data, String serviceId) async {
    bool isSuccess = await _servicesService.saveServiceDetails(data, serviceId);
    return isSuccess;
  }
}
