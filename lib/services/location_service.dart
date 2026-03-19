import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  // Caching variables to store previously fetched address and minimize API calls
  static Map<String, dynamic>? _cachedAddress;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Expose cache for immediate UI updates
  static Map<String, dynamic>? get cachedAddress => _cachedAddress;

  // Configuration constants - Optimized for faster response
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high, // Changed from 'best' to 'high' for faster lock without significant loss in address accuracy
    distanceFilter: 10, // Update if moved more than 10 meters
  );

  /// Ensures location permissions are granted, otherwise returns false
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

  /// Fetches the current location and returns a formatted address string with detailed information.
  /// Optimized with caching and background processing to improve perceived performance.
  static Future<Map<String, dynamic>?> getUserAddressWithDetails({bool saveToFirestore = true}) async {
    try {
      // 1. Immediate Cache Check: Return cached data if available and fresh
      if (_cachedAddress != null && _lastFetchTime != null) {
        if (DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
          return _cachedAddress;
        }
      }

      bool hasPermission = await ensurePermissions();
      if (!hasPermission) return _cachedAddress; // Fallback to cache if permission denied but we have old data

      // 2. Faster Location Fetching: Try last known position first as it's nearly instantaneous
      Position? position = await Geolocator.getLastKnownPosition();
      
      // 3. If no last known position or it's older than 5 minutes, fetch fresh current position
      if (position == null || 
          DateTime.now().difference(position.timestamp) > const Duration(minutes: 5)) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: _locationSettings,
        ).timeout(const Duration(seconds: 5), onTimeout: () async {
          // Fallback to last known if current position takes too long (e.g., weak GPS signal)
          return await Geolocator.getLastKnownPosition() ?? 
                 await Geolocator.getCurrentPosition(
                   locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
                 );
        });
      }

      // 4. Reverse geocoding (Network call) with timeout to prevent long hangs
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5), onTimeout: () => []);

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

        // Update local cache for subsequent calls
        _cachedAddress = addressData;
        _lastFetchTime = DateTime.now();

        // 5. Performance Optimization: Save to Firestore in background (don't await)
        if (saveToFirestore) {
          _saveLocationToFirestore(addressData);
        }

        return addressData;
      }

      return _cachedAddress; // Fallback to cache if geocoding fails
    } catch (e) {
      print('Error getting address: $e');
      return _cachedAddress; // Fallback to cache on error
    }
  }

  /// Geocodes a string address into coordinates (latitude, longitude)
  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations[0].latitude,
          'longitude': locations[0].longitude,
        };
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }

  /// Async background task to save location data to Firestore.
  /// Automatically removes duplicate entries for the same address to keep history clean.
  static Future<void> _saveLocationToFirestore(Map<String, dynamic> addressData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();
        
        List<dynamic> detectedLocations = [];
        if (docSnapshot.exists && docSnapshot.data() != null && docSnapshot.data()!['detected_locations'] != null) {
          detectedLocations = List.from(docSnapshot.data()!['detected_locations']);
        }

        // New location entry
        final newEntry = {
          'address': addressData['fullAddress'],
          'latitude': addressData['latitude'],
          'longitude': addressData['longitude'],
          'timestamp': DateTime.now(),
        };

        // 📌 Delete duplicate entries if found automatically
        // Filter out any existing entries with the same address to avoid redundant history items
        detectedLocations.removeWhere((item) => item is Map && item['address'] == addressData['fullAddress']);
        
        // Add the latest detection to the history
        detectedLocations.add(newEntry);

        // Keep the history manageable (limit to last 20 unique locations)
        if (detectedLocations.length > 20) {
          detectedLocations.removeAt(0);
        }

        await docRef.update({
          'detected_locations': detectedLocations,
          'last_known_location': addressData['fullAddress'],
          'latitude': addressData['latitude'],
          'longitude': addressData['longitude'],
          'last_location_update': FieldValue.serverTimestamp(),
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
