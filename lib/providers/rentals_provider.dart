import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/backend_services.dart';


class RentalsProvider extends ChangeNotifier {
  // ==========================================
  // 1. STATE VARIABLES
  // ==========================================
  List<Map<String, dynamic>> _myRentalsList = [];
  List<Map<String, dynamic>> _allRentalsList = [];
  
  bool _isLoading = true;
  bool _isAllRentalsLoading = true;

  // Initialize your service
  final StoreAllRentalsInfo _rentalsService = StoreAllRentalsInfo();

  // ==========================================
  // 2. GETTERS
  // ==========================================
  List<Map<String, dynamic>> get myRentalsList => _myRentalsList;
  List<Map<String, dynamic>> get allRentalsList => _allRentalsList;
  
  bool get isLoading => _isLoading;
  bool get isAllRentalsLoading => _isAllRentalsLoading;

  RentalsProvider() {
    _listenToRentalsData();
    _listenToAllRentals();
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

  void _listenToAllRentals() {
    // Collection Group query to fetch all 'items' sub-collections across all rental owners
    FirebaseFirestore.instance
        .collectionGroup('items')
        .snapshots()
        .listen((snapshot) {
      
      _allRentalsList = snapshot.docs.map((doc) => doc.data()).toList();

      _allRentalsList.sort((a, b) {
        String nameA = (a['item_name'] ?? '').toString().toLowerCase();
        String nameB = (b['item_name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
      
      _isAllRentalsLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error fetching all rentals: $error");
      _isAllRentalsLoading = false;
      notifyListeners();
    });
  }

  // ==========================================
  // 4. WRITE DATA
  // ==========================================

  // 1. Fetch the ID using the service layer
  String generateRentalItemId(String uid) {
    return _rentalsService.getRentalId(uid);
  }
}
