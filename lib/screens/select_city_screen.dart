import 'package:flutter/material.dart';
import 'package:sevashare_v4/styles/appstyles.dart';

class SelectCityScreen extends StatefulWidget {
  final String? currentCity;

  const SelectCityScreen({super.key, this.currentCity});

  @override
  State<SelectCityScreen> createState() => _SelectCityScreenState();
}

class _SelectCityScreenState extends State<SelectCityScreen> {
  String? _selectedCity;

  // City list with placeholder icons representing landmarks
  final List<Map<String, dynamic>> _cities = [
    {'name': 'Mumbai', 'icon': Icons.location_city},
    {'name': 'Delhi-NCR', 'icon': Icons.account_balance},
    {'name': 'Bengaluru', 'icon': Icons.business},
    {'name': 'Hyderabad', 'icon': Icons.fort},
    {'name': 'Chandigarh', 'icon': Icons.architecture},
    {'name': 'Ahmedabad', 'icon': Icons.mosque},
    {'name': 'Pune', 'icon': Icons.castle},
    {'name': 'Chennai', 'icon': Icons.train},
    {'name': 'Kolkata', 'icon': Icons.museum},
    {'name': 'Kochi', 'icon': Icons.sailing},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.currentCity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select City',
          style: TextStyle(
            color: AppStyles.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppStyles.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF5F7F9), // Light grayish background for section header
            child: Text(
              'POPULAR CITIES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Cities Grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
              ),
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = _selectedCity == city['name'];
                
                return CityGridItem(
                  name: city['name'],
                  icon: city['icon'],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCity = city['name'];
                    });
                    // Return the selected city to the previous screen
                    Navigator.pop(context, city['name']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CityGridItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CityGridItem({
    super.key,
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with selection dot
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: isSelected ? AppStyles.primaryColor : AppStyles.secondaryColor,
                ),
                // Only show dot if we want it strictly like the image
                // (The image shows the dot next to the text usually, but the icon can also be tinted)
              ],
            ),
            const SizedBox(height: 10),
            
            // City Name with Selection Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppStyles.secondaryColor,
                    ),
                  ),
                Flexible(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
