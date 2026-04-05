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
  final bool enableDistanceSorting;

  const ServiceProviderCardList({
    super.key,
    required this.providers,
    required this.screenWidth,
    this.isLoading = false,
    this.enableDistanceSorting = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine responsive card width for horizontal scrolling
    double cardWidth = screenWidth * 0.65;
    if (screenWidth > 600) cardWidth = screenWidth * 0.45; // Tablet
    if (screenWidth > 1200) cardWidth = screenWidth * 0.3; // Desktop

    double horizontalPadding = screenWidth * 0.05;
    double itemSpacing = screenWidth * 0.04;
    if (itemSpacing > 16.0) itemSpacing = 16.0;

    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child: SizedBox(
              width: cardWidth,
              child: const ServiceProviderCardShimmer(),
            ),
          )),
        ),
      );
    }

    if (providers.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No services found", style: TextStyle(color: Colors.grey))),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    List<Map<String, dynamic>> sortedProviders = providers.map((p) => Map<String, dynamic>.from(p)).toList();

    if (enableDistanceSorting) {
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
    }

    final displayList = sortedProviders.take(10).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: displayList.map((service) {
          return Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child: SizedBox(
              width: cardWidth,
              child: ServiceProviderCard(
                width: double.infinity,
                name: service['full_name'] ?? 'No Name',
                profession: service['profession'] ?? 'Professional',
                price: 'Rs.${service['hourly_rate'] ?? 0.0}/hr',
                imageUrl: service['profile_image_url'] ?? '',
                rating: (service['rating'] ?? '0.0').toString(),
                reviewCount: (service['reviews_count'] ?? 0).toString(),
                providerLat: (service['address']?['latitude'] as num?)?.toDouble(),
                providerLon: (service['address']?['longitude'] as num?)?.toDouble(),
                distance: service['_distance'],
                providerUid: service['provider_uid'],
                serviceId: service['service_id'],
                onBookPressed: (distance, avgRating, totalReviews) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookNowScreen(
                        providerData: service,
                        distance: distance,
                        averageRating: avgRating,
                        totalReviewCount: totalReviews,
                      ),
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
  // Flag to prevent internal sorting from overriding external sorting (e.g. Price filter)
  final bool enableDistanceSorting;

  const ServiceProviderCardGrid({
    super.key,
    required this.providers,
    this.isLoading = false,
    this.enableDistanceSorting = true, // Default: true to maintain existing behavior
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
            children: List.generate(6, (index) => SizedBox(
              width: itemWidth,
              child: const ServiceProviderCardShimmer(),
            )),
          );
        }

        if (providers.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: size.height * 0.1),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No services found in this city", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final userProvider = Provider.of<UserProvider>(context);

        // Creating a mutable copy to avoid immutable list issues
        List<Map<String, dynamic>> sortedProviders = providers.map((p) => Map<String, dynamic>.from(p)).toList();

        // Only perform internal distance calculation and sorting if enabled
        if (enableDistanceSorting) {
          for (var provider in sortedProviders) {
            final address = provider['address'] as Map<String, dynamic>?;
            provider['_distance'] = CalculateDistance.calculateDistance(
              userProvider.latitude,
              userProvider.longitude,
              (address?['latitude'] as num?)?.toDouble(),
              (address?['longitude'] as num?)?.toDouble(),
            );
          }

          sortedProviders.sort((a, b) {
            double distA = a['_distance'] ?? -1.0;
            double distB = b['_distance'] ?? -1.0;
            if (distA < 0) return 1;
            if (distB < 0) return -1;
            return distA.compareTo(distB);
          });
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: sortedProviders.map((service) {
            return SizedBox(
              width: itemWidth,
              child: ServiceProviderCard(
                width: double.infinity,
                name: service['full_name'] ?? 'No Name',
                profession: service['profession'] ?? 'Professional',
                price: 'Rs.${service['hourly_rate'] ?? 0.0}/hr',
                imageUrl: service['profile_image_url'] ?? '',
                rating: (service['rating'] ?? '0.0').toString(),
                reviewCount: (service['reviews_count'] ?? 0).toString(),
                providerLat: (service['address']?['latitude'] as num?)?.toDouble(),
                providerLon: (service['address']?['longitude'] as num?)?.toDouble(),
                distance: service['_distance'],
                providerUid: service['provider_uid'],
                serviceId: service['service_id'],
                onBookPressed: (distance, avgRating, totalReviews) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookNowScreen(
                        providerData: service,
                        distance: distance,
                        averageRating: avgRating,
                        totalReviewCount: totalReviews,
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
