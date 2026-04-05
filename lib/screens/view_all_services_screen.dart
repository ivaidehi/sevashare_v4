import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/screens/select_city_screen.dart';

import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/service_provider_cardlist.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../styles/appstyles.dart';
import '../utils/calculate_distance.dart';

class ViewAllCardsScreen extends StatefulWidget {
  final String? category;
  const ViewAllCardsScreen({super.key, this.category});

  @override
  State<ViewAllCardsScreen> createState() => _ViewAllCardsScreenState();
}

class _ViewAllCardsScreenState extends State<ViewAllCardsScreen> {
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
    final serviceProvider = context.watch<ServiceProvider>();
    final userProvider = context.watch<UserProvider>();

    // 1. Filter providers based on the selected city and optionally by category
    List<Map<String, dynamic>> filteredProviders = serviceProvider.allServicesList
        .where((service) {
      final address = service['address'] as Map<String, dynamic>?;
      final city = address?['city']?.toString() ?? '';
      bool cityMatch = city.toLowerCase() == _selectedCity.toLowerCase();
      
      if (widget.category != null) {
        final category = service['service_category']?.toString() ?? '';
        return cityMatch && category.toLowerCase() == widget.category!.toLowerCase();
      }
      
      return cityMatch;
    })
        .map((p) => Map<String, dynamic>.from(p))
        .toList();

    // 2. Calculate distances and sort
    for (var provider in filteredProviders) {
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

    // Sort by distance (ascending)
    filteredProviders.sort((a, b) {
      double distA = a['_distance'] ?? -1.0;
      double distB = b['_distance'] ?? -1.0;

      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category ?? "All Services",
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
            // Use Flexible with constraints to prevent overflow
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (serviceProvider.isAllProvidersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (filteredProviders.isEmpty) {
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
                            "No providers found${widget.category != null ? " for ${widget.category}" : ""} in $_selectedCity",
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

                  // Use SingleChildScrollView with GridView inside for proper scrolling
                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: ServiceProviderCardGrid(
                      providers: filteredProviders,
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