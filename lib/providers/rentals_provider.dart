import 'package:flutter/material.dart';
import '../services/firebase_service.dart';


class RentalsProvider extends ChangeNotifier {
  // Initialize your service
  final StoreAllRentalsInfo _rentalsService = StoreAllRentalsInfo();

  // 1. Fetch the ID using the service layer (No Firestore imports needed!)
  String generateRentalItemId(String uid) {
    return _rentalsService.getRentalId(uid);
  }


}