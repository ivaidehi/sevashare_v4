import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/backend_services.dart';


class RentalsProvider extends ChangeNotifier {
  // ==========================================
  // 1. STATE VARIABLES
  // ==========================================
  List<Map<String, dynamic>> _myRentalsList = [];
  bool _isLoading = true;

  // Initialize your service
  final StoreAllRentalsInfo _rentalsService = StoreAllRentalsInfo();

  // ==========================================
  // 2. GETTERS
  // ==========================================
  List<Map<String, dynamic>> get myRentalsList => _myRentalsList;
  bool get isLoading => _isLoading;

  RentalsProvider() {
    _listenToRentalsData();
  }

  // ==========================================
  // 3. READ DATA (Real-time Listener)
  // ==========================================
  void _listenToRentalsData() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('rentals')
          .doc(uid)
          .collection('items')
          .orderBy('created_at', descending: true)
          .snapshots()
          .listen((snapshot) {
        _myRentalsList = snapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  // ==========================================
  // 4. WRITE DATA
  // ==========================================

  // 1. Fetch the ID using the service layer
  String generateRentalItemId(String uid) {
    return _rentalsService.getRentalId(uid);
  }
}
