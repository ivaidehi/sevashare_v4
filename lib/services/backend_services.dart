import 'dart:async';
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
// 📌 Booking Service for managing service and rental bookings separately
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📌 Bookmark / Save Feature
  Future<void> toggleSaveItem(String userId, String itemId, String type, Map<String, dynamic> itemData) async {
    final docRef = _db.collection('users').doc(userId).collection('saved_items').doc(itemId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'itemId': itemId,
        'type': type,
        'itemData': itemData,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isItemSaved(String userId, String itemId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('saved_items')
        .doc(itemId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<QuerySnapshot> getSavedItems(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('saved_items')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // 📌 Service Bookings
  Future<bool> bookService(Map<String, dynamic> bookingData) async {
    try {
      final docRef = _db.collection('service_bookings').doc();
      bookingData['bookingId'] = docRef.id;
      bookingData['bookingStatus'] = 'pending';
      bookingData['createdAt'] = FieldValue.serverTimestamp();
      bookingData['timestamp'] = FieldValue.serverTimestamp();

      // 🔽 ADDED: Seen tracking fields
      bookingData['isSeenByProvider'] = false;
      bookingData['isSeenByUser'] = false;

      await docRef.set(bookingData);
      return true;
    } catch (e) { return false; }
  }

  // For backward compatibility while refactoring
  Future<bool> createBooking(Map<String, dynamic> bookingData) => bookService(bookingData);

  Future<void> acceptServiceBooking(String bookingId) async {
    try {
      await _db.collection('service_bookings').doc(bookingId).update({
        'bookingStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        // 🔽 UPDATED: Mark as unseen by user when accepted
        'isSeenByUser': false,
      });
    } catch (e) { print('Error accepting service booking: $e'); }
  }

  // For backward compatibility
  Future<void> acceptBooking(String bookingId) => acceptServiceBooking(bookingId);

  // 📌 Rejection Logic
  // 🔽 ADDED: Reject booking logic
  Future<void> rejectBooking(String bookingId) async {
    try {
      await _db.collection('service_bookings').doc(bookingId).update({
        'bookingStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        // 🔽 UPDATED: Mark as unseen by user when rejected
        'isSeenByUser': false,
      });
    } catch (e) { print('Error rejecting service booking: $e'); }
  }

  // 📌 Rental Bookings
  Future<bool> bookRental(Map<String, dynamic> bookingData) async {
    try {
      final docRef = _db.collection('rental_bookings').doc();
      bookingData['booking_id'] = docRef.id;
      bookingData['status'] = 'pending';
      bookingData['createdAt'] = FieldValue.serverTimestamp();
      bookingData['timestamp'] = FieldValue.serverTimestamp();

      // 🔽 ADDED: Seen tracking fields
      bookingData['isSeenByProvider'] = false;
      bookingData['isSeenByUser'] = false;

      await docRef.set(bookingData);
      return true;
    } catch (e) { return false; }
  }

  // For backward compatibility
  Future<bool> createRentalBooking(Map<String, dynamic> bookingData) => bookRental(bookingData);

  Future<void> updateRentalBookingStatus(String bookingId, String newStatus) async {
    try {
      await _db.collection('rental_bookings').doc(bookingId).update({
        'status': newStatus,
        if (newStatus == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
        // 🔽 UPDATED: Mark as unseen by user when status changes
        if (newStatus == 'accepted' || newStatus == 'rejected') 'isSeenByUser': false,
      });
    } catch (e) { print('Error updating rental booking status: $e'); }
  }

  // 📌 Mark bookings as seen logic
  // 🔽 ADDED: Mark notifications as seen by Provider
  Future<void> markAsSeenByProvider(String bookingId, {bool isRental = false}) async {
    try {
      String collection = isRental ? 'rental_bookings' : 'service_bookings';
      await _db.collection(collection).doc(bookingId).update({
        'isSeenByProvider': true,
      });
    } catch (e) { print('Error marking as seen by provider: $e'); }
  }

  // 🔽 ADDED: Mark notifications as seen by User
  Future<void> markAsSeenByUser(String bookingId, {bool isRental = false}) async {
    try {
      String collection = isRental ? 'rental_bookings' : 'service_bookings';
      await _db.collection(collection).doc(bookingId).update({
        'isSeenByUser': true,
      });
    } catch (e) { print('Error marking as seen by user: $e'); }
  }

  // 🔽 ADDED: Batch update to mark all notifications as seen
  Future<void> markAllAsSeen(String uid, bool isProvider) async {
    try {
      WriteBatch batch = _db.batch();

      // We check both collections because your architecture splits them
      List<String> collections = ['service_bookings', 'rental_bookings'];

      for (String coll in collections) {
        Query query = _db.collection(coll);
        if (isProvider) {
          String field = coll == 'service_bookings' ? 'providerId' : 'owner_id';
          query = query.where(field, isEqualTo: uid).where('isSeenByProvider', isEqualTo: false);
        } else {
          String field = coll == 'service_bookings' ? 'userUid' : 'renter_id';
          query = query.where(field, isEqualTo: uid).where('isSeenByUser', isEqualTo: false);
        }

        final snapshot = await query.get();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {
            isProvider ? 'isSeenByProvider' : 'isSeenByUser': true
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all as seen: $e');
    }
  }

  // 📌 Real-time Streams (Merged)
  Stream<List<DocumentSnapshot>> getBookingsForUser(String userUid) {
    final serviceStream = _db.collection('service_bookings')
        .where('userUid', isEqualTo: userUid)
        .snapshots();

    final rentalStream = _db.collection('rental_bookings')
        .where('renter_id', isEqualTo: userUid)
        .snapshots();

    return _mergeBookingStreams(serviceStream, rentalStream);
  }

  Stream<List<DocumentSnapshot>> getBookingsForProvider(String providerId) {
    final serviceStream = _db.collection('service_bookings')
        .where('providerId', isEqualTo: providerId)
        .snapshots();

    final rentalStream = _db.collection('rental_bookings')
        .where('owner_id', isEqualTo: providerId)
        .snapshots();

    return _mergeBookingStreams(serviceStream, rentalStream);
  }

  Stream<List<DocumentSnapshot>> _mergeBookingStreams(
      Stream<QuerySnapshot> s1, Stream<QuerySnapshot> s2) {
    final controller = StreamController<List<DocumentSnapshot>>();
    List<DocumentSnapshot> l1 = [];
    List<DocumentSnapshot> l2 = [];

    void emit() {
      if (!controller.isClosed) {
        controller.add([...l1, ...l2]);
      }
    }

    final sub1 = s1.listen((snap) { l1 = snap.docs; emit(); }, onError: controller.addError);
    final sub2 = s2.listen((snap) { l2 = snap.docs; emit(); }, onError: controller.addError);

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  // 📌 Fetch Reviews for a Service
  Stream<QuerySnapshot> getServiceReviews(String providerId, String serviceId) {
    if (providerId.isEmpty || serviceId.isEmpty) return const Stream.empty();
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
    if (providerId.isEmpty || serviceId.isEmpty) return false;
    try {
      await _db.collection('service_providers')
          .doc(providerId)
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .add(reviewData);
      return true;
    } catch (e) { return false; }
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