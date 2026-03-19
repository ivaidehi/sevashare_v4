import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../styles/appstyles.dart';

class DetectLocationField extends StatefulWidget {
  final Function(Map<String, dynamic> addressDetails) onLocationDetected;

  const DetectLocationField({
    super.key,
    required this.onLocationDetected,
  });

  @override
  State<DetectLocationField> createState() => _DetectLocationFieldState();
}

class _DetectLocationFieldState extends State<DetectLocationField> {
  bool _isLoading = false;

  Future<void> _handleDetectLocation() async {
    // 1. Immediate UI update from cache (even if potentially stale)
    // This improves perceived performance significantly.
    final cache = LocationService.cachedAddress;
    if (cache != null) {
      widget.onLocationDetected(cache);
      // We still continue to fetch fresh location in the background if needed.
    }

    setState(() => _isLoading = true);
    try {
      // 2. Optimized fetch: uses last known position and high accuracy instead of best
      final addressDetails = await LocationService.getUserAddressWithDetails();
      
      if (addressDetails != null) {
        // 3. Update with fresh data if it differs from cache
        widget.onLocationDetected(addressDetails);
      } else if (cache == null) {
        // Only show error if we have no data at all (neither cache nor fresh)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not detect location. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppStyles.secondaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _handleDetectLocation,
            icon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.my_location, color: AppStyles.primaryColor),
            label: Text(
              _isLoading ? 'Detecting...' : 'Detect Location',
              style: TextStyle(color: AppStyles.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
