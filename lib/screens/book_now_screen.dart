import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../services/backend_services.dart';
import '../styles/appstyles.dart';
import '../utils/calculate_distance.dart';

class BookNowScreen extends StatefulWidget {
  final Map<String, dynamic> providerData;
  final double? distance;
  final double? averageRating;
  final int? totalReviewCount;

  const BookNowScreen({
    super.key,
    required this.providerData,
    this.distance,
    this.averageRating,
    this.totalReviewCount,
  });

  @override
  State<BookNowScreen> createState() => _BookNowScreenState();
}

class _BookNowScreenState extends State<BookNowScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  String? _selectedDayPart; // Targeted change: track selected day part
  bool _isBooking = false;
  bool _isLoadingSlots = false;
  bool _isLoadingData = true;
  Map<String, dynamic>? _fullServiceData;
  List<String> _bookedSlots = [];
  final BookingService _bookingService = BookingService();

  // Review state
  final TextEditingController _reviewController = TextEditingController();
  int _userRating = 0;
  bool _isSubmittingReview = false;

  bool get ready =>
      _selectedDate != null && _selectedSlot != null && !_isBooking;

  final Map<String, List<String>> _groupedSlots = {
    "Morning": [
      "06:00 AM - 07:00 AM",
      "07:00 AM - 08:00 AM",
      "08:00 AM - 09:00 AM",
      "09:00 AM - 10:00 AM",
      "10:00 AM - 11:00 AM",
      "11:00 AM - 12:00 PM",
    ],
    "Afternoon": [
      "12:00 PM - 01:00 PM",
      "01:00 PM - 02:00 PM",
      "02:00 PM - 03:00 PM",
      "03:00 PM - 04:00 PM",
      "04:00 PM - 05:00 PM",
    ],
    "Evening": [
      "05:00 PM - 06:00 PM",
      "06:00 PM - 07:00 PM",
      "07:00 PM - 08:00 PM",
      "08:00 PM - 09:00 PM",
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchFullServiceDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullServiceDetails() async {
    setState(() => _isLoadingData = true);
    try {
      final String providerUid =
          widget.providerData['provider_uid'] ??
              widget.providerData['uid'] ??
              '';
      final String serviceId = widget.providerData['service_id'] ?? '';

      if (providerUid.isNotEmpty && serviceId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(providerUid)
            .collection('services')
            .doc(serviceId)
            .get();

        if (doc.exists) {
          // Re-inject IDs because they are often not in the document body
          _fullServiceData = Map<String, dynamic>.from(doc.data()!);
          _fullServiceData?['service_id'] = serviceId;
          _fullServiceData?['provider_uid'] = providerUid;
        }
      }

      if (_fullServiceData == null) {
        _fullServiceData = Map<String, dynamic>.from(widget.providerData);
      } else {
        // Fallback IDs if they somehow didn't get set
        _fullServiceData?['service_id'] ??= serviceId;
        _fullServiceData?['provider_uid'] ??= providerUid;
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
      debugPrint("Error fetching service details: $e");
      _fullServiceData ??= Map<String, dynamic>.from(widget.providerData);
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      String providerId =
          widget.providerData['provider_uid'] ??
              widget.providerData['uid'] ??
              '';
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: providerId)
          .where('selectedDate', isEqualTo: formattedDate)
          .where('bookingStatus', isNotEqualTo: 'cancelled')
          .get();

      List<String> booked = snapshot.docs
          .map((doc) => doc.data()['selectedTime'] as String)
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
      initialDate: DateTime.now(),
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

  void _handleBooking() async {
    if (_selectedDate == null || _selectedSlot == null) return;
    setState(() => _isBooking = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String providerUid =
        widget.providerData['provider_uid'] ?? widget.providerData['uid'] ?? '';

    final bookingData = {
      'userUid': userProvider.uid,
      'userName': userProvider.username,
      'providerId': providerUid,
      'providerName': _fullServiceData?['full_name'] ?? 'Provider',
      'providerProfession': _fullServiceData?['profession'] ?? 'Service',
      'providerImage': _fullServiceData?['profile_image_url'] ?? '',
      'serviceName':
      _fullServiceData?['service_category'] ??
          _fullServiceData?['profession'] ??
          'Service',
      'price': _fullServiceData?['hourly_rate'] ?? 0.0,
      'selectedDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'selectedTime': _selectedSlot,
      'bookingStatus': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'serviceDetails': _fullServiceData,
    };

    bool success = await _bookingService.createBooking(bookingData);
    setState(() => _isBooking = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request sent successfully!')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create booking. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleSubmitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
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

    // Defensive extraction of IDs from ALL available sources
    String providerUid = _fullServiceData?['provider_uid'] ?? '';
    if (providerUid.isEmpty) providerUid = _fullServiceData?['uid'] ?? '';
    if (providerUid.isEmpty)
      providerUid = widget.providerData['provider_uid'] ?? '';
    if (providerUid.isEmpty) providerUid = widget.providerData['uid'] ?? '';

    String serviceId = _fullServiceData?['service_id'] ?? '';
    if (serviceId.isEmpty) serviceId = widget.providerData['service_id'] ?? '';

    if (providerUid.isEmpty || serviceId.isEmpty) {
      setState(() => _isSubmittingReview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Service identifiers missing. Cannot submit review.',
          ),
        ),
      );
      return;
    }

    final reviewData = {
      'userUid': userProvider.uid,
      'userName': userProvider.username,
      'providerId': providerUid,
      'providerName': _fullServiceData?['full_name'] ?? 'Provider',
      'rating': _userRating,
      'review': _reviewController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    bool success = await _bookingService.submitReview(
      providerUid,
      serviceId,
      reviewData,
    );

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
        const SnackBar(
          content: Text('Failed to submit review. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: AppStyles.bgColor,
        appBar: AppBar(backgroundColor: AppStyles.primaryColor, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _fullServiceData ?? widget.providerData;

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  _buildProviderHeader(data),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(data),
                        const SizedBox(height: 24),
                        _buildAboutSection(data),
                        const SizedBox(height: 24),
                        _buildServiceDetailsBox(data),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Select Date'),
                        // Select Date & Time Slots
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
                        const SizedBox(height: 40),

                        // Ratings & Review Section
                        _buildReviewsSection(data),
                        const SizedBox(height: 24),
                        _buildWriteReviewSection(),
                        const SizedBox(height: 24),


                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed Booking Button
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
                  style: AppStyles.primaryButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey[300]!;
                        }
                        return AppStyles.primaryColor;
                      },
                    ),
                  ),
                  onPressed: ready ? _handleBooking : null,
                  child: _isBooking
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Book Service',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],

      ),
    );
  }

  Widget _buildProviderHeader(Map<String, dynamic> data) {
    final int reviewCount = widget.totalReviewCount ?? (data['reviews_count'] ?? 0);
    final double rating = widget.averageRating ?? (data['rating'] ?? 0.0).toDouble();
    final bool isNew = reviewCount <= 0;

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
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white24,
            backgroundImage:
            data['profile_image_url'] != null &&
                data['profile_image_url'].isNotEmpty
                ? NetworkImage(data['profile_image_url'])
                : null,
            child:
            data['profile_image_url'] == null ||
                data['profile_image_url'].isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['full_name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  data['profession'] ?? 'Service Provider',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                if (isNew)
                  Text(
                    "New",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' ($reviewCount reviews)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
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
                "Rs.${data['hourly_rate']}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "/hr",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    double? d = widget.distance ?? (data['distance'] ?? data['_distance'])?.toDouble();
    String distanceStr = d != null ? CalculateDistance.formatDistance(d) : 'N/A';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(distanceStr, 'Distance'),
        _buildStatItem(data['jobs_done']?.toString() ?? '342', 'Jobs Done'),
        _buildStatItem('Rs.${data['hourly_rate']}/hr', 'Rate'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About'),
        const SizedBox(height: 8),
        Text(
          data['service_description'] ??
              'No description available for this service.',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildServiceDetailsBox(Map<String, dynamic> data) {
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
          const Text(
            "Service Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.handyman_outlined,
            data['service_name'] ?? data['profession'] ?? 'General Service',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.access_time,
            "Duration: ${data['duration'] ?? '2 hours'}",
          ),
          if (data['experience_years'] != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.work_outline,
              "Experience: ${data['experience_years']} years",
            ),
          ],
          if (data['contact_no'] != null && data['contact_no'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.phone,
              "Contact: ${data['contact_no']}",
            ),
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(Map<String, dynamic> data) {
    // Robustly extract IDs
    String providerUid = data['provider_uid'] ?? '';
    if (providerUid.isEmpty) providerUid = data['uid'] ?? '';
    if (providerUid.isEmpty)
      providerUid = widget.providerData['provider_uid'] ?? '';
    if (providerUid.isEmpty) providerUid = widget.providerData['uid'] ?? '';

    String serviceId = data['service_id'] ?? '';
    if (serviceId.isEmpty) serviceId = widget.providerData['service_id'] ?? '';

    final int reviewCount = widget.totalReviewCount ?? (data['reviews_count'] ?? 0);
    final double rating = widget.averageRating ?? (data['rating'] ?? 0.0).toDouble();
    final bool isNew = reviewCount <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Ratings & Reviews'),
            if (isNew)
              Text(
                "New",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppStyles.secondaryColor,
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    ' ($reviewCount reviews)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (providerUid.isEmpty || serviceId.isEmpty)
          _buildNoReviewsState()
        else
          StreamBuilder<QuerySnapshot>(
            stream: _bookingService.getServiceReviews(providerUid, serviceId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoReviewsState();
              }

              final reviews = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length > 3
                    ? 3
                    : reviews.length, // Show top 3 reviews
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final reviewData =
                  reviews[index].data() as Map<String, dynamic>;
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
                style: TextStyle(
                  color: AppStyles.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['userName'] ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (review['rating'] ?? 5)
                            ? Icons.star
                            : Icons.star_border,
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
                DateFormat(
                  'dd MMM yyyy',
                ).format((review['timestamp'] as Timestamp).toDate()),
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
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
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
                borderSide: BorderSide(color: Colors.grey.shade200),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSubmittingReview
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Submit Review',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
              _selectedSlot = null; // Reset slot when day part changes
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppStyles.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppStyles.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  dayPart,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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

    final slots = _groupedSlots[_selectedDayPart]!
        .where((slot) => !_bookedSlots.contains(slot))
        .toList();

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
              color: isSelected
                  ? AppStyles.secondaryColor
                  : (isBooked ? Colors.grey[200] : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppStyles.secondaryColor
                    : (isBooked ? Colors.transparent : Colors.grey[300]!),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : (isBooked ? Colors.grey[400] : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
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
              _selectedDate == null
                  ? 'Choose Date'
                  : DateFormat('dd MMM, yyyy').format(_selectedDate!),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppStyles.primaryColor,
      ),
    );
  }
}
