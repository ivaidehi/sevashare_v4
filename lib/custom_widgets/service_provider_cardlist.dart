import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/calculate_distance.dart';
import 'service_provider_card.dart';

class ServiceProviderCardList extends StatelessWidget {
  final List<dynamic> providers;
  final double screenWidth;
  final bool isLoading;

  const ServiceProviderCardList({
    super.key,
    required this.providers,
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
            child: ServiceProviderCardShimmer(width: screenWidth * 0.6),
          )),
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    
    // 1. Create a sortable list and calculate distances for each provider
    List<Map<String, dynamic>> sortedProviders = providers.map((p) => Map<String, dynamic>.from(p)).toList();

    for (var provider in sortedProviders) {
      final address = provider['address'] as Map<String, dynamic>?;
      final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
      final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;
      
      provider['_distance'] = CalculateDistance.calculateDistance(
        userProvider.latitude,
        userProvider.longitude,
        lat,
        lon,
      );
    }

    // 2. Sort by distance (ascending)
    // Providers with invalid distance (-1.0) are moved to the end
    sortedProviders.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;
      
      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    // 3. Limit to top 10 closest providers
    final displayList = sortedProviders.take(10).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      clipBehavior: Clip.none, // CRITICAL FOR SHADOWS
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayList.map((service) {
          final address = service['address'] as Map<String, dynamic>?;
          final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
          final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;

          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ServiceProviderCard(
              width: screenWidth * 0.6,
              name: service['full_name'] ?? 'No Name',
              profession: service['profession'] ?? 'Professional',
              price: 'Rs.${service['hourly_rate'] ?? 0.0}/hr',
              imageUrl: service['profile_image_url'] ?? '',
              rating: '4.9',
              reviewCount: '0',
              providerLat: lat,
              providerLon: lon,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ServiceProviderCardGrid extends StatelessWidget {
  final List<dynamic> providers;
  final bool isLoading;

  const ServiceProviderCardGrid({
    super.key,
    required this.providers,
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
          childAspectRatio: 0.75,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ServiceProviderCardShimmer(),
      );
    }

    if (providers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No providers found in this city",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final service = providers[index];
        final address = service['address'] as Map<String, dynamic>?;
        final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
        final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;

        return ServiceProviderCard(
          width: double.infinity,
          name: service['full_name'] ?? 'No Name',
          profession: service['profession'] ?? 'Professional',
          price: 'Rs.${service['hourly_rate'] ?? 0.0}/hr',
          imageUrl: service['profile_image_url'] ?? '',
          rating: '4.9',
          reviewCount: '0',
          providerLat: lat,
          providerLon: lon,
        );
      },
    );
  }
}
