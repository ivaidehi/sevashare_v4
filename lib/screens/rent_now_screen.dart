import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/rentals_provider.dart';
import '../providers/user_provider.dart';
import '../services/backend_services.dart';
import '../styles/appstyles.dart';
import 'bookings_screen.dart';

class RentNowScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const RentNowScreen({super.key, required this.item});

  @override
  State<RentNowScreen> createState() => _RentNowScreenState();
}

class _RentNowScreenState extends State<RentNowScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  String? _selectedDayPart;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _userRating = 0;
  bool _isSubmittingReview = false;
  List<String> _bookedSlots = [];
  final BookingService _bookingService = BookingService();

  bool get ready =>
      _selectedDate != null &&
      _selectedSlot != null &&
      !_isLoading &&
      _descriptionController.text.trim().isNotEmpty;

  final Map<String, List<String>> _groupedSlots = {
    "Morning": [
      "06:00 AM - 07:00 AM",
      "07:00 AM - 08:00 AM",
      "08:00 AM - 09:00 AM",
      "09:00 AM - 10:00 AM",
      "10:00 AM - 11:00 AM",
      "11:00 AM - 12:00 PM"
    ],
    "Afternoon": [
      "12:00 PM - 01:00 PM",
      "01:00 PM - 02:00 PM",
      "02:00 PM - 03:00 PM",
      "03:00 PM - 04:00 PM",
      "04:00 PM - 05:00 PM"
    ],
    "Evening": [
      "05:00 PM - 06:00 PM",
      "06:00 PM - 07:00 PM",
      "07:00 PM - 08:00 PM",
      "08:00 PM - 09:00 PM"
    ],
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      String itemId = widget.item['rental_item_id'] ?? '';
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('item_id', isEqualTo: itemId)
          .where('booking_date', isEqualTo: formattedDate)
          .where('status', isNotEqualTo: 'cancelled')
          .get();

      List<String> booked = snapshot.docs
          .map((doc) => doc.data()['time_slot'] as String)
          .toList();

      setState(() {
        _bookedSlots = booked;
        _isLoadingSlots = false;
      });
    } catch (e) {
      debugPrint("Error fetching slots: $e");
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppStyles.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchBookedSlots(picked);
    }
  }

  Future<void> _handleRentNow() async {
    if (!ready) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rentalsProvider = Provider.of<RentalsProvider>(context, listen: false);

    final String ownerId = widget.item['owner_uid'] ?? widget.item['currentUser_uid'] ?? '';

    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Provider information is missing.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    final bookingData = {
      'item_id': widget.item['rental_item_id'],
      'item_name': widget.item['item_name'],
      'item_image': (widget.item['item_images'] as List).isNotEmpty ? widget.item['item_images'][0] : '',
      'owner_id': ownerId,
      'owner_name': widget.item['owner_name'],
      'renter_id': userProvider.uid,
      'renter_name': userProvider.username,
      'booking_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'time_slot': _selectedSlot,
      'price': widget.item['rent_per_day'],
      'status': 'pending',
      'description': _descriptionController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    bool success = await rentalsProvider.bookRental(bookingData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rental request sent successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookingsScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item not available for this slot or error occurred.")),
        );
      }
    }
  }

  Future<void> _handleSubmitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review comment')),
      );
      return;
    }

    setState(() => _isSubmittingReview = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String ownerId = widget.item['owner_uid'] ?? widget.item['currentUser_uid'] ?? '';
    final String itemId = widget.item['rental_item_id'] ?? '';

    if (ownerId.isEmpty || itemId.isEmpty) {
      setState(() => _isSubmittingReview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Rental identifiers missing.')),
      );
      return;
    }

    final reviewData = {
      'userUid': userProvider.uid,
      'userName': userProvider.username,
      'ownerId': ownerId,
      'itemName': widget.item['item_name'],
      'rating': _userRating,
      'review': _reviewController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    bool success = await _bookingService.submitRentalReview(ownerId, itemId, reviewData);

    if (!mounted) return;
    setState(() => _isSubmittingReview = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
      setState(() {
        _userRating = 0;
        _reviewController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.item['item_images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images[0] : '';
    final String name = widget.item['item_name'] ?? 'No Name';
    final String category = widget.item['category'] ?? 'General';
    final double rentPerDay = (widget.item['rent_per_day'] ?? 0.0).toDouble();
    final String owner = widget.item['owner_name'] ?? 'Unknown';
    final String description = widget.item['description'] ?? 'No description provided.';

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(
        title: const Text('Confirm Rental', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildItemHeader(imageUrl, name, category, rentPerDay),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('About Item'),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        _buildRentalDetailsBox(owner, category),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Select Date'),
                        _buildDatePicker(),
                        if (_selectedDate != null) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('Select Day Part'),
                          const SizedBox(height: 12),
                          _buildDayParts(),
                          const SizedBox(height: 24),
                          if (_selectedDayPart != null) ...[
                            _buildSectionTitle('Select Time Slot'),
                            const SizedBox(height: 12),
                            if (_isLoadingSlots)
                              const Center(child: CircularProgressIndicator())
                            else
                              _buildTimeSlotsSection(),
                          ],
                        ],
                        const SizedBox(height: 24),
                        _buildSectionTitle('Description / Purpose'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Enter the purpose of renting (Required)",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppStyles.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildReviewsSection(),
                        const SizedBox(height: 24),
                        _buildWriteReviewSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed Rent Now Button at Bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: ready ? _handleRentNow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Rent Now',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader(String imageUrl, String name, String category, double price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white24),
              errorWidget: (context, url, error) => Container(
                color: Colors.white24,
                child: const Icon(Icons.image_not_supported, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  category,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    const Text(
                      '4.8',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Rs.$price",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "/day",
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('2.5 km', 'Distance'),
        _buildStatItem('Available', 'Status'),
        _buildStatItem('Verified', 'Owner'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildRentalDetailsBox(String owner, String category) {
    final String contact = widget.item['contact_no']?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rental Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person_outline, "Owner: $owner"),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.category_outlined, "Category: $category"),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.check_circle_outline, "Condition: Excellent"),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone, "Contact: $contact"),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppStyles.secondaryColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14))),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final String ownerId = widget.item['owner_uid'] ?? widget.item['currentUser_uid'] ?? '';
    final String itemId = widget.item['rental_item_id'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Ratings & Reviews'),
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  '4.8',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ownerId.isEmpty || itemId.isEmpty)
          _buildNoReviewsState()
        else
          StreamBuilder<QuerySnapshot>(
            stream: _bookingService.getRentalReviews(ownerId, itemId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoReviewsState();
              }

              final reviews = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length > 3 ? 3 : reviews.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final reviewData = reviews[index].data() as Map<String, dynamic>;
                  return _buildReviewItem(reviewData);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppStyles.primaryColor.withOpacity(0.1),
              child: Text(
                (review['userName'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(color: AppStyles.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['userName'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (review['rating'] ?? 5) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ),
            if (review['timestamp'] != null)
              Text(
                DateFormat('dd MMM yyyy').format((review['timestamp'] as Timestamp).toDate()),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review['review'] ?? 'No comment provided.',
          style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildNoReviewsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'No reviews yet',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWriteReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Write a Review'),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _userRating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppStyles.primaryColor),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isSubmittingReview ? null : _handleSubmitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.secondaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSubmittingReview
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text(
                'Submit Review',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppStyles.primaryColor),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null ? 'Choose Date' : DateFormat('dd MMM, yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey : Colors.black87,
                fontSize: 16,
              ),
            ),
            Icon(Icons.calendar_month, color: AppStyles.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDayParts() {
    return Row(
      children: _groupedSlots.keys.map((dayPart) {
        bool isSelected = _selectedDayPart == dayPart;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedDayPart = dayPart;
              _selectedSlot = null;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppStyles.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppStyles.primaryColor : Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  dayPart,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotsSection() {
    if (_selectedDayPart == null) return const SizedBox.shrink();

    final slots = _groupedSlots[_selectedDayPart]!;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        bool isBooked = _bookedSlots.contains(slot);
        bool isSelected = _selectedSlot == slot;
        return GestureDetector(
          onTap: isBooked ? null : () => setState(() => _selectedSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppStyles.secondaryColor : (isBooked ? Colors.grey[200] : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppStyles.secondaryColor : (isBooked ? Colors.transparent : Colors.grey[300]!),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : (isBooked ? Colors.grey[400] : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
