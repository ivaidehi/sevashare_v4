import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../styles/appstyles.dart';

class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const LocationPermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

// 1. Add WidgetsBindingObserver to detect when user returns to the app
class _LocationPermissionScreenState extends State<LocationPermissionScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // 2. Register the observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 3. Unregister the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. This fires whenever the app is resumed (e.g., returning from Settings)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentCheckPermission();
    }
  }

  /// Automatically checks status without showing loaders/snackbars unless necessary
  Future<void> _silentCheckPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      widget.onPermissionGranted();
    }
  }

  Future<void> _requestPermission() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please turn on your device location.'),
          backgroundColor: AppStyles.secondaryColor,
        ),
      );
      await Geolocator.openLocationSettings();
      // Logic stops here until user returns
      setState(() => _isChecking = false);
      return;
    }

    bool granted = await LocationService.ensurePermissions();

    if (granted) {
      widget.onPermissionGranted();
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is permanently denied. Please enable it in App Settings.'),
            backgroundColor: Colors.red,
          ),
        );
        await Geolocator.openAppSettings();
      }
    }

    if (mounted) setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    // UI remains the same...
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppStyles.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, size: 80, color: AppStyles.secondaryColor),
            ),
            const SizedBox(height: 40),
            Text(
              'Location Access Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppStyles.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'To provide you with the best services nearby, Seva Share needs access to your location. This is mandatory for using the app.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isChecking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Enable Location Access',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}