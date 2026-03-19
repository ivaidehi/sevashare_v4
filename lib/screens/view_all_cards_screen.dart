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
  const ViewAllCardsScreen({super.key});

  @override
  State<ViewAllCardsScreen> createState() => _ViewAllCardsScreenState();
}

class _ViewAllCardsScreenState extends State<ViewAllCardsScreen> {
  String _selectedCity = 'Mumbai';

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
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final userProvider = context.watch<UserProvider>();

    // 1. Filter providers based on the selected city
    List<Map<String, dynamic>> filteredProviders = serviceProvider.allServicesList
        .where((service) {
          final address = service['address'] as Map<String, dynamic>?;
          final city = address?['city']?.toString() ?? '';
          return city.toLowerCase() == _selectedCity.toLowerCase();
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
        title: "All Services",
        subtitle: _selectedCity,
        onSubtitlePressed: _openCitySelection,
        onBackPressed: () {
          Navigator.pop(context);
        },
        actionIcon: Icons.filter_list_rounded,
      ),
      backgroundColor: AppStyles.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ServiceProviderCardGrid(
                providers: filteredProviders,
                isLoading: serviceProvider.isAllProvidersLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
