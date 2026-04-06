import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/providers/service_provider.dart';
import 'package:sevashare_v4/providers/user_provider.dart';
import 'package:sevashare_v4/screens/add_rentals_screen.dart';
import 'package:sevashare_v4/screens/add_service_screen.dart';
import 'package:sevashare_v4/screens/saved_screen.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../styles/appstyles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String _locationAddress = 'Detect Location';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _autoDetectLocation();
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isLoadingLocation = true);
    String? address = await LocationService.getUserAddress();
    if (mounted) {
      setState(() {
        _locationAddress = address ?? 'Could not detect location';
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final serviceProvider = context.watch<ServiceProvider>();

    // Use UserProvider's loading state
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              // User Header Section
              Container(
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

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
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
                                userProvider.username.isNotEmpty
                                    ? userProvider.username.substring(0, 1).toUpperCase()
                                    : 'U',
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
                                // Use username from UserProvider
                                userProvider.username,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(
                                    userProvider.userType == 'service_provider'
                                        ? Icons.work_outline
                                        : Icons.person,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    // If service provider, show their profession, otherwise show user type
                                    userProvider.userType == 'service_provider'
                                        ? serviceProvider.profession
                                        : 'Member',
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
                                    userProvider.createdAt != null
                                        ? 'Joined ${userProvider.createdAt!.day} ${_getMonthName(userProvider.createdAt!.month)} ${userProvider.createdAt!.year}'
                                        : 'Joined Recently',
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

              // User Details Section
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
                        title: userProvider.email,
                        suffixIcon: Icons.edit,
                        onTap: () {},
                      ),
                      _buildProfileItem(
                        icon: Icons.phone_outlined,
                        title: userProvider.mobile,
                        suffixIcon: Icons.edit,
                        onTap: () {},
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (_locationAddress == 'Detect Location' || _isLoadingLocation)
                                      ? Icons.my_location_outlined
                                      : Icons.location_on_outlined,
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
                    ],
                  ),
                ),
              ),

              // Services & Rentals Section (Conditional)
              if (userProvider.userType == 'service_provider') ...[
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

                        _buildProfileItem(
                          icon: Icons.person_search,
                          title: 'Add Service',
                          suffixIcon: Icons.add_circle_outline,
                          onTap: () {
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

                      _buildProfileItem(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Saved ',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileItem(
                        icon: Icons.light_mode_outlined,
                        title: 'Appearance',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {},
                      ),
                      _buildProfileItem(
                        icon: Icons.security_outlined,
                        title: 'Privacy & Security',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {},
                      ),
                      _buildProfileItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {},
                      ),
                      _buildProfileItem(
                        icon: Icons.info_outline,
                        title: 'About App',
                        suffixIcon: Icons.arrow_forward_ios,
                        onTap: () {},
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
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
              try {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}