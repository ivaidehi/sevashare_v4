import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';

class UserProvider with ChangeNotifier {
  // 1. STATE VARIABLES
  String _uid = "";
  String _username = "Username";
  String _email = "";
  String _mobile = "";
  String _userType = "user";
  bool _emailVerified = false;
  DateTime? _createdAt;
  String _lastKnownLocation = 'Detecting location...';

  // New Location Variables
  double? _latitude;
  double? _longitude;

  bool _isLoading = true;

  // 2. GETTERS
  String get uid => _uid;
  String get username => _username;
  String get email => _email;
  String get mobile => _mobile;
  String get userType => _userType;
  bool get emailVerified => _emailVerified;
  DateTime? get createdAt => _createdAt;
  bool get isLoading => _isLoading;
  String get lastKnownLocation => _lastKnownLocation;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  // Constructor starts listening to data
  UserProvider() {
    _listenToUserData();
  }

  // 3. READ DATA (Real-time Listener)
  void _listenToUserData() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;

            _uid = data['uid'] ?? '';
            _username = data['username'] ?? 'No Username';
            _email = data['email'] ?? '';
            _mobile = data['mobile'] ?? '';
            _userType = data['userType'] ?? 'user';
            _emailVerified = data['emailVerified'] ?? false;
            _lastKnownLocation = data['last_known_location'] ?? 'Location not set';
            
            // Fetch Lat/Long from user document
            _latitude = data['latitude'] != null ? (data['latitude'] as num).toDouble() : null;
            _longitude = data['longitude'] != null ? (data['longitude'] as num).toDouble() : null;

            if (data['createdAt'] != null) {
              _createdAt = (data['createdAt'] as Timestamp).toDate();
            }

            _isLoading = false;
            notifyListeners();
          }
        });

        // Automatically fetch and update location since permission is mandatory
        _autoUpdateLocation();
      } else {
        _resetState();
      }
    });
  }

  Future<void> _autoUpdateLocation() async {
    final addressDetails = await LocationService.getUserAddressWithDetails();
    if (addressDetails != null) {
      _lastKnownLocation = addressDetails['fullAddress'];
      // Update local state coordinates if they were just detected
      _latitude = addressDetails['latitude'];
      _longitude = addressDetails['longitude'];
      notifyListeners();
    }
  }

  void _resetState() {
    _uid = "";
    _username = "Username";
    _email = "";
    _mobile = "";
    _userType = "user";
    _emailVerified = false;
    _createdAt = null;
    _lastKnownLocation = 'Location not set';
    _latitude = null;
    _longitude = null;
    _isLoading = false;
    notifyListeners();
  }
}
