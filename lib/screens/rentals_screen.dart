import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/screens/view_all_rentals_screen.dart';
import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/custom_navbar.dart';
import '../custom_widgets/rental_cardlist.dart';
import '../providers/rentals_provider.dart';
import '../providers/user_provider.dart';
import '../styles/appstyles.dart';
import 'add_rentals_screen.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  @override
  Widget build(BuildContext context) {
    final rentalsProvider = context.watch<RentalsProvider>();
    final userProvider = context.watch<UserProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Rentals",
        onBackPressed: () {
          ChangeTabNotification(0).dispatch(context);
        },
        actionIcon: Icons.bookmark_border_rounded,
      ),
      backgroundColor: AppStyles.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(height: 15),

              // ================= SEARCH BAR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    // --- ADD BORDER HERE ---
                    border: Border.all(
                      color: AppStyles.primaryColor_light,
                      width: 0.3,
                    ),
                    // -----------------------
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3), // Slightly offset to make the border pop
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search rental items...',
                      border: InputBorder.none, // Keep this none since the Container handles the border
                      prefixIcon: Icon(Icons.search, color: AppStyles.primaryColor),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= MY RENTALS SECTION (Conditional) =================
              if (userProvider.userType == "service_provider")
                _buildMyRentalsSection(rentalsProvider, screenWidth),

              // ================= CATEGORIES =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildCategoryItem(
                      icon: Icons.grid_view,
                      label: 'All',
                      color: Colors.grey[700]!,
                      onTap: () => _navigateToViewAllRentals(null),
                    ),
                    _buildCategoryItem(
                      icon: Icons.home,
                      label: 'Home',
                      color: Colors.blue,
                      onTap: () => _navigateToViewAllRentals('Home'),
                    ),
                    _buildCategoryItem(
                      icon: Icons.build,
                      label: 'Tools',
                      color: Colors.orange,
                      onTap: () => _navigateToViewAllRentals('Tools'),
                    ),
                    _buildCategoryItem(
                      icon: Icons.electrical_services,
                      label: 'Electrical',
                      color: Colors.green,
                      onTap: () => _navigateToViewAllRentals('Electrical'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ================= AVAILABLE RENTALS SECTION =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToViewAllRentals(null),
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
              const SizedBox(height: 10),
              
              RentalCardGrid(
                items: rentalsProvider.allRentalsList,
                isLoading: rentalsProvider.isAllRentalsLoading,
              ),

              // const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToViewAllRentals(String? category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllRentalsScreen(category: category),
      ),
    );
  }

  // ================= MY RENTALS SECTION =================
  Widget _buildMyRentalsSection(RentalsProvider rentalsProvider, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Rental Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.primaryColor,
                ),
              ),
              if (rentalsProvider.myRentalsList.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppStyles.secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        if (rentalsProvider.myRentalsList.isEmpty && !rentalsProvider.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You haven't added any rental items yet.",
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
                          builder: (context) => const AddRentalItemScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_circle_outline, color: AppStyles.secondaryColor),
                    label: Text(
                      'Add Your First Rental Item',
                      style: TextStyle(
                        color: AppStyles.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppStyles.secondaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          RentalCardList(
            items: rentalsProvider.myRentalsList,
            screenWidth: screenWidth,
            isLoading: rentalsProvider.isLoading,
          ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
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
      ),
    );
  }
}