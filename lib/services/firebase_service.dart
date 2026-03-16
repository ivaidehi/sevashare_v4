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
class StoreAllServiceInfo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to save form data to Firestore
  Future<bool> saveServiceDetails(Map<String, dynamic> serviceData) async {
    try {
      // Use the UID as the Document ID instead of letting Firebase generate a random one
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await _db.collection('service_providers').doc(uid).set(serviceData);
      return true;
    } catch (e) {
      print('Error saving services data: $e');
      return false;
    }
  }
}

// 📌 To store rental items and their owner details in firebase firestore
class StoreAllRentalsInfo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to save form data to Firestore
  Future<bool> saveRentalsDetails(Map<String, dynamic> rentalsData) async {
    try {
      // Storing data in a collection named 'service_providers'
      // It auto-generates a unique Document ID for this entry
      await _db.collection('rentals').add(rentalsData);
      return true;
    } catch (e) {
      // Log the error for debugging
      print('Error saving rentals data to Firestore: $e');
      return false;
    }
  }
}