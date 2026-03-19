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
    setState(() => _isLoading = true);
    try {
      final addressDetails = await LocationService.getUserAddressWithDetails();
      if (addressDetails != null) {
        widget.onLocationDetected(addressDetails);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect location. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
        const Divider(height: 40, thickness: 1),
      ],
    );
  }
}
