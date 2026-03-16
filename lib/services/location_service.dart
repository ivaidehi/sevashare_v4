import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Configuration constants
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.best, // Best accuracy for location detection
    distanceFilter: 0, // Get all position updates (no filtering)
    timeLimit: Duration(seconds: 10), // Timeout after 10 seconds
  );

  /// Fetches the current location with high accuracy and returns Position object
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Location services are disabled. Please enable them.');
      }

      // 2. Check and request permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      // 3. Get current position with best accuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Gets current position with last known location as fallback
  static Future<Position?> getCurrentPositionWithFallback() async {
    try {
      // Try to get fresh position first
      Position? position = await getCurrentPosition();

      if (position != null) {
        return position;
      }

      // Fallback to last known position
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        print('Using last known position from: ${lastPosition.timestamp}');
        return lastPosition;
      }

      throw Exception('No position available');
    } catch (e) {
      print('Error getting position with fallback: $e');
      return null;
    }
  }

  /// Gets detailed location data including accuracy
  static Future<Map<String, dynamic>?> getDetailedLocation() async {
    try {
      Position? position = await getCurrentPosition();

      if (position == null) {
        return null;
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy, // Accuracy in meters
        'altitude': position.altitude,
        'heading': position.heading,
        'timestamp': position.timestamp,
        'isMocked': position.isMocked, // Check if location is mocked
      };
    } catch (e) {
      print('Error getting detailed location: $e');
      return null;
    }
  }

  /// Fetches the current location and returns a formatted address string with detailed information
  static Future<Map<String, dynamic>?> getUserAddressWithDetails() async {
    try {
      Position? position = await getCurrentPosition();

      if (position == null) {
        return null;
      }

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Create detailed address object
        return {
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
          'accuracy': position.accuracy,
        };
      }

      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  /// Returns formatted address string
  static Future<String?> getUserAddress() async {
    try {
      var addressDetails = await getUserAddressWithDetails();
      return addressDetails?['fullAddress'] ?? 'Address not found.';
    } catch (e) {
      return 'Failed to get location: $e';
    }
  }

  /// Listen to location updates (useful for tracking)
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: null,
      ),
    );
  }

  /// Check if location is accurate enough based on desired accuracy
  static bool isLocationAccurate(Position position, double desiredAccuracyInMeters) {
    return position.accuracy <= desiredAccuracyInMeters;
  }

  /// Helper method to format address
  static String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }
}