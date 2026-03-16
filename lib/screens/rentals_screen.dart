import 'package:flutter/material.dart';
import 'package:sevashare_v4/screens/services_screen.dart';

import '../custom_widgets/custom_appbar.dart';
import '../styles/appstyles.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              // Trending Rentals Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Rentals',
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

              // Rental Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildRentalCategory(
                      title: 'Home',
                      itemCount: '12 items',
                      color: Colors.blue[50]!,
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildRentalCategory(
                      title: 'Tools',
                      itemCount: '8 items',
                      color: Colors.green[50]!,
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildRentalCategory(
                      title: 'Electronics',
                      itemCount: '15 items',
                      color: Colors.orange[50]!,
                      iconColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildRentalCategory({
  required String title,
  required String itemCount,
  required Color color,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.category,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  itemCount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[500],
        ),
      ],
    ),
  );
}