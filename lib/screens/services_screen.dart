import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/service_provider.dart';
import '../styles/appstyles.dart';


class ServicesScreen extends StatefulWidget {

  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final double screenWidth = MediaQuery.of(context).size.width;
  late final double cardWidth = (screenWidth - 20) / 2;
  late final serviceProvider = context.watch<ServiceProvider>();

  @override
  Widget build(BuildContext context) {
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
                colors: [
                  AppStyles.primaryColor,
                  AppStyles.secondaryColor,
                ],
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
                SizedBox(height: 40,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hello, welcome
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello ${serviceProvider.fullName}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seva Share | Navi Mumbai',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    // Notifications
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        // color: Colors.white.withOpacity(0.2),
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

          // 📌 My Services Section
          // 📌 My Services Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor, // Ensure AppStyles is imported
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

// Dynamic List Rendering
          serviceProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : serviceProvider.myServicesList.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "You haven't added any services yet.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                // Map through the Firestore data to generate cards dynamically
                children: serviceProvider.myServicesList.map((service) {

                  // Extract data with safe fallbacks
                  final String name = service['full_name'] ?? 'No Name';
                  final String profession = service['profession'] ?? 'Professional';
                  final double hourlyRate = (service['hourly_rate'] ?? 0.0).toDouble();
                  final String imageUrl = service['profile_image_url'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0), // Replaces the SizedBox spacer
                    child: _buildProviderCard(
                      width: MediaQuery.of(context).size.width * 0.6,
                      name: name,
                      profession: profession,
                      price: 'Rs.$hourlyRate/hr',

                      // Handle missing images safely with a fallback placeholder
                      imageUrl: imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://images.unsplash.com/photo-1598257006458-087169a1f08d',

                      // Hardcoded for now unless you save these to Firestore later
                      rating: '4.9',
                      reviewCount: '0',
                      distance: 'N/A',
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 📌 Services Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {},
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

          // Services Grid
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildServiceItem(
                  icon: Icons.plumbing,
                  label: 'Plumbing',
                  color: Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.electrical_services,
                  label: 'Electrical',
                  color: Colors.orange,
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.cleaning_services,
                  label: 'Cleaning',
                  color: Colors.green,
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.drive_eta,
                  label: 'Moving',
                  color: Colors.purple,
                ),
                const SizedBox(width: 15),
                _buildServiceItem(
                  icon: Icons.build,
                  label: 'Repair',
                  color: Colors.red,
                ),
              ],
            ),
          ),
          // const SizedBox(height: 10),

          // 📌 Nearby Providers Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildProviderCard(
                    width: MediaQuery.of(context).size.width * 0.6,
                    name: serviceProvider.fullName,
                    profession: serviceProvider.profession,
                    rating: '4.9',
                    imageUrl:
                    serviceProvider.profileImageUrl,
                    distance: '2.4 km',
                    price: 'Rs.${serviceProvider.hourlyRate}/hr', reviewCount: '45',
                  ),
                  const SizedBox(width: 12),
                  _buildProviderCard(
                    width: MediaQuery.of(context).size.width * 0.6,
                    name: 'Maria Lee',
                    profession: 'Electrician',
                    rating: '4.7',
                    imageUrl:
                    'https://images.unsplash.com/photo-1598257006458-087169a1f08d',
                    distance: '3.1 km',
                    price: '\$35/hr', reviewCount: '8',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Provider Card - spare
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppStyles.secondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'AJ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.secondaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Provider Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex Johnson',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plumber',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.9 (127 reviews)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppStyles.secondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2.3 km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.attach_money,
                            color: AppStyles.secondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$45/hr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Book Button
                Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppStyles.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Book',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),


        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
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
    );
  }

  // ================= PROVIDER CARD =================
  Widget _buildProviderCard({
    required double width,
    required String name,
    required String profession,
    required String rating,
    required String reviewCount, // Added review count parameter
    required String imageUrl,
    required String distance,
    required String price,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4), // Added slight vertical offset for better shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------
          // IMAGE & LIKE BUTTON
          // ----------------------------------------
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 110, // Slightly increased height for better proportions
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // 5. Like button at top right corner
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFF1E293B), // Dark slate color
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          // ----------------------------------------
          // DETAILS SECTION (3 Rows)
          // ----------------------------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ROW 1: Name and Rating with Review Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B), // Dark blue/slate color matching the image
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFF1E293B), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ROW 2: Designation / Profession
                Text(
                  profession,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 12), // Spacing before the final row

                // ROW 3: Price and Distance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Text (Formatted to match the blue text in the image)
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6), // Blue color matching image
                      ),
                    ),
                    // Distance with Location Icon
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
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
    );
  }
}


