import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';


// 📌 Initialize firebase service
class FirebaseServices {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}

// 📌 Select/pick images from device with optimization
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  // Pick single image with compression and resizing
  static Future<File?> pickSingleImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Limit size to optimize upload and loading speed
        maxHeight: 1024,
        imageQuality: 80, // Compress image
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error picking single image: $e");
    }
    return null;
  }


  // Pick multiple images with compression and resizing
  static Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return pickedFiles.map((e) => File(e.path)).toList();
    } catch (e) {
      print("Error picking multiple images: $e");
      return [];
    }
  }
}


// 📌 Upload images to ImgBB
class ImgBBService {
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';
  static const String _apiKey = 'acaf17dc0d62e42f7e5ab8a52bfef6d5';

  /// 🔹 Upload Single Image
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_baseUrl),
      );

      request.fields['key'] = _apiKey;

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);

        // ImgBB returns the direct URL. We could also store jsonData['data']['thumb']['url'] for faster loading of small cards.
        return jsonData['data']['url'];
      } else {
        print('❌ ImgBB Upload Failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ ImgBB Upload Error: $e');
      return null;
    }
  }

  /// 🔹 Upload Multiple Images
  static Future<List<String>> uploadMultipleImages(List<File> images) async {
    List<String> urls = [];

    for (File image in images) {
      final url = await uploadImage(image);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }
}


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
class StoreAllRentalsInfo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Helper to generate the ID cleanly
  String getRentalId(String uid) {
    return _db
        .collection('rentals')
        .doc(uid)
        .collection('items')
        .doc()
        .id;
  }

  // 2. Your existing save function (updated to accept the generated ID)
  Future<bool> saveRentalsDetails(Map<String, dynamic> rentalsData,
      String itemId) async {
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

// -----------------------------------------------------------------------------
// 📌 Booking Service for managing service bookings
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final docRef = _db.collection('bookings').doc();
      bookingData['bookingId'] = docRef.id;
      bookingData['bookingStatus'] = 'pending';
      bookingData['createdAt'] = FieldValue.serverTimestamp();
      bookingData['timestamp'] = FieldValue.serverTimestamp(); // For real-time sorting

      await docRef.set(bookingData);
      return true;
    } catch (e) { return false; }
  }

  // 📌 Acceptance Logic
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'bookingStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { print('Error accepting booking: $e'); }
  }

  // 📌 Real-time Stream for User
  // ✅ Removed .orderBy('timestamp') to avoid index error. Sorting is done client-side.
  Stream<QuerySnapshot> getBookingsForUser(String userUid) {
    return _db.collection('bookings')
        .where(Filter.or(
        Filter('userUid', isEqualTo: userUid),
        Filter('renter_id', isEqualTo: userUid)
    ))
        .snapshots();
  }

  // 📌 Real-time Stream for Provider
  // ✅ Removed .orderBy('timestamp') to avoid index error. Sorting is done client-side.
  Stream<QuerySnapshot> getBookingsForProvider(String providerId) {
    return _db.collection('bookings')
        .where(Filter.or(
        Filter('providerId', isEqualTo: providerId),
        Filter('owner_id', isEqualTo: providerId)
    ))
        .snapshots();
  }

  // 📌 Fetch Reviews for a Service
  Stream<QuerySnapshot> getServiceReviews(String providerId, String serviceId) {
    // Return empty stream if IDs are missing to prevent crash
    if (providerId.isEmpty || serviceId.isEmpty) {
      return const Stream.empty();
    }
    return _db.collection('service_providers')
        .doc(providerId)
        .collection('services')
        .doc(serviceId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 📌 Submit a Review
  Future<bool> submitReview(String providerId, String serviceId, Map<String, dynamic> reviewData) async {
    if (providerId.isEmpty || serviceId.isEmpty) {
      print('❌ Error: providerId or serviceId is empty');
      return false;
    }
    try {
      await _db.collection('service_providers')
          .doc(providerId)
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .add(reviewData);

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  // 📌 Rental specific booking methods
  Future<bool> createRentalBooking(Map<String, dynamic> bookingData) async {
    try {
      final docRef = _db.collection('bookings').doc();
      bookingData['booking_id'] = docRef.id;
      bookingData['createdAt'] = FieldValue.serverTimestamp();
      bookingData['timestamp'] = FieldValue.serverTimestamp();
      await docRef.set(bookingData);
      return true;
    } catch (e) { return false; }
  }

  Future<void> updateRentalBookingStatus(String bookingId, String newStatus) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        if (newStatus == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { print('Error updating rental booking status: $e'); }
  }

  // 📌 Rental Reviews
  Stream<QuerySnapshot> getRentalReviews(String ownerId, String itemId) {
    if (ownerId.isEmpty || itemId.isEmpty) return const Stream.empty();
    return _db.collection('rentals')
        .doc(ownerId)
        .collection('items')
        .doc(itemId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<bool> submitRentalReview(String ownerId, String itemId, Map<String, dynamic> reviewData) async {
    try {
      await _db.collection('rentals')
          .doc(ownerId)
          .collection('items')
          .doc(itemId)
          .collection('reviews')
          .add(reviewData);
      return true;
    } catch (e) {
      print('Error submitting rental review: $e');
      return false;
    }
  }
}
