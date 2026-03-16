import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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