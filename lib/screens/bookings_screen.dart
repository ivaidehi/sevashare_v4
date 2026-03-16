import 'package:flutter/material.dart';
import 'package:sevashare_v4/screens/services_screen.dart';
import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/custom_navbar.dart';
import '../styles/appstyles.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Completed, 2: Cancelled

  // TODO: Replace with Firebase data - Updated with service provider data
  final List<Map<String, dynamic>> _bookings = [
    {
      'id': '1',
      'title': 'Fix leaking pipe under kitchen sink',
      'status': 'Confirmed',
      'providerName': 'Mike Johnson',
      'providerType': 'Plumber',
      'date': 'Dec 15, 2023',
      'time': '10:00 AM',
      'address': '2.5 km away',
      'duration': '2 hours',
      'amount': '\$75',
      'rating': 4.8,
      'reviews': 156,
      'distance': '2.5 km',
      'jobsCompleted': 342,
      'rate': '\$45/hr',
      'about': 'Expert plumber with 8+ years experience in residential and commercial plumbing. Specialized in pipe repairs, fixture installation, and emergency services.',
      'providerImage': null,
      'serviceType': 'Plumbing',
    },
  ];

  // Status color mapping
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Get icon for service type
  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'plumber':
      case 'plumbing':
        return Icons.plumbing;
      case 'carpenter':
      case 'carpentry':
        return Icons.handyman;
      case 'electrician':
        return Icons.electrical_services;
      default:
        return Icons.build;
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    switch (_selectedTab) {
      case 0: // Upcoming
        return _bookings.where((b) =>
        b['status'] == 'Confirmed' || b['status'] == 'Pending').toList();
      case 1: // Completed
        return _bookings.where((b) => b['status'] == 'Completed').toList();
      case 2: // Cancelled
        return _bookings.where((b) => b['status'] == 'Cancelled').toList();
      default:
        return _bookings;
    }
  }

  int _getTabCount(int tabIndex) {
    switch (tabIndex) {
      case 0: return _bookings.where((b) =>
      b['status'] == 'Confirmed' || b['status'] == 'Pending').length;
      case 1: return _bookings.where((b) => b['status'] == 'Completed').length;
      case 2: return _bookings.where((b) => b['status'] == 'Cancelled').length;
      default: return 0;
    }
  }

  void _showProviderProfile(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildProviderProfile(booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "My Bookings",
        onBackPressed: () {
          // This sends a signal up the tree to CustomNavBar to switch to index 0 (Services)
          ChangeTabNotification(0).dispatch(context);
        },
      ),
      body: Column(
        children: [
          // const SizedBox(height: 20),
          _buildTabs(),
          Expanded(
            child: _filteredBookings.isEmpty
                ? _buildEmptyState()
                : _buildBookingsList(),
          ),
        ],
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Container(
  //     padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text('My Bookings', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
  //         const SizedBox(height: 8),
  //         Text('View and manage your bookings', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildTabButton(0, 'Upcoming', _getTabCount(0)),
          const SizedBox(width: 12),
          _buildTabButton(1, 'Completed', _getTabCount(1)),
          const SizedBox(width: 12),
          _buildTabButton(2, 'Cancelled', _getTabCount(2)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, int count) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppStyles.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppStyles.primaryColor : Colors.grey.shade300, width: 1),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(count.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: isSelected ? AppStyles.primaryColor : Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredBookings.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _showProviderProfile(_filteredBookings[index]),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildBookingCard(_filteredBookings[index]),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final statusColor = _getStatusColor(booking['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Profile Picture + Status Chip
            Column(
              children: [
                // Status Chip moved here
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 10, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        booking['status'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // profile image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      booking['providerName'][0],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),


              ],
            ),

            const SizedBox(width: 16),

            // Right Column: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Ratings Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking['providerName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Star Rating and Count
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            "4.8", // Replace with booking['rating'] if available
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "(34)", // Replace with booking['reviews'] if available
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Service Type
                  Row(
                    children: [
                      Icon(
                        _getServiceIcon(booking['serviceType']),
                        size: 14,
                        color: AppStyles.secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking['providerType'],
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date and Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppStyles.secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${booking['date']}  ${booking['time']}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Distance and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: AppStyles.secondaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking['address'],
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        booking['amount'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final config = [
      {'icon': Icons.calendar_today_outlined, 'msg': 'No Upcoming Bookings', 'sub': 'You have no confirmed or pending bookings at the moment.'},
      {'icon': Icons.check_circle_outline, 'msg': 'No Completed Bookings', 'sub': 'You haven\'t completed any bookings yet.'},
      {'icon': Icons.cancel_outlined, 'msg': 'No Cancelled Bookings', 'sub': 'You haven\'t cancelled any bookings.'},
    ][_selectedTab];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(config['icon'] as IconData, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(config['msg'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(config['sub'] as String, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderProfile(Map<String, dynamic> booking) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Provider Header with service icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor_light,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                _getServiceIcon(booking['serviceType']),
                                size: 24,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['providerName'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking['providerType'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${booking['rating']} (${booking['reviews']} reviews)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats Row - Removed Response Time, added Jobs Completed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Distance', booking['distance']),
                          _buildStatColumn('Jobs Done', '${booking['jobsCompleted']}'),
                          _buildStatColumn('Rate', booking['rate']),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // About Section
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['about'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Service Details Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Service Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.build, size: 14, color: AppStyles.secondaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  booking['title'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: AppStyles.secondaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Duration: ${booking['duration']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Book Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Implement booking action
                          },
                          style: AppStyles.primaryButtonStyle,
                          child: const Text(
                            'Book Service',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}