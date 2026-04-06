import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        actionIcon: Icons.bookmark_border_rounded,
      ),
      body: Column(
        children: [
          _buildTabs(), // UI : Instagram-style tabs
          _buildSearchBar(), // UI : Search bar added below tabs
          Expanded(
            // 🔽 FIX 1: Change QuerySnapshot to List<DocumentSnapshot>
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

                // 🔽 FIX 2: Use snapshot.data!.isEmpty instead of snapshot.data!.docs.isEmpty
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // 🔽 FIX 3: Directly use snapshot.data! since it is already a List<DocumentSnapshot>
                final List<DocumentSnapshot> allBookings = List.from(snapshot.data!);

                // Sorting client-side to ensure real-time responsiveness
                allBookings.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return bTime.compareTo(aTime);
                });

                // UI : Updated filtering logic with Search and Tabs
                final filteredBookings = allBookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? data['bookingStatus'] ?? 'pending';

                  bool matchesTab = false;
                  if (_selectedTab == 0) matchesTab = (status == 'pending');
                  else if (_selectedTab == 1) matchesTab = (status == 'accepted');
                  else if (_selectedTab == 2) matchesTab = (status == 'rejected');

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

  Widget _buildTabs() {
    return Container(
      // UI: Instagram-style horizontal tabs with indicator line
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Pending'),
          _buildTabButton(1, 'Accepted'),
          _buildTabButton(2, 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      // UI : Rounded search bar with clean modern UI
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search",
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
    final String date = data['booking_date'] ?? data['selectedDate'] ?? '';
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
    Color statusColor = status == 'accepted' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);

    return InkWell(
      // Navigation: Tapping card navigates directly to Book Now screen
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          // Card Layout Fix: Use mainAxisSize.min to allow card to expand based on content
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty ? Text((isProvider ? clientName : providerName)[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 12),
                // Main Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isProvider ? clientName : providerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        maxLines: 1,
                      ),
                      Text(
                        serviceName,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      // Time Visibility Fix: Use Wrap to ensure Date and Time are both visible even on small screens
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ],
                          ),
                          // Time Visibility Fix: Specifically ensured time is visible by placing it in its own flexible row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  time,
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price and Status Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Rs.$price",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Accept / Reject Buttons Fix: Horizontally aligned with proper spacing and responsive sizing
            if (isProvider && status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _bookingService.rejectBooking(doc.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(0, 36), // Removed hardcoded width for responsiveness
                        ),
                        child: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          minimumSize: const Size(0, 36), // Removed hardcoded width for responsiveness
                        ),
                        child: const Text('Accept', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildEmptyState() {
    String message = 'No pending bookings';
    if (_selectedTab == 1) message = 'No accepted bookings';
    if (_selectedTab == 2) message = 'No rejected bookings';

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