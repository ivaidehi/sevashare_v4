import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../custom_widgets/custom_navbar.dart';
import '../providers/user_provider.dart';
import '../services/backend_services.dart';
import '../styles/appstyles.dart';
import '../custom_widgets/custom_appbar.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0; // 0: Pending, 1: Accepted
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String uid = userProvider.uid;
    final bool isProvider = userProvider.userType == 'service_provider';

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: "Rentals",
        onBackPressed: () {
          ChangeTabNotification(0).dispatch(context);
        },
        actionIcon: Icons.bookmark_border_rounded,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final List<DocumentSnapshot> allBookings = List.from(snapshot.data!.docs);

                // Sorting client-side to ensure real-time responsiveness
                allBookings.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return bTime.compareTo(aTime);
                });

                final filteredBookings = allBookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? data['bookingStatus'] ?? 'pending';
                  if (_selectedTab == 0) return status == 'pending';
                  if (_selectedTab == 1) return status == 'accepted';
                  return false;
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          _buildTabButton(0, 'Pending'),
          const SizedBox(width: 10),
          _buildTabButton(1, 'Accepted'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppStyles.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppStyles.primaryColor : Colors.grey.shade200),
            boxShadow: isSelected ? [BoxShadow(color: AppStyles.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
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

    Color statusColor = status == 'accepted' ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => _showBookingDetails(context, data, doc.id, isProvider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(status == 'accepted' ? Icons.check_circle : Icons.pending_actions, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          isProvider ? clientName : providerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const Text(" 4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty ? Text((isProvider ? clientName : providerName)[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(data.containsKey('item_name') ? Icons.inventory_2_outlined : Icons.handyman_outlined, size: 16, color: AppStyles.secondaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              serviceName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 16, color: AppStyles.secondaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "$date  $time",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: AppStyles.secondaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "2.5 km away",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Rs.$price",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (isProvider && status == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(80, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> data, String bookingId, bool isProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailsPopup(data: data, bookingId: bookingId, isProvider: isProvider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0 ? 'No pending bookings' : 'No accepted bookings',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final bool isProvider;

  const _BookingDetailsPopup({required this.data, required this.bookingId, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final String providerName = data['owner_name'] ?? data['providerName'] ?? 'Provider';
    final String profession = data['category'] ?? data['providerProfession'] ?? 'Service Provider';
    final String imageUrl = data['item_image'] ?? data['providerImage'] ?? '';
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

    final serviceDetails = data['serviceDetails'] ?? {};
    final String about = data['description'] ?? serviceDetails['service_description'] ?? 'No description available.';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 25),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty ? Icon(Icons.person, size: 40, color: AppStyles.primaryColor) : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(providerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(profession, style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const Text(" 4.8 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text("(156 reviews)", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("2.5 km", "Distance"),
                      _buildStatItem("342", "Jobs Done"),
                      _buildStatItem("Rs.$price", "Price"),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("About", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(about, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Booking Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildDetailRow(data.containsKey('item_name') ? Icons.inventory_2 : Icons.handyman, data['item_name'] ?? data['serviceName'] ?? "Service"),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.calendar_today, "Date: $date"),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.schedule, "Time: $time"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (isProvider && (data['status'] == 'pending' || data['bookingStatus'] == 'pending'))
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (data.containsKey('status')) {
                            BookingService().updateRentalBookingStatus(bookingId, 'accepted');
                          } else {
                            BookingService().acceptBooking(bookingId);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Accept Booking", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Close", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppStyles.secondaryColor.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade700))),
      ],
    );
  }
}
