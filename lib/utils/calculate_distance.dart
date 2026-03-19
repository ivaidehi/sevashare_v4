import 'dart:math';

class CalculateDistance {
  /// Calculates the distance between two points (latitude and longitude) using the Haversine formula.
  /// Returns the distance in kilometers.
  static double calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return -1.0; // Return -1 to indicate invalid coordinates
    }

    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Formats the distance into a user-friendly string (e.g., "1.2 km" or "800 m").
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 0) return 'N/A';
    
    if (distanceInKm < 1) {
      // If less than 1 km, show in meters
      int meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else {
      // Show in kilometers with one decimal place
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }
}
