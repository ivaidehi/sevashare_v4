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
  List<Map<String, dynamic>> _userBookings = [];
  List<Map<String, dynamic>> _providerBookings = [];

  bool _isLoading = true;
  bool _isAllRentalsLoading = true;

  // Initialize your service
  final StoreAllRentalsInfo _rentalsService = StoreAllRentalsInfo();
  final BookingService _bookingService = BookingService();

  // ==========================================
  // 2. GETTERS
  // ==========================================
  List<Map<String, dynamic>> get myRentalsList => _myRentalsList;
  List<Map<String, dynamic>> get allRentalsList => _allRentalsList;
  List<Map<String, dynamic>> get userBookings => _userBookings;
  List<Map<String, dynamic>> get providerBookings => _providerBookings;

  bool get isLoading => _isLoading;
  bool get isAllRentalsLoading => _isAllRentalsLoading;

  // ==========================================
  // 3. CONSTRUCTOR
  // ==========================================
  RentalsProvider() {
    _listenToRentalsData();
    _listenToAllRentals();
    fetchUserBookings();
    fetchProviderBookings(); // ✅ FIXED
  }

  // ==========================================
  // 4. READ DATA (Real-time Listener)
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
  // 5. FETCH USER BOOKINGS
  // ==========================================
  void fetchUserBookings() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      FirebaseFirestore.instance
          .collection('bookings')
          .where('renter_id', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {

        _userBookings = snapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        notifyListeners();
      });
    }
  }

  // ==========================================
  // 6. FETCH PROVIDER BOOKINGS (🔥 MAIN FIX)
  // ==========================================
  void fetchProviderBookings() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: uid) // ✅ IMPORTANT
          .snapshots()
          .listen((snapshot) {

        print("Provider UID: $uid"); // Debug

        _providerBookings = snapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;

          print("Booking owner_id: ${data['owner_id']}"); // Debug

          return data;
        }).toList();

        notifyListeners();
      });
    }
  }

  // ==========================================
  // 7. GENERATE RENTAL ID
  // ==========================================
  String generateRentalItemId(String uid) {
    return _rentalsService.getRentalId(uid);
  }

  // ==========================================
  // 8. BOOK RENTAL
  // ==========================================
  Future<bool> bookRental(Map<String, dynamic> bookingData) async {
    try {
      bool success = await _bookingService.createRentalBooking(bookingData);
      return success;
    } catch (e) {
      print("Booking Error: $e");
      return false;
    }
  }

  // ==========================================
  // 9. UPDATE BOOKING STATUS
  // ==========================================
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingService.updateRentalBookingStatus(bookingId, newStatus);
  }
}