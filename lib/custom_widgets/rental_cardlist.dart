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
    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RentalCardShimmer(width: screenWidth * 0.5),
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

    // 1. Create a sortable list and calculate distances for each item
    List<Map<String, dynamic>> sortedItems = items.map((i) => Map<String, dynamic>.from(i)).toList();
    
    for (var item in sortedItems) {
      final address = item['address'] as Map<String, dynamic>?;
      final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
      final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;
      
      item['_distance'] = CalculateDistance.calculateDistance(
        userProvider.latitude,
        userProvider.longitude,
        lat,
        lon,
      );
    }

    // 2. Sort by distance (ascending)
    sortedItems.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;
      
      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    // 3. Limit to top 10 closest items (consistent with ServiceProviderCardList flow)
    final displayList = sortedItems.take(10).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayList.map((item) {
          final List<dynamic> images = item['item_images'] ?? [];
          final String imageUrl = images.isNotEmpty ? images[0] : '';
          
          final address = item['address'] as Map<String, dynamic>?;
          final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
          final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;

          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RentalCard(
              width: screenWidth * 0.5,
              itemName: item['item_name'] ?? 'Unknown Item',
              ownerName: item['owner_name'] ?? 'Unknown Owner',
              category: item['category'] ?? 'General',
              price: 'Rs.${item['rent_per_day'] ?? 0}/day',
              imageUrl: imageUrl,
              itemLat: lat,
              itemLon: lon,
              distance: item['_distance'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RentNowScreen(item: item),
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
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => const RentalCardShimmer(),
      );
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No items found in this city",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);

    // 1. Create a sortable list and calculate distances for each item
    List<Map<String, dynamic>> sortedItems = items.map((i) => Map<String, dynamic>.from(i)).toList();
    
    for (var item in sortedItems) {
      final address = item['address'] as Map<String, dynamic>?;
      final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
      final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;
      
      item['_distance'] = CalculateDistance.calculateDistance(
        userProvider.latitude,
        userProvider.longitude,
        lat,
        lon,
      );
    }

    // 2. Sort by distance (ascending)
    sortedItems.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;
      
      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        final List<dynamic> images = item['item_images'] ?? [];
        final String imageUrl = images.isNotEmpty ? images[0] : '';
        
        final address = item['address'] as Map<String, dynamic>?;
        final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
        final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;

        return RentalCard(
          width: double.infinity,
          itemName: item['item_name'] ?? 'Unknown Item',
          ownerName: item['owner_name'] ?? 'Unknown Owner',
          category: item['category'] ?? 'General',
          price: 'Rs.${item['rent_per_day'] ?? 0}/day',
          imageUrl: imageUrl,
          itemLat: lat,
          itemLon: lon,
          distance: item['_distance'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RentNowScreen(item: item),
              ),
            );
          },
        );
      },
    );
  }
}
