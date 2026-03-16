import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}

// 📌 To store service_provider and their service details in firebase firestore
// 📌 To store service_provider and their service details in firebase firestore
class StoreAllServiceInfo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Helper to generate the Service ID cleanly
  String getNewServiceId(String uid) {
    return _db
        .collection('service_providers')
        .doc(uid)
        .collection('services')
        .doc()
        .id;
  }

  // 2. Your existing save function (updated to accept the generated ID)
  Future<bool> saveServiceDetails(Map<String, dynamic> serviceData, String serviceId) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await _db
          .collection('service_providers')
          .doc(uid)
          .collection('services')
          .doc(serviceId) // Use the generated ID here
          .set(serviceData);

      return true;
    } catch (e) {
      print('Error saving services data: $e');
      return false;
    }
  }
}

// 📌 To store rental items and their owner details in firebase firestore
// Inside your firebase_service.dart file
class StoreAllRentalsInfo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Helper to generate the ID cleanly
  String getRentalId(String uid) {
    return _db.collection('rentals').doc(uid).collection('items').doc().id;
  }

  // 2. Your existing save function (updated to accept the generated ID)
  Future<bool> saveRentalsDetails(Map<String, dynamic> rentalsData, String itemId) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await _db
          .collection('rentals')
          .doc(uid)
          .collection('items')
          .doc(itemId) // Use the generated ID here
          .set(rentalsData);

      return true;
    } catch (e) {
      print('Error saving rentals data to Firestore: $e');
      return false;
    }
  }
}