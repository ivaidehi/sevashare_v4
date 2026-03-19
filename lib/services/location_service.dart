import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  // Configuration constants
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10, // Update if moved more than 10 meters
  );

  /// Ensures location permissions are granted, otherwise throws an error or handles it
  static Future<bool> ensurePermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Fetches the current location and returns a formatted address string with detailed information
  static Future<Map<String, dynamic>?> getUserAddressWithDetails() async {
    try {
      bool hasPermission = await ensurePermissions();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final addressData = {
          'fullAddress': _formatAddress(place),
          'street': place.street ?? '',
          'locality': place.locality ?? '',
          'subLocality': place.subLocality ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'subAdministrativeArea': place.subAdministrativeArea ?? '',
          'postalCode': place.postalCode ?? '',
          'country': place.country ?? '',
          'isoCountryCode': place.isoCountryCode ?? '',
          'name': place.name ?? '',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now(),
        };

        // Automatically store in Firestore if user is logged in
        await _saveLocationToFirestore(addressData);

        return addressData;
      }

      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  static Future<void> _saveLocationToFirestore(Map<String, dynamic> addressData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'detected_locations': FieldValue.arrayUnion([
            {
              'address': addressData['fullAddress'],
              'latitude': addressData['latitude'],
              'longitude': addressData['longitude'],
              'timestamp': FieldValue.serverTimestamp(),
            }
          ]),
          'last_known_location': addressData['fullAddress'], // Keep a quick reference
        });
      } catch (e) {
        print('Error saving location to Firestore: $e');
      }
    }
  }

  /// Returns formatted address string
  static Future<String?> getUserAddress() async {
    try {
      var addressDetails = await getUserAddressWithDetails();
      return addressDetails?['fullAddress'];
    } catch (e) {
      return null;
    }
  }

  /// Helper method to format address
  static String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
    if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
    if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
    return addressParts.join(', ');
  }
}
