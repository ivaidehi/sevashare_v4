import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/providers/user_provider.dart';
import 'package:sevashare_v4/screens/add_rentals_screen.dart';
import 'package:sevashare_v4/screens/add_service_screen.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../styles/appstyles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 1. Create an instance of your AuthService at the top of your State class
  final AuthService _authService = AuthService();
  late final userProvider = context.watch<UserProvider>();

  String _locationAddress = 'Detect Location';
  bool _isLoadingLocation = false;


  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  String _userType = 'user'; // Default fallback
  String _userMail = ' '; // Default fallback
  String _userContact = ' '; // Default fallback

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    // Start loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. You can also use the currentUser getter from your AuthService!
      final user = _authService.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'No user logged in.';
          _isLoading = false;
        });
        return;
      }

      // 3. USE YOUR AUTHSERVICE METHOD HERE
      final Map<String, dynamic>? data = await _authService.getUserData(
        user.uid,
      );

      // Check if data exists
      if (data == null) {
        setState(() {
          _errorMessage = 'User profile not found.';
          _isLoading = false;
        });
        return;
      }

      // Extract and save the data to your state variables
      setState(() {
        _userData = data;
        _userType = _userData?['userType'] ?? 'user';
        _userMail = _userData?['email'] ?? ' ';
        _userContact = _userData?['mobile'] ?? ' ';
        _isLoading = false; // Stop loading
      });
    } catch (e) {
      // Handle any unexpected errors
      setState(() {
        _errorMessage = 'Error loading profile data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'Profile',
      //     style: TextStyle(
      //       fontSize: 24,
      //       fontWeight: FontWeight.bold,
      //       color: AppStyles.primaryColor,
      //     ),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: IconThemeData(
      //     color: AppStyles.primaryColor,
      //   ),
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              // User Header Section
              Container(
                // height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppStyles.primaryColor, AppStyles.secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Pattern (Optional)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Profile Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with White Border
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'JD',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // User Info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProvider.fullName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // PROFESSION & DATE ROW
                              Row(
                                children: [
                                  Icon(
                                    _userType == 'service_provider'
                                        ? Icons.work_outline
                                        : Icons.person,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    userProvider.profession,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Joined 5 Feb 2026',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              //User Info Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          'User Details',
                          style: AppStyles.subHeadLineStyle.copyWith(
                            fontSize: 18,
                            color: AppStyles.primaryColor,
                          ),
                        ),
                      ),

                      _buildProfileItem(
                        icon: Icons.email_outlined,
                        title: _userMail,
                        suffixIcon: Icons.edit,
                        onTap: () {
                          // Navigate to add service screen
                        },
                      ),
                      _buildProfileItem(
                        icon: Icons.phone_outlined,
                        title: _userContact,
                        suffixIcon: Icons.edit,
                        onTap: () {
                          // Navigate to add rental item settings
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppStyles.secondaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isLoadingLocation
                                ? null
                                : () async {
                              setState(() => _isLoadingLocation = true);
                              String? address = await LocationService.getUserAddress();
                              setState(() {
                                _locationAddress = address ?? 'Could not detect location';
                                _isLoadingLocation = false;
                              });
                            },
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.center, // Centers the group
                              mainAxisSize: MainAxisSize.min,            // Pulls icon and text together
                              children: [
                                Icon(
                                  (_locationAddress == 'Detect Location' || _isLoadingLocation)
                                      ? Icons.my_location_outlined
                                      : Icons.location_on_outlined, // Swapped to filled icon for better 'detected' visual
                                  color: AppStyles.secondaryColor,
                                  size: 25,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _isLoadingLocation ? 'Detecting...' : _locationAddress,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: AppStyles.primaryColor,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // _buildProfileItem(
                      //   icon: Icons.location_on_outlined,
                      //   title: _isLoadingLocation ? 'Detecting...' : _locationAddress, // Update UI dynamically
                      //   suffixIcon: Icons.my_location,
                      //   onTap: () async {
                      //     // 1. Set loading state
                      //     setState(() {
                      //       _isLoadingLocation = true;
                      //     });
                      //
                      //     // 2. Call our new service
                      //     String? address = await LocationService.getUserAddress();
                      //
                      //     // 3. Update the UI with the result
                      //     setState(() {
                      //       _locationAddress = address ?? 'Could not detect location';
                      //       _isLoadingLocation = false;
                      //     });
                      //   },
                      // )
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 24),

              // Services & Rentals Section
              if (_userType == 'service_provider') ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            'Service & Rentals',
                            style: AppStyles.subHeadLineStyle.copyWith(
                              fontSize: 18,
                              color: AppStyles.primaryColor,
                            ),
                          ),
                        ),

                        // Services & Rentals Items
                        _buildProfileItem(
                          icon: Icons.person_search,
                          title: 'Add Service',
                          suffixIcon: Icons.add_circle_outline,
                          onTap: () {
                            // Navigate to add service screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddServiceScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileItem(
                          icon: Icons.category,
                          title: 'Add Rental Item',
                          suffixIcon: Icons.add_circle_outline,
                          onTap: () {
                            // Navigate to add rental item screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddRentalItemScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Account Settings Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          'Account Settings',
                          style: AppStyles.subHeadLineStyle.copyWith(
                            fontSize: 18,
                            color: AppStyles.primaryColor,
                          ),
                        ),
                      ),

                      // Settings Items
                      // _buildProfileItem(
                      //   icon: Icons.person_outline,
                      //   title: 'Edit Profile',
                      //   suffixIcon: Icons.arrow_forward_ios,
                      //   onTap: () {
                      //     // Navigate to edit profile screen
                      //   },
                      // ),
                      _buildProfileItem(
                        icon: Icons.light_mode_outlined,
                        title: 'Appearance',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {
                          // Navigate to notifications settings
                        },
                      ),
                      _buildProfileItem(
                        icon: Icons.security_outlined,
                        title: 'Privacy & Security',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {
                          // Navigate to privacy settings
                        },
                      ),
                      _buildProfileItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {
                          // Navigate to help center
                        },
                      ),
                      _buildProfileItem(
                        icon: Icons.info_outline,
                        title: 'About App',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {
                          // Navigate to about screen
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Log Out Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildProfileItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  isLogout: true,
                  suffixIcon: Icons.arrow_forward_ios,
                  onTap: () {
                    // Handle logout
                    _showLogoutDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 15),

              // Delete Account
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildProfileItem(
                  icon: Icons.delete_outlined,
                  title: 'Delete Account',
                  isLogout: true,
                  suffixIcon: Icons.arrow_forward_ios,
                  onTap: () {
                    // Handle logout
                    // _showLogoutDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required IconData suffixIcon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout ? Colors.red : AppStyles.secondaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLogout ? Colors.red : AppStyles.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                suffixIcon,
                size: 17,
                color: isLogout
                    ? Colors.red.withOpacity(0.5)
                    : AppStyles.secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final AuthService _authService = AuthService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out',
          style: TextStyle(
            color: AppStyles.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppStyles.primaryColor.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppStyles.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Perform logout action
              try {
                // 3. Call the method
                await _authService.signOut();

                // 4. Navigate the user back to the Login Screen
                if (context.mounted) {
                  // Adjust '/login' to match your actual route name
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                // 5. Handle any errors (like showing a snackbar)
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
              // Navigate to login screen or clear session
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
