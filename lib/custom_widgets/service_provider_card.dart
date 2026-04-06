import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../styles/appstyles.dart';
import '../providers/user_provider.dart';
import '../utils/calculate_distance.dart';
import '../screens/book_now_screen.dart';

class ServiceProviderCard extends StatelessWidget {
  final double? width;
  final String name;
  final String profession;
  final String rating;
  final String reviewCount;
  final String imageUrl;
  final String price;
  final double? providerLat;
  final double? providerLon;
  final double? distance;
  final void Function(double distance, double? avgRating, int? totalReviews)? onBookPressed;
  final String? providerUid;
  final String? serviceId;
  final Map<String, dynamic>? fullServiceData;

  const ServiceProviderCard({
    super.key,
    this.width,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.price,
    this.providerLat,
    this.providerLon,
    this.distance,
    this.onBookPressed,
    this.providerUid,
    this.serviceId,
    this.fullServiceData,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final double distanceKm = distance ?? CalculateDistance.calculateDistance(
      userProvider.latitude,
      userProvider.longitude,
      providerLat,
      providerLon,
    );

    final String displayDistance = userProvider.userType == "service_provider"
        ? "N/A"
        : CalculateDistance.formatDistance(distanceKm);

    final String effectiveImageUrl = imageUrl.isNotEmpty
        ? imageUrl
        : 'https://images.unsplash.com/photo-1598257006458-087169a1f08d';

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // 🔽 Reduced radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: (providerUid != null && serviceId != null)
            ? FirebaseFirestore.instance
                .collection('service_providers')
                .doc(providerUid)
                .collection('services')
                .doc(serviceId)
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

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (onBookPressed != null) {
                  onBookPressed!(distanceKm, currentAvgRating, currentTotalReviews);
                } else if (fullServiceData != null) {
                  _navigateToBookNow(context, distanceKm, currentAvgRating, currentTotalReviews);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.5, // 🔽 Adjusted ratio for smaller width
                    child: CachedNetworkImage(
                      imageUrl: effectiveImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ServiceProviderCardShimmer(isImageOnly: true),
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8), // 🔽 Reduced padding
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                profession,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12, // 🔽 Reduced font size
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              flex: 2,
                              child: currentTotalReviews > 0
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 12), // 🔽 Smaller icon
                                        const SizedBox(width: 2),
                                        Text(
                                          currentAvgRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 11, // 🔽 Smaller text
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
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]), // 🔽 Smaller text
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: Colors.black),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      displayDistance,
                                      style: const TextStyle(fontSize: 10, color: Colors.black), // 🔽 Smaller text
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 12, // 🔽 Smaller text
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (onBookPressed != null) {
                                onBookPressed!(distanceKm, currentAvgRating, currentTotalReviews);
                              } else if (fullServiceData != null) {
                                 _navigateToBookNow(context, distanceKm, currentAvgRating, currentTotalReviews);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyles.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6), // 🔽 Reduced padding
                              minimumSize: const Size(0, 30), // 🔽 Reduced height
                              elevation: 0,
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // 🔽 Smaller text
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _navigateToBookNow(BuildContext context, double distance, double? avgRating, int? totalReviews) {
    if (fullServiceData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookNowScreen(
            providerData: fullServiceData!,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 🔽 Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        "New",
        style: TextStyle(
          fontSize: 9, // 🔽 Smaller text
          fontWeight: FontWeight.w700,
          color: Color(0xFF3B82F6),
        ),
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
          ? AspectRatio(
        aspectRatio: 1.5,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )
          : Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                width: double.infinity,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(height: 8, width: 60, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 8, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 28, width: double.infinity, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
