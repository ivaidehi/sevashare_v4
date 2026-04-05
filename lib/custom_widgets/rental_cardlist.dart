import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/rent_now_screen.dart';
import '../utils/calculate_distance.dart';
import 'rental_card.dart';

class RentalCardList extends StatelessWidget {
  final List<dynamic> items;
  final double screenWidth;
  final bool isLoading;

  const RentalCardList({
    super.key,
    required this.items,
    required this.screenWidth,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine responsive card width for horizontal scrolling
    double cardWidth = screenWidth * 0.5;
    if (screenWidth > 600) cardWidth = screenWidth * 0.35; // Tablet
    if (screenWidth > 1200) cardWidth = screenWidth * 0.25; // Desktop

    // Dynamic padding and spacing
    double horizontalPadding = screenWidth * 0.05;
    double itemSpacing = screenWidth * 0.04;
    if (itemSpacing > 16.0) itemSpacing = 16.0;

    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        child: Row(
          children: List.generate(3, (index) => Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child: RentalCardShimmer(width: cardWidth),
          )),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No items found", style: TextStyle(color: Colors.grey))),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    List<Map<String, dynamic>> sortedItems = items.map((i) => Map<String, dynamic>.from(i)).toList();
    
    for (var item in sortedItems) {
      final address = item['address'] as Map<String, dynamic>?;
      item['_distance'] = CalculateDistance.calculateDistance(
        userProvider.latitude,
        userProvider.longitude,
        (address?['latitude'] as num?)?.toDouble(),
        (address?['longitude'] as num?)?.toDouble(),
      );
    }

    sortedItems.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;
      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    final displayList = sortedItems.take(10).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayList.map((item) {
          final List<dynamic> images = item['item_images'] ?? [];
          final String imageUrl = images.isNotEmpty ? images[0] : '';
          
          return Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child: RentalCard(
              width: cardWidth,
              itemName: item['item_name'] ?? 'Unknown Item',
              ownerName: item['owner_name'] ?? 'Unknown Owner',
              category: item['category'] ?? 'General',
              price: 'Rs.${item['rent_per_day'] ?? 0}/day',
              imageUrl: imageUrl,
              rating: (item['rating'] ?? '0.0').toString(),
              reviewCount: (item['reviews_count'] ?? 0).toString(),
              itemLat: (item['address']?['latitude'] as num?)?.toDouble(),
              itemLon: (item['address']?['longitude'] as num?)?.toDouble(),
              distance: item['_distance'],
              ownerId: item['owner_id'],
              itemId: item['item_id'],
              onTap: (dist, rating, reviews) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RentNowScreen(
                      item: item,
                      distance: dist,
                      averageRating: rating,
                      totalReviewCount: reviews,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RentalCardGrid extends StatelessWidget {
  final List<dynamic> items;
  final bool isLoading;

  const RentalCardGrid({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final size = MediaQuery.of(context).size;
        
        // Determine column count based on available width
        int crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);
        double spacing = width * 0.04;
        if (spacing > 16.0) spacing = 16.0;
        
        double itemWidth = (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        if (isLoading) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(4, (index) => SizedBox(
              width: itemWidth,
              child: const RentalCardShimmer(),
            )),
          );
        }

        if (items.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: size.height * 0.1),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: size.width * 0.15, color: Colors.grey),
                  SizedBox(height: size.height * 0.02),
                  const Text("No items found in this city", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final userProvider = Provider.of<UserProvider>(context);
        List<Map<String, dynamic>> sortedItems = items.map((i) => Map<String, dynamic>.from(i)).toList();
        
        for (var item in sortedItems) {
          final address = item['address'] as Map<String, dynamic>?;
          item['_distance'] = CalculateDistance.calculateDistance(
            userProvider.latitude,
            userProvider.longitude,
            (address?['latitude'] as num?)?.toDouble(),
            (address?['longitude'] as num?)?.toDouble(),
          );
        }

        sortedItems.sort((a, b) {
          double distA = a['_distance'] ?? -1.0;
          double distB = b['_distance'] ?? -1.0;
          if (distA < 0) return 1;
          if (distB < 0) return -1;
          return distA.compareTo(distB);
        });

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: sortedItems.map((item) {
            final List<dynamic> images = item['item_images'] ?? [];
            final String imageUrl = images.isNotEmpty ? images[0] : '';
            
            return SizedBox(
              width: itemWidth,
              child: RentalCard(
                width: double.infinity,
                itemName: item['item_name'] ?? 'Unknown Item',
                ownerName: item['owner_name'] ?? 'Unknown Owner',
                category: item['category'] ?? 'General',
                price: 'Rs.${item['rent_per_day'] ?? 0}/day',
                imageUrl: imageUrl,
                rating: (item['rating'] ?? '0.0').toString(),
                reviewCount: (item['reviews_count'] ?? 0).toString(),
                itemLat: (item['address']?['latitude'] as num?)?.toDouble(),
                itemLon: (item['address']?['longitude'] as num?)?.toDouble(),
                distance: item['_distance'],
                ownerId: item['owner_id'],
                itemId: item['item_id'],
                onTap: (dist, rating, reviews) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RentNowScreen(
                        item: item,
                        distance: dist,
                        averageRating: rating,
                        totalReviewCount: reviews,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
