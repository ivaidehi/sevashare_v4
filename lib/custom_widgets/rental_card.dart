import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../styles/appstyles.dart';
import '../providers/user_provider.dart';
import '../utils/calculate_distance.dart';
import '../screens/rent_now_screen.dart';

class RentalCard extends StatelessWidget {
  final double? width;
  final String itemName;
  final String ownerName;
  final String category;
  final String price;
  final String imageUrl;
  final String rating;
  final String reviewCount;
  final double? itemLat;
  final double? itemLon;
  final double? distance;
  final void Function(double distance, double? avgRating, int? totalReviews)? onTap;
  final String? ownerId;
  final String? itemId;
  final Map<String, dynamic>? fullItemData;

  const RentalCard({
    super.key,
    this.width,
    required this.itemName,
    required this.ownerName,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.itemLat,
    this.itemLon,
    this.distance,
    this.onTap,
    this.ownerId,
    this.itemId,
    this.fullItemData,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final double distanceKm = distance ?? CalculateDistance.calculateDistance(
      userProvider.latitude,
      userProvider.longitude,
      itemLat,
      itemLon,
    );

    final String displayDistance = userProvider.userType == "service_provider"
        ? "N/A"
        : CalculateDistance.formatDistance(distanceKm);

    return StreamBuilder<QuerySnapshot>(
      stream: (ownerId != null && itemId != null)
          ? FirebaseFirestore.instance
              .collection('rentals')
              .doc(ownerId)
              .collection('items')
              .doc(itemId)
              .collection('reviews')
              .snapshots()
          : null,
      builder: (context, snapshot) {
        double currentAvgRating = double.tryParse(rating) ?? 0.0;
        int currentTotalReviews = int.tryParse(reviewCount) ?? 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final reviews = snapshot.data!.docs;
          currentTotalReviews = reviews.length;
          double sumRating = 0;
          for (var doc in reviews) {
            sumRating += (doc.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0.0;
          }
          currentAvgRating = sumRating / currentTotalReviews;
        }

        return GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap!(distanceKm, currentAvgRating, currentTotalReviews);
            } else if (fullItemData != null) {
              _navigateToRentNow(context, distanceKm, currentAvgRating, currentTotalReviews);
            }
          },
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.black),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    displayDistance,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            flex: 2,
                            child: currentTotalReviews > 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        currentAvgRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          ' ($currentTotalReviews)',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildNewBadge(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToRentNow(BuildContext context, double distance, double? avgRating, int? totalReviews) {
    if (fullItemData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RentNowScreen(
            item: fullItemData!,
            distance: distance,
            averageRating: avgRating,
            totalReviewCount: totalReviews,
          ),
        ),
      );
    }
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        "New",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3B82F6),
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
                mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
