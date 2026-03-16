import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';

class UserProvider with ChangeNotifier {
  String _fullName = "Username";
  String _profession = "Profession";
  bool _isLoading = true;

  // Getters to access the data
  String get fullName => _fullName;
  String get profession => _profession;
  bool get isLoading => _isLoading;

  UserProvider() {
    _listenToUserData();
  }

  void _listenToUserData() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('service_providers')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;
          _fullName = data['full_name'] ?? 'No Name';
          _profession = data['profession'] ?? 'Professional';
        }
        _isLoading = false;
        notifyListeners(); // This tells all UI widgets to rebuild with new data
      });
    }
  }
}


class ServicesProvider extends ChangeNotifier {
  // Initialize your service
  final StoreAllServiceInfo _servicesService = StoreAllServiceInfo();

  // 1. Fetch the ID using the service layer
  String generateServiceId(String uid) {
    return _servicesService.getNewServiceId(uid);
  }

  // 2. Wrap the save function to keep your UI clean
  Future<bool> submitServiceData(Map<String, dynamic> data, String serviceId) async {
    // You can set loading states here if you want!
    // e.g., _isLoading = true; notifyListeners();

    bool isSuccess = await _servicesService.saveServiceDetails(data, serviceId);

    // _isLoading = false; notifyListeners();
    return isSuccess;
  }
}