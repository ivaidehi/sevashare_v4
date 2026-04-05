import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../styles/appstyles.dart';
import '../providers/user_provider.dart';
import '../utils/calculate_distance.dart';

class RentalCard extends StatelessWidget {
  final double? width;
  final String itemName;
  final String ownerName;
  final String category;
  final String price;
  final String imageUrl;
  final double? itemLat;
  final double? itemLon;
  final double? distance;
  final VoidCallback? onTap;

  const RentalCard({
    super.key,
    this.width,
    required this.itemName,
    required this.ownerName,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.itemLat,
    this.itemLon,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Use passed distance or calculate in real-time using user and item coordinates
    final double distanceKm = distance ?? CalculateDistance.calculateDistance(
      userProvider.latitude,
      userProvider.longitude,
      itemLat,
      itemLon,
    );

    // Conditionally set display distance based on userType
    final String displayDistance = userProvider.userType == "service_provider"
        ? "N/A"
        : CalculateDistance.formatDistance(distanceKm);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              AspectRatio(
                aspectRatio: 1.6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    Text(
                      'by $ownerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.secondaryColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppStyles.secondaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFF1E293B), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              "4.9",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                            Text(
                              ' (12)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        // Distance display aligned with ServiceProviderCard style
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              displayDistance,
                              style: const TextStyle(fontSize: 12, color: Colors.black),
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
        ),
      ),
    );
  }
}

class RentalCardShimmer extends StatelessWidget {
  final double? width;
  final bool isImageOnly;

  const RentalCardShimmer({super.key, this.width, this.isImageOnly = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: isImageOnly
          ? AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          width: double.infinity,
          color: Colors.white,
        ),
      )
          : Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.6,
              child: Container(
                width: double.infinity,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(height: 12, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
