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
