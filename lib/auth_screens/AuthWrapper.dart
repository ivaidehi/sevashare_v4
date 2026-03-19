import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sevashare_v4/custom_widgets/custom_navbar.dart';
import 'package:sevashare_v4/services/location_service.dart';
import 'package:sevashare_v4/screens/location_permission_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'create_account_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isFirstTime = true;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  User? _cachedUser;
  String? _cachedUserType;
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();
    _isFirstTime = _prefs.getBool('isFirstTime') ?? true;
    _cachedUser = FirebaseAuth.instance.currentUser;

    // Check location permission
    _locationPermissionGranted = await LocationService.ensurePermissions();

    if (_cachedUser != null) {
      _cachedUserType = _prefs.getString('userType_${_cachedUser!.uid}');
      _fetchUserTypeInBackground(_cachedUser!.uid);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserTypeInBackground(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final userType = data['userType'] ?? 'user';
          await _prefs.setString('userType_$uid', userType);
          if (mounted) {
            setState(() {
              _cachedUserType = userType;
            });
          }
        }
      }
    } catch (e) {
      print('Background user type fetch error: $e');
    }
  }

  Future<void> _markAsNotFirstTime() async {
    await _prefs.setBool('isFirstTime', false);
    if (mounted) {
      setState(() {
        _isFirstTime = false;
      });
    }
  }

  Future<String> _getUserType(String uid) async {
    if (_cachedUserType != null) return _cachedUserType!;
    final cachedType = _prefs.getString('userType_$uid');
    if (cachedType != null) return cachedType;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final userType = data?['userType'] ?? 'user';
        await _prefs.setString('userType_$uid', userType);
        return userType;
      }
      return 'user';
    } catch (e) {
      return 'user';
    }
  }

  Widget _buildSplashScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSplashScreen();

    // Mandatory Location Check
    if (!_locationPermissionGranted) {
      return LocationPermissionScreen(
        onPermissionGranted: () {
          setState(() {
            _locationPermissionGranted = true;
          });
        },
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: _cachedUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return _isFirstTime
              ? OnboardingScreen(onComplete: _markAsNotFirstTime)
              : const LoginScreen();
        }

        if (_cachedUserType != null || _prefs.getString('userType_${user.uid}') != null) {
          return const CustomNavBar();
        }

        return FutureBuilder<String>(
          future: _getUserType(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return _buildSplashScreen();
            }
            return const CustomNavBar();
          },
        );
      },
    );
  }
}
