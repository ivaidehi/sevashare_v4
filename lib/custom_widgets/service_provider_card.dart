import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../styles/appstyles.dart';
import '../providers/user_provider.dart';
import '../utils/calculate_distance.dart';

class ServiceProviderCard extends StatelessWidget {
  final double width;
  final String name;
  final String profession;
  final String rating;
  final String reviewCount;
  final String imageUrl;
  final String price;
  final double? providerLat;
  final double? providerLon;
  final double? distance; // Optional pre-calculated distance

  const ServiceProviderCard({
    super.key,
    required this.width,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.price,
    this.providerLat,
    this.providerLon,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Use passed distance or calculate in real-time using provider coordinates
    final double distanceKm = distance ?? CalculateDistance.calculateDistance(
      userProvider.latitude,
      userProvider.longitude,
      providerLat,
      providerLon,
    );

    final String displayDistance = CalculateDistance.formatDistance(distanceKm);

    final String effectiveImageUrl = imageUrl.isNotEmpty
        ? imageUrl
        : 'https://images.unsplash.com/photo-1598257006458-087169a1f08d';

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: effectiveImageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ServiceProviderCardShimmer(isImageOnly: true),
                  errorWidget: (context, url, error) => Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, color: Color(0xFF1E293B), size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        profession,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ),
                    // Rating & Comments count
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFF1E293B), size: 14),
                        // const SizedBox(width: 4),
                        Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        Text(' ($reviewCount)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
                // const SizedBox(height: 4),

                // Profession
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 5),

                // location & price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(displayDistance, style: TextStyle(fontSize: 12, color: Colors.black)),
                      ],
                    ),
                    Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
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

class ServiceProviderCardShimmer extends StatelessWidget {
  final double? width;
  final bool isImageOnly;

  const ServiceProviderCardShimmer({super.key, this.width, this.isImageOnly = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: isImageOnly
          ? Container(height: 110, width: double.infinity, color: Colors.white)
          : Container(
        width: width,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(height: 110, width: double.infinity, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(width: 100, height: 14, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
