import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/screens/profile_screen.dart';
import '../providers/user_provider.dart';
import '../screens/services_screen.dart';
import '../services/backend_services.dart';
import '../styles/appstyles.dart';
import '../screens/bookings_screen.dart';
import '../screens/rentals_screen.dart';

/// 1. Custom Notification to communicate from children to the NavBar
class ChangeTabNotification extends Notification {
  final int index;
  ChangeTabNotification(this.index);
}

class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootPage;

  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.rootPage,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
        );
      },
    );
  }
}

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _screens = [
    const ServicesScreen(),
    const RentalsScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 2. Wrap everything in a NotificationListener to handle tab switches from children
    return NotificationListener<ChangeTabNotification>(
      onNotification: (notification) {
        setState(() {
          _selectedIndex = notification.index;
        });
        return true; // Stop notification from bubbling further
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          final currentNavigator = _navigatorKeys[_selectedIndex].currentState!;

          if (currentNavigator.canPop()) {
            currentNavigator.pop();
          } else {
            if (_selectedIndex != 0) {
              setState(() {
                _selectedIndex = 0;
              });
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              TabNavigator(navigatorKey: _navigatorKeys[0], rootPage: _screens[0]),
              TabNavigator(navigatorKey: _navigatorKeys[1], rootPage: _screens[1]),
              TabNavigator(navigatorKey: _navigatorKeys[2], rootPage: _screens[2]),
              TabNavigator(navigatorKey: _navigatorKeys[3], rootPage: _screens[3]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (_selectedIndex == index) {
                _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
              }

              // 🔽 ADDED: Mark notifications as seen when switching to Bookings tab
              if (index == 2) {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                BookingService().markAllAsSeen(
                    userProvider.uid,
                    userProvider.userType == 'service_provider'
                );
              }

              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: AppStyles.primaryColor,
            unselectedItemColor: Colors.grey[600],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              _buildNavItem(Icons.home_repair_service, 'Services', 0),
              _buildNavItem(Icons.widgets_rounded, 'Rentals', 1),
              _buildNavItem(Icons.calendar_today_rounded, 'Bookings', 2),
              _buildNavItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? AppStyles.secondaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: _selectedIndex == index ? 26 : 24,
        ),
      ),
      label: label,
    );
  }
}
