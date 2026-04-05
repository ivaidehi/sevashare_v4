import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/screens/select_city_screen.dart';

import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/rental_cardlist.dart';
import '../providers/rentals_provider.dart';
import '../providers/user_provider.dart';
import '../styles/appstyles.dart';
import '../utils/calculate_distance.dart';

class ViewAllRentalsScreen extends StatefulWidget {
  final String? category;
  const ViewAllRentalsScreen({super.key, this.category});

  @override
  State<ViewAllRentalsScreen> createState() => _ViewAllRentalsScreenState();
}

class _ViewAllRentalsScreenState extends State<ViewAllRentalsScreen> {
  String _selectedCity = 'Mumbai';
  final ScrollController _scrollController = ScrollController();

  void _openCitySelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCityScreen(currentCity: _selectedCity),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedCity = result;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rentalsProvider = context.watch<RentalsProvider>();
    final userProvider = context.watch<UserProvider>();

    // 1. Filter rentals based on the selected city and optionally by category
    List<Map<String, dynamic>> filteredRentals = rentalsProvider.allRentalsList
        .where((item) {
      final address = item['address'] as Map<String, dynamic>?;
      final city = address?['city']?.toString() ?? '';
      bool cityMatch = city.toLowerCase() == _selectedCity.toLowerCase();
      
      if (widget.category != null) {
        final category = item['category']?.toString() ?? '';
        return cityMatch && category.toLowerCase() == widget.category!.toLowerCase();
      }
      
      return cityMatch;
    })
        .map((i) => Map<String, dynamic>.from(i))
        .toList();

    // 2. Calculate distances and sort
    for (var item in filteredRentals) {
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

    // Sort by distance (ascending)
    filteredRentals.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;

      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category ?? "All Rentals",
        subtitle: _selectedCity,
        onSubtitlePressed: _openCitySelection,
        onBackPressed: () {
          Navigator.pop(context);
        },
        actionIcon: Icons.filter_list_rounded,
      ),
      backgroundColor: AppStyles.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (rentalsProvider.isAllRentalsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (filteredRentals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No rentals found${widget.category != null ? " in ${widget.category}" : ""} in $_selectedCity",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _openCitySelection,
                            child: const Text("Change City"),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: RentalCardGrid(
                      items: filteredRentals,
                      isLoading: false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}