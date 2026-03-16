import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sevashare_v4/custom_widgets/custom_navbar.dart';
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
  User? _cachedUser;
  String? _cachedUserType;
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize SharedPreferences once
    _prefs = await SharedPreferences.getInstance();

    // Check first time immediately from cache
    _isFirstTime = _prefs.getBool('isFirstTime') ?? true;

    // Get cached user immediately
    _cachedUser = FirebaseAuth.instance.currentUser;

    // If user exists, try to get cached user type
    if (_cachedUser != null) {
      _cachedUserType = _prefs.getString('userType_${_cachedUser!.uid}');

      // Fetch user type in background without waiting
      _fetchUserTypeInBackground(_cachedUser!.uid);
    }

    // Show the UI immediately
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

          // Cache in SharedPreferences
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
      // Silently fail - we'll use cached or default value
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
    // First check cache
    if (_cachedUserType != null) {
      return _cachedUserType!;
    }

    final cachedType = _prefs.getString('userType_$uid');
    if (cachedType != null) {
      return cachedType;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final userType = data?['userType'] ?? 'user';

        // Cache for next time
        await _prefs.setString('userType_$uid', userType);
        return userType;
      }

      return 'user';
    } catch (e) {
      print('Error fetching user type: $e');
      return 'user';
    }
  }

  Widget _buildSplashScreen() {
    // This should match your app's branding
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your app logo here
            // Image.asset('assets/logo.png', height: 100),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show minimal loading
    if (_isLoading) {
      return _buildSplashScreen();
    }

    // Listen to auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: _cachedUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // No user logged in
        if (user == null) {
          return _isFirstTime
              ? OnboardingScreen(onComplete: _markAsNotFirstTime)
              : const LoginScreen();
        }

        // User is logged in - we need their type
        // If we have cached type, go directly to main screen
        if (_cachedUserType != null ||
            _prefs.getString('userType_${user.uid}') != null) {
          // Use cached type without waiting
          return const CustomNavBar();
        }

        // Need to fetch user type
        return FutureBuilder<String>(
          future: _getUserType(user.uid),
          builder: (context, snapshot) {
            // Show loading only if we truly have no data
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildSplashScreen();
            }

            // Once we have data (or if fetch fails), go to main screen
            return const CustomNavBar();
          },
        );
      },
    );
  }
}