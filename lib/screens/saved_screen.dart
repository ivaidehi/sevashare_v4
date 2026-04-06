import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/service_provider_card.dart';
import '../custom_widgets/rental_card.dart';
import '../providers/user_provider.dart';
import '../services/backend_services.dart';
import '../styles/appstyles.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final BookingService bookingService = BookingService();

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: "Saved Items",
        onBackPressed: () => Navigator.pop(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingService.getSavedItems(userProvider.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No saved items yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final savedItems = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: savedItems.length,
            itemBuilder: (context, index) {
              final data = savedItems[index].data() as Map<String, dynamic>;
              final String type = data['type'] ?? '';
              final itemData = data['itemData'] as Map<String, dynamic>;

              if (type == 'service') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: ServiceProviderCard(
                    name: itemData['full_name'] ?? 'No Name',
                    profession: itemData['profession'] ?? 'Service',
                    rating: (itemData['rating'] ?? 0.0).toString(),
                    reviewCount: (itemData['reviews_count'] ?? 0).toString(),
                    imageUrl: itemData['profile_image_url'] ?? '',
                    price: "Rs.${itemData['hourly_rate']}/hr",
                    providerLat: itemData['latitude'],
                    providerLon: itemData['longitude'],
                    fullServiceData: itemData,
                  ),
                );
              } else if (type == 'rental') {
                final List<dynamic> images = itemData['item_images'] ?? [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: RentalCard(
                    itemName: itemData['item_name'] ?? 'No Name',
                    ownerName: itemData['owner_name'] ?? 'Unknown',
                    category: itemData['category'] ?? 'General',
                    price: "Rs.${itemData['rent_per_day']}/day",
                    imageUrl: images.isNotEmpty ? images[0] : '',
                    rating: (itemData['rating'] ?? 0.0).toString(),
                    reviewCount: (itemData['reviews_count'] ?? 0).toString(),
                    itemLat: itemData['latitude'],
                    itemLon: itemData['longitude'],
                    fullItemData: itemData,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
