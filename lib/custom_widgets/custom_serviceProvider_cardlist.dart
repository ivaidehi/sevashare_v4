import 'package:flutter/material.dart';

import 'custom_serviceProvider_card.dart';

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      clipBehavior: Clip.none, // CRITICAL FOR SHADOWS
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: providers.map((service) {
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
              distance: 'N/A',
            ),
          );
        }).toList(),
      ),
    );
  }
}