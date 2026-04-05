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
  String _selectedPriceFilter = 'None';
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sort by Price",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ListTile(
                      leading: Icon(Icons.sort, color: AppStyles.secondaryColor),
                      title: const Text("Low to High"),
                      trailing: _selectedPriceFilter == 'Low to High'
                          ? Icon(Icons.check_circle, color: AppStyles.secondaryColor)
                          : null,
                      onTap: () {
                        setModalState(() => _selectedPriceFilter = 'Low to High');
                        setState(() => _selectedPriceFilter = 'Low to High');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.sort, color: AppStyles.secondaryColor),
                      title: const Text("High to Low"),
                      trailing: _selectedPriceFilter == 'High to Low'
                          ? Icon(Icons.check_circle, color: AppStyles.secondaryColor)
                          : null,
                      onTap: () {
                        setModalState(() => _selectedPriceFilter = 'High to Low');
                        setState(() => _selectedPriceFilter = 'High to Low');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.grey),
                      title: const Text("Reset Filter"),
                      onTap: () {
                        setModalState(() => _selectedPriceFilter = 'None');
                        setState(() => _selectedPriceFilter = 'None');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
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
    final size = MediaQuery.of(context).size;
    final double paddingHorizontal = size.width * 0.05;

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

    // 2. Calculate distances for everyone first
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

    // 3. Apply sorting (Price or Distance)
    if (_selectedPriceFilter == 'Low to High') {
      filteredProviders.sort((a, b) {
        double priceA = double.tryParse(a['hourly_rate']?.toString() ?? '0') ?? 0.0;
        double priceB = double.tryParse(b['hourly_rate']?.toString() ?? '0') ?? 0.0;
        return priceA.compareTo(priceB);
      });
    } else if (_selectedPriceFilter == 'High to Low') {
      filteredProviders.sort((a, b) {
        double priceA = double.tryParse(a['hourly_rate']?.toString() ?? '0') ?? 0.0;
        double priceB = double.tryParse(b['hourly_rate']?.toString() ?? '0') ?? 0.0;
        return priceB.compareTo(priceA);
      });
    } else {
      // Default: Sort by distance (ascending)
      filteredProviders.sort((a, b) {
        double distA = a['_distance'] ?? -1.0;
        double distB = b['_distance'] ?? -1.0;

        if (distA < 0) return 1;
        if (distB < 0) return -1;
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category ?? "All Services",
        subtitle: _selectedCity,
        onSubtitlePressed: _openCitySelection,
        onBackPressed: () {
          Navigator.pop(context);
        },
        actionIcon: Icons.filter_list_rounded,
        onMenuPressed: _showFilterBottomSheet,
      ),
      backgroundColor: AppStyles.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (serviceProvider.isAllProvidersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (filteredProviders.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: size.width * 0.15,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: size.height * 0.02),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                "No providers found${widget.category != null ? " for ${widget.category}" : ""} in $_selectedCity",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _openCitySelection,
                              child: const Text("Change City"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingHorizontal,
                        vertical: size.height * 0.02,
                      ),
                      child: ServiceProviderCardGrid(
                        providers: filteredProviders,
                        isLoading: false,
                      ),
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