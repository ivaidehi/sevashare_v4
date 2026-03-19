import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/custom_navbar.dart';
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
                      prefixIcon: Icon(Icons.search, color: AppStyles.primaryColor),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= MY RENTALS SECTION (Conditional) =================
              if (userProvider.userType == "service_provider")
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
                    _buildCategoryItem(icon: Icons.home, label: 'Home', color: Colors.blue),
                    _buildCategoryItem(icon: Icons.build, label: 'Tools', color: Colors.orange),
                    _buildCategoryItem(icon: Icons.electrical_services, label: 'Electronics', color: Colors.green),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= AVAILABLE RENTALS SECTION =================
              _buildAvailableRentalsSection(rentalsProvider),

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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: _buildShimmerLoadingRow(),
      );
    }

    if (rentalsProvider.myRentalsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 5),
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
            const SizedBox(height: 20),
          ],
        ),
      );
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

  // ================= AVAILABLE RENTALS SECTION =================
  Widget _buildAvailableRentalsSection(RentalsProvider rentalsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        rentalsProvider.isAllRentalsLoading
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShimmerLoadingGrid(),
              )
            : rentalsProvider.allRentalsList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("No rental items available."),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double cardWidth = (constraints.maxWidth - 20) / 2;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: rentalsProvider.allRentalsList.map((item) {
                            final List<dynamic> images = item['item_images'] ?? [];
                            final String imageUrl = images.isNotEmpty ? images[0] : '';
                            final String name = item['item_name'] ?? 'No Name';
                            final String category = item['category'] ?? 'General';
                            final double rentPerDay = (item['rent_per_day'] ?? 0.0).toDouble();
                            final String owner = item['owner_name'] ?? 'Unknown';

                            return _buildRentalCard(
                              width: cardWidth,
                              name: name,
                              category: category,
                              price: 'Rs.$rentPerDay/day',
                              owner: owner,
                              condition: 'N/A',
                              distance: 'N/A',
                              imageUrl: imageUrl,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildShimmerLoadingRow() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth * 0.45;
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: _buildRentalCardShimmer(width: cardWidth),
        ),
      ),
    );
  }

  Widget _buildShimmerLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 20) / 2;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: List.generate(4, (index) => _buildRentalCardShimmer(width: cardWidth)),
        );
      },
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
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 90,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 90,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
              memCacheHeight: 180,
              maxWidthDiskCache: 400,
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
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      distance,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _buildRentalCardShimmer({required double width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 50, height: 10, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 10, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 40, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
