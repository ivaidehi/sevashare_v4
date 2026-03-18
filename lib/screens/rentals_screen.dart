import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/screens/services_screen.dart';
import '../custom_widgets/custom_appbar.dart';
import '../providers/rentals_provider.dart';
import '../styles/appstyles.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - 60) / 2;
    final rentalsProvider = context.watch<RentalsProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: "Rentals",
        onBackPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServicesScreen()),
          );
        },
      ),
      backgroundColor: AppStyles.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 15),

              // ================= SEARCH BAR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search rental items...',
                      border: InputBorder.none,
                      prefixIcon:
                      Icon(Icons.search, color: AppStyles.primaryColor),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ================= MY RENTALS SECTION =================
              _buildMyRentalsSection(rentalsProvider),

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
                        icon: Icons.home, label: 'Home', color: Colors.blue),
                    _buildCategoryItem(
                        icon: Icons.build, label: 'Tools', color: Colors.orange),
                    _buildCategoryItem(
                        icon: Icons.electrical_services,
                        label: 'Electronics',
                        color: Colors.green),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= RENTAL ITEMS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Available Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRentalCard(
                      width: cardWidth,
                      name: 'Drill Machine',
                      category: 'Tool',
                      price: '\$10/day',
                      owner: 'Rahul Sharma',
                      condition: 'Good',
                      distance: '1.5 km',
                      imageUrl:
                      'https://images.unsplash.com/photo-1597852074816-d933c7d2b988',
                    ),
                    _buildRentalCard(
                      width: cardWidth,
                      name: 'Vacuum Cleaner',
                      category: 'Home',
                      price: '\$8/day',
                      owner: 'Priya Patel',
                      condition: 'Excellent',
                      distance: '2.2 km',
                      imageUrl:
                      'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRentalCard(
                      width: cardWidth,
                      name: 'DSLR Camera',
                      category: 'Electronics',
                      price: '\$20/day',
                      owner: 'Amit Verma',
                      condition: 'Very Good',
                      distance: '3.0 km',
                      imageUrl:
                      'https://images.unsplash.com/photo-1516035069371-29a1b244cc32',
                    ),
                    _buildRentalCard(
                      width: cardWidth,
                      name: 'Ladder',
                      category: 'Tool',
                      price: '\$5/day',
                      owner: 'Sanjay Mehta',
                      condition: 'Good',
                      distance: '1.8 km',
                      imageUrl:
                      'https://images.unsplash.com/photo-1503387762-592deb58ef4e',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MY RENTALS SECTION =================
  Widget _buildMyRentalsSection(RentalsProvider rentalsProvider) {
    if (rentalsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rentalsProvider.myRentalsList.isEmpty) {
      return const SizedBox.shrink();
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth * 0.45;

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
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rentalsProvider.myRentalsList.length,
            itemBuilder: (context, index) {
              final item = rentalsProvider.myRentalsList[index];
              final List<dynamic> images = item['item_images'] ?? [];
              final String imageUrl = images.isNotEmpty ? images[0] : '';
              final String name = item['item_name'] ?? 'No Name';
              final String category = item['category'] ?? 'General';
              final double rentPerDay = (item['rent_per_day'] ?? 0.0).toDouble();
              final String owner = item['owner_name'] ?? 'Me';

              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: _buildRentalCard(
                  width: cardWidth,
                  name: name,
                  category: category,
                  price: 'Rs.$rentPerDay/day',
                  owner: owner,
                  condition: 'N/A',
                  distance: '0 km',
                  imageUrl: imageUrl,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ================= CATEGORY ITEM =================
  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppStyles.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ================= RENTAL CARD =================
  Widget _buildRentalCard({
    required double width,
    required String name,
    required String category,
    required String price,
    required String owner,
    required String condition,
    required String distance,
    required String imageUrl,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 90,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),

          // DETAILS
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                Text(
                  category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 4),

                Text(
                  "Owner: $owner",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  "Condition: $condition",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),

                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      distance,
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  price,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
