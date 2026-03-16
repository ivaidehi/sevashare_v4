import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/auth_screens/login_screen.dart';
import 'package:sevashare_v4/providers/user_provider.dart';
import 'package:sevashare_v4/screens/add_rentals_screen.dart';
import 'package:sevashare_v4/screens/add_service_screen.dart';
import 'package:sevashare_v4/screens/bookings_screen.dart';
import 'package:sevashare_v4/screens/rentals_screen.dart';
import 'package:sevashare_v4/custom_widgets/custom_navbar.dart';
import 'package:sevashare_v4/screens/profile_screen.dart';
import 'package:sevashare_v4/screens/services_screen.dart';
import 'package:sevashare_v4/services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sevashare_v4/styles/appstyles.dart';


import 'auth_screens/AuthWrapper.dart';
import 'auth_screens/create_account_screen.dart';
import 'auth_screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SevaShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.dmSansTextTheme(),
        scaffoldBackgroundColor: AppStyles.bgColor,
      ),
      home: const AuthWrapper(), // Changed to AuthWrapper
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/create_acc': (context) => const CreateAccountScreen(),
        '/login': (context) => const LoginScreen(),
        '/bottom_nav_bar': (context) => const CustomNavBar(),
        '/services_screen': (context) => const ServicesScreen(),
        '/rentals_screen': (context) => const RentalsScreen(),
        '/bookings_screen': (context) => const BookingsScreen(),
        '/profile_screen': (context) => const ProfileScreen(),
        '/add_service': (context) => const AddServiceScreen(),
        '/add_rental_item': (context) => const AddRentalItemScreen(),
      },
    );
  }
}