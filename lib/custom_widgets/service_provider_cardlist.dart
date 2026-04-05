import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/book_now_screen.dart';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: screenWidth * 0.6,
              child: const ServiceProviderCardShimmer(),
            ),
          )),
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);

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

    sortedProviders.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;

      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    final displayList = sortedProviders.take(10).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: displayList.map((service) {
          final address = service['address'] as Map<String, dynamic>?;
          final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
          final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;

          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: screenWidth * 0.6,
              child: ServiceProviderCard(
                width: double.infinity,
                name: service['full_name'] ?? 'No Name',
                profession: service['profession'] ?? 'Professional',
                price: 'Rs.${service['hourly_rate'] ?? 0.0}/hr',
                imageUrl: service['profile_image_url'] ?? '',
                rating: '4.9',
                reviewCount: '0',
                providerLat: lat,
                providerLon: lon,
                distance: service['_distance'],
                onBookPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookNowScreen(providerData: service),
                    ),
                  );
                },
              ),
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68, // Reduced to give more vertical space
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ServiceProviderCardShimmer(),
      );
    }

    if (providers.isEmpty) {
      return const SizedBox.shrink(); // Return empty, parent handles empty state
    }

    final userProvider = Provider.of<UserProvider>(context);

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

    sortedProviders.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;

      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    // Use Wrap instead of GridView for better flexibility
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: sortedProviders.map((service) {
        final address = service['address'] as Map<String, dynamic>?;
        final double? lat = address?['latitude'] != null ? (address!['latitude'] as num).toDouble() : null;
        final double? lon = address?['longitude'] != null ? (address!['longitude'] as num).toDouble() : null;

        // Calculate width based on screen size
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = (screenWidth - 48) / 2; // 20 padding on each side + 16 spacing = 48

        return SizedBox(
          width: cardWidth,
          child: ServiceProviderCard(
            width: double.infinity,
            name: service['full_name'] ?? 'No Name',
            profession: service['profession'] ?? 'Professional',
            price: 'Rs.${service['hourly_rate'] ?? 0.0}/hr',
            imageUrl: service['profile_image_url'] ?? '',
            rating: '4.9',
            reviewCount: '0',
            providerLat: lat,
            providerLon: lon,
            distance: service['_distance'],
            onBookPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookNowScreen(providerData: service),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}