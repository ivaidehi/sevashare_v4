import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/screens/view_all_services_screen.dart';
import 'package:sevashare_v4/screens/select_city_screen.dart';
import '../custom_widgets/service_provider_cardlist.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../styles/appstyles.dart';
import 'add_service_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _selectedCity = 'Mumbai';

  void _openCitySelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCityScreen(currentCity: _selectedCity),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedCity = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final userProvider = context.watch<UserProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 Top banner with greeting Hello Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello ${userProvider.username}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _openCitySelection,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Seva Share | $_selectedCity',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor_light,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search services, rentals...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppStyles.primaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 📌 My Services Section (Conditionally rendered based on userType)
          if (userProvider.userType == "service_provider") ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'My Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.primaryColor,
                ),
              ),
            ),

            // Dynamic List Rendering using refactored components
            serviceProvider.isLoading
                ? ServiceProviderCardList(
              providers: const [], // Empty list because isLoading is true
              screenWidth: screenWidth,
              isLoading: true,
            )
                : serviceProvider.myServicesList.isEmpty
                ? _buildEmptyServicesState(context) // Using a helper for the empty state
                : ServiceProviderCardList(
              providers: serviceProvider.myServicesList,
              screenWidth: screenWidth,
              isLoading: false,
            ),
          ],
          const SizedBox(height: 10),

          // 📌 Services Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              'Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppStyles.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Services Grid
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildServiceItem(
                  icon: Icons.grid_view,
                  label: 'All',
                  color: Colors.grey[700]!,
                  onTap: () => _navigateToViewAll(null),
                ),
                const SizedBox(width: 15),

                _buildServiceItem(
                  icon: Icons.plumbing,
                  label: 'Plumbing',
                  color: Colors.blue,
                  onTap: () => _navigateToViewAll('Plumbing'),
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.build,
                  label: 'Carpentry',
                  color: Colors.red,
                  onTap: () => _navigateToViewAll('Carpentry'),
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.electrical_services,
                  label: 'Electrical',
                  color: Colors.orange,
                  onTap: () => _navigateToViewAll('Electrical'),
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.cleaning_services,
                  label: 'Cleaning',
                  color: Colors.green,
                  onTap: () => _navigateToViewAll('Cleaning'),
                ),

              ],
            ),
          ),

          // 📌 Nearby Providers Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Providers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewAllCardsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppStyles.secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 10),
          ServiceProviderCardList(
            providers: serviceProvider.allServicesList,
            screenWidth: screenWidth,
            isLoading: serviceProvider.isAllProvidersLoading,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _navigateToViewAll(String? category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllCardsScreen(category: category),
      ),
    );
  }

  Widget _buildEmptyServicesState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "You haven't added any services yet.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddServiceScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.add_circle_outline,
                color: AppStyles.secondaryColor,
              ),
              label: Text(
                'Add Your First Service',
                style: TextStyle(
                  color: AppStyles.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppStyles.secondaryColor,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Icon(icon, size: 30, color: color)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppStyles.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}