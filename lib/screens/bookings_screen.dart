import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sevashare_v4/screens/profile_screen.dart';
import '../custom_widgets/custom_navbar.dart';
import '../providers/user_provider.dart';
import '../services/backend_services.dart';
import '../styles/appstyles.dart';
import '../custom_widgets/custom_appbar.dart';
import 'book_now_screen.dart'; // Navigation: Import BookNowScreen

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0;
  String _searchQuery = ''; // UI: Search query state
  final BookingService _bookingService = BookingService();

  // Optimized: Define status tabs in a single list for reusability
  final List<String> _statusTabs = [
    'Pending',
    'Accepted',
    'Rejected',
    'Rescheduled',
    'Completed',
    'Cancelled'
  ];

  // Helper method to get the ordinal suffix for a day (st, nd, rd, th)
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // Reusable date formatting logic
  String _getFormattedDate(dynamic dateValue) {
    if (dateValue == null || dateValue == '') return 'No Date';

    DateTime? dateTime;
    if (dateValue is Timestamp) {
      dateTime = dateValue.toDate();
    } else if (dateValue is String) {
      dateTime = DateTime.tryParse(dateValue);
    } else if (dateValue is DateTime) {
      dateTime = dateValue;
    }

    if (dateTime == null) return dateValue.toString();

    String day = dateTime.day.toString();
    String suffix = _getDaySuffix(dateTime.day);
    String month = DateFormat('MMM').format(dateTime);
    String year = dateTime.year.toString();
    String weekday = DateFormat('EEEE').format(dateTime);

    return "$day$suffix $month $year, $weekday";
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String uid = userProvider.uid;
    final bool isProvider = userProvider.userType == 'service_provider';

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: "Bookings",
        onBackPressed: () {
          ChangeTabNotification(0).dispatch(context);
        },
        actionWidget: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppStyles.primaryColor,
              // border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userProvider.username.isNotEmpty
                    ? userProvider.username.substring(0, 1).toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabs(), // UI : Responsive & Scrollable tabs
          const SizedBox(height: 15), // Spacing above search bar
          _buildSearchBar(),
          // Clickable full-width tab/button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
            child: InkWell(
              onTap: () {
                // Click behavior can be added here
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: AppStyles.primaryColor_light.withOpacity(0.2),
                    width: 0.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: AppStyles.secondaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manage Rental Items Bookings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.primaryColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // const SizedBox(height: 15), // Spacing above search bar
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: isProvider
                  ? _bookingService.getBookingsForProvider(uid)
                  : _bookingService.getBookingsForUser(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final List<DocumentSnapshot> allBookings = List.from(snapshot.data!);

                // Sorting client-side to ensure real-time responsiveness
                allBookings.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return bTime.compareTo(aTime);
                });

                // Optimized: Simplified dynamic filtering logic
                final filteredBookings = allBookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? data['bookingStatus'] ?? 'pending').toString().toLowerCase();

                  // Dynamic match based on selected tab title
                  bool matchesTab = status == _statusTabs[_selectedTab].toLowerCase();

                  if (!matchesTab) return false;

                  if (_searchQuery.isEmpty) return true;

                  final pName = (data['owner_name'] ?? data['providerName'] ?? '').toString().toLowerCase();
                  final cName = (data['renter_name'] ?? data['userName'] ?? '').toString().toLowerCase();
                  final sName = (data['item_name'] ?? data['serviceName'] ?? '').toString().toLowerCase();

                  return pName.contains(_searchQuery.toLowerCase()) ||
                      cName.contains(_searchQuery.toLowerCase()) ||
                      sName.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredBookings.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildBookingCard(booking, isProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Refactored: Simplified and Responsive TabBar
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyles.bgColor,
        border: Border(bottom: BorderSide(color: AppStyles.primaryColor_light, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(_statusTabs.length, (index) {
            return _buildTabButton(index, _statusTabs[index]);
          }),
        ),
      ),
    );
  }

  // Reusable Tab Button Widget
  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppStyles.secondaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppStyles.primaryColor : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(
          //   color: AppStyles.primaryColor_light,
          //   width: 0.2,
          // ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: "Search bookings...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: AppStyles.primaryColor),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(DocumentSnapshot doc, bool isProvider) {
    final data = doc.data() as Map<String, dynamic>;
    final String status = data['status'] ?? data['bookingStatus'] ?? 'pending';
    final String providerName = data['owner_name'] ?? data['providerName'] ?? 'Provider';
    final String clientName = data['renter_name'] ?? data['userName'] ?? 'Client';
    final String serviceName = data['item_name'] ?? data['serviceName'] ?? 'Service';
    
    // Updated: Apply custom date formatting
    final String date = _getFormattedDate(data['booking_date'] ?? data['selectedDate'] ?? data['timestamp']);
    final String time = data['time_slot'] ?? data['selectedTime'] ?? '';

    double price = 0.0;
    if (data['price'] != null) {
      if (data['price'] is num) {
        price = (data['price'] as num).toDouble();
      } else if (data['price'] is String) {
        price = double.tryParse(data['price']) ?? 0.0;
      }
    }

    final String imageUrl = data['item_image'] ?? data['providerImage'] ?? '';
    Color statusColor = status == 'accepted' ? AppStyles.primaryColor : (status == 'rejected' ? Colors.red : AppStyles.secondaryColor);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookNowScreen(
              providerData: data['serviceDetails'] ?? data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar - Fixed size, won't change
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? Text(
                      (isProvider ? clientName : providerName)[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Expanded ensures this column takes remaining space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Provider Name - Flexible with ellipsis
                        Flexible(
                          child: Text(
                            providerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppStyles.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Service Name - Flexible with ellipsis
                        Flexible(
                          child: Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Time - Flexible with ellipsis
                        Flexible(
                          child: Text(
                            "Client: $clientName",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Price & Status Column - Fixed width to prevent overflow
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 80,
                      maxWidth: 120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Price - Flexible with text wrap
                        Flexible(
                          child: Text(
                            "Rs.$price",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppStyles.secondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status Badge
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Date and Client Row - Responsive
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Date Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            date,
                            style: TextStyle(
                              color: AppStyles.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    // Client Name
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            time,
                            style: TextStyle(
                              color: AppStyles.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Buttons Section
              if (isProvider && status == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _bookingService.rejectBooking(doc.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppStyles.secondaryColor,
                            side: BorderSide(color: AppStyles.secondaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(0, 38),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (data.containsKey('status')) {
                              _bookingService.updateRentalBookingStatus(doc.id, 'accepted');
                            } else {
                              _bookingService.acceptBooking(doc.id);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            minimumSize: const Size(0, 38),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
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

  Widget _buildEmptyState() {
    String message = 'No ${_statusTabs[_selectedTab].toLowerCase()} bookings';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
