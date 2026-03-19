import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sevashare_v4/styles/appstyles.dart';
import '../custom_widgets/custom_inputfield.dart';
import '../custom_widgets/detect_location_field.dart';
import '../providers/rentals_provider.dart';
import '../services/backend_services.dart';
import '../services/location_service.dart';

class AddRentalItemScreen extends StatefulWidget {
  const AddRentalItemScreen({super.key});

  @override
  State<AddRentalItemScreen> createState() => _AddRentalItemScreenState();
}

class _AddRentalItemScreenState extends State<AddRentalItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final StoreAllRentalsInfo _firestoreService = StoreAllRentalsInfo();

  bool _isLoading = false;
  bool _offerDelivery = false;

  // --- Section 1: Item Details & Pricing Controllers ---
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _purchaseYearController = TextEditingController();
  final TextEditingController _rentPerHourController = TextEditingController();
  final TextEditingController _rentPerDayController = TextEditingController();
  final TextEditingController _securityDepositController =
  TextEditingController();
  final TextEditingController _deliveryChargeController =
  TextEditingController();

  // --- Section 2: Ownership Details Controllers ---
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();

  // --- Section 3: Location Controllers ---
  final TextEditingController _houseAreaController = TextEditingController();
  final TextEditingController _roadLandmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void dispose() {
    _itemNameController.dispose();
    _categoryController.dispose();
    _modelNumberController.dispose();
    _descController.dispose();
    _purchaseYearController.dispose();
    _rentPerHourController.dispose();
    _rentPerDayController.dispose();
    _securityDepositController.dispose();
    _deliveryChargeController.dispose();
    _ownerNameController.dispose();
    _contactNoController.dispose();
    _serialNumberController.dispose();
    _houseAreaController.dispose();
    _roadLandmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // --- Variables ---
  File? _invoiceBillImg;
  List<File> _rentalItemImages = [];
  final ImagePicker _picker = ImagePicker();

  // --- Shared Function ---
  Future<void> _selectImage({required bool isMultiple}) async {
    try {
      if (isMultiple) {
        final List<XFile> selectedImages = await _picker.pickMultiImage();
        if (selectedImages.isNotEmpty) {
          setState(() {
            _rentalItemImages.addAll(
              selectedImages.map((xFile) => File(xFile.path)).toList(),
            );
          });
        }
      } else {
        final XFile? selectedImage = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        if (selectedImage != null) {
          setState(() {
            _invoiceBillImg = File(selectedImage.path);
          });
        }
      }
    } catch (e) {
      _showSnackBar("Error picking images: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFA61617) : Colors.green,
      ),
    );
  }

  void _clearForm() {
    _itemNameController.clear();
    _categoryController.clear();
    _modelNumberController.clear();
    _descController.clear();
    _purchaseYearController.clear();
    _rentPerHourController.clear();
    _rentPerDayController.clear();
    _securityDepositController.clear();
    _deliveryChargeController.clear();
    _ownerNameController.clear();
    _contactNoController.clear();
    _serialNumberController.clear();
    _houseAreaController.clear();
    _roadLandmarkController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    setState(() {
      _offerDelivery = false;
      _invoiceBillImg = null;
      _rentalItemImages.clear();
    });
  }

  void _onLocationDetected(Map<String, dynamic> details) {
    setState(() {
      _houseAreaController.text = details['name'] ?? details['street'] ?? '';
      _roadLandmarkController.text = details['subLocality'] ?? details['locality'] ?? '';
      _cityController.text = details['locality'] ?? '';
      _stateController.text = details['administrativeArea'] ?? '';
      _pincodeController.text = details['postalCode'] ?? '';
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_contactNoController.text.trim().length != 10) {
        _showSnackBar(
          'Please enter a valid 10-digit contact number.',
          isError: true,
        );
        return;
      }

      if (_rentalItemImages.isEmpty) {
        _showSnackBar('Please add at least one item image.', isError: true);
        return;
      }

      setState(() => _isLoading = true);

      // 📌 Latitude & Longitude Detection from address
      final String fullAddress = "${_houseAreaController.text.trim()}, "
          "${_roadLandmarkController.text.trim()}, "
          "${_cityController.text.trim()}, "
          "${_stateController.text.trim()}, "
          "${_pincodeController.text.trim()}";

      final Map<String, double>? coordinates = await LocationService.getCoordinatesFromAddress(fullAddress);

      if (coordinates == null || coordinates['latitude'] == null || coordinates['longitude'] == null) {
        setState(() => _isLoading = false);
        _showSnackBar('Enter valid address', isError: true);
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Error: You must be logged in to add a rental item.',
          isError: true,
        );
        return;
      }

      try {
        _showSnackBar('Uploading images... Please wait.');

        List<String> rentalItemImageUrls = [];
        if (_rentalItemImages.isNotEmpty) {
          rentalItemImageUrls = await ImgBBService.uploadMultipleImages(_rentalItemImages);
        }

        String? invoiceImageUrl;
        if (_invoiceBillImg != null) {
          invoiceImageUrl = await ImgBBService.uploadImage(_invoiceBillImg!);
        }

        final rentalsProvider = Provider.of<RentalsProvider>(context, listen: false);
        final String rentalItemId = rentalsProvider.generateRentalItemId(currentUser.uid);

        final Map<String, dynamic> rentalData = {
          'rental_item_id': rentalItemId,
          'currentUser_uid': currentUser.uid,
          'item_name': _itemNameController.text.trim(),
          'category': _categoryController.text.trim(),
          'model_number': _modelNumberController.text.trim(),
          'description': _descController.text.trim(),
          'purchase_year': int.tryParse(_purchaseYearController.text.trim()) ?? 0,
          'item_images': rentalItemImageUrls,
          'invoice_image_url': invoiceImageUrl,
          'rent_per_hour':
          double.tryParse(_rentPerHourController.text.trim()) ?? 0.0,
          'rent_per_day':
          double.tryParse(_rentPerDayController.text.trim()) ?? 0.0,
          'security_deposit':
          double.tryParse(_securityDepositController.text.trim()) ?? 0.0,
          'offer_delivery': _offerDelivery,
          'delivery_charge': _offerDelivery
              ? (double.tryParse(_deliveryChargeController.text.trim()) ?? 0.0)
              : 0.0,
          'owner_name': _ownerNameController.text.trim(),
          'contact_no': _contactNoController.text.trim(),
          'serial_or_proof': _serialNumberController.text.trim(),
          'address': {
            'house_area': _houseAreaController.text.trim(),
            'road_landmark': _roadLandmarkController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'pincode': _pincodeController.text.trim(),
            'latitude': coordinates['latitude'],
            'longitude': coordinates['longitude'],
          },
          'created_at': FieldValue.serverTimestamp(),
        };

        final bool success = await _firestoreService.saveRentalsDetails(
            rentalData, rentalItemId
        );

        setState(() => _isLoading = false);

        if (success) {
          _showSnackBar('Rental item added successfully!');
          _clearForm();
        } else {
          _showSnackBar(
            'Failed to add rental item. Please try again.',
            isError: true,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isError: true);
      }
    } else {
      _showSnackBar('Please fill in all required fields.', isError: true);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppStyles.primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add Rental Item",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppStyles.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppStyles.primaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('> Item Details & Pricing'),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: _rentalItemImages.isEmpty
                              ? GestureDetector(
                            onTap: () => _selectImage(isMultiple: true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                                border:
                                Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Add Item Images",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                              : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _rentalItemImages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _rentalItemImages.length) {
                                return GestureDetector(
                                  onTap: () => _selectImage(isMultiple: true),
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.grey),
                                  ),
                                );
                              }
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: FileImage(_rentalItemImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _rentalItemImages.removeAt(index);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close,
                                            size: 15, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Max 5 clear photos recommended",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    CustomInputField(
                      controller: _itemNameController,
                      labelText: 'Item Name',
                      warning: 'Please enter item name',
                      prefixIcon: Icon(Icons.inventory_2_outlined,
                          color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            controller: _categoryController,
                            labelText: 'Category',
                            warning: 'Enter category',
                            prefixIcon: Icon(Icons.category_outlined,
                                color: AppStyles.secondaryColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomInputField(
                            controller: _modelNumberController,
                            labelText: 'Model (Optional)',
                            warning: '',
                            prefixIcon: Icon(Icons.numbers,
                                color: AppStyles.secondaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _descController,
                      labelText: 'Short Description',
                      warning: 'Please enter description',
                      maxlines: 3,
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _purchaseYearController,
                      labelText: 'Purchase Year (Approx)',
                      warning: 'Enter year',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.calendar_today_outlined,
                          color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 24),

                    // Pricing Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            controller: _rentPerHourController,
                            labelText: 'Rent /Hr',
                            warning: 'Required',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(Icons.timer_outlined,
                                color: AppStyles.secondaryColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomInputField(
                            controller: _rentPerDayController,
                            labelText: 'Rent /Day',
                            warning: 'Required',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(Icons.today_outlined,
                                color: AppStyles.secondaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _securityDepositController,
                      labelText: 'Security Deposit (If any)',
                      warning: '',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.lock_outline,
                          color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Option Switch
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppStyles.primaryColor_light),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text('Offer Delivery'),
                        subtitle: const Text(
                          'Turn on if you can deliver this item to the renter\'s location.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _offerDelivery,
                        activeColor: Colors.green,
                        onChanged: (bool value) {
                          setState(() {
                            _offerDelivery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_offerDelivery)
                      CustomInputField(
                        controller: _deliveryChargeController,
                        labelText: 'Delivery Charge (One way)',
                        warning: 'Required',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icon(Icons.delivery_dining,
                            color: AppStyles.secondaryColor),
                      ),

                    const SizedBox(height: 10),
                    const Divider(thickness: 1),

                    // SECTION 2: Ownership Details
                    _buildSectionHeader('> Ownership Details'),

                    CustomInputField(
                      controller: _ownerNameController,
                      labelText: 'Owner / Full Name',
                      warning: 'Enter owner name',
                      prefixIcon:
                      Icon(Icons.person, color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _contactNoController,
                      labelText: 'Contact Number',
                      warning: 'Enter 10-digit number',
                      keyboardType: TextInputType.phone,
                      prefixIcon:
                      Icon(Icons.phone, color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _serialNumberController,
                      labelText: 'Serial Number / ID Proof Reference',
                      warning: 'Enter reference info',
                      prefixIcon: Icon(Icons.verified_user_outlined,
                          color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    // Invoice Picker
                    GestureDetector(
                      onTap: () => _selectImage(isMultiple: false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: AppStyles.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _invoiceBillImg != null
                                    ? "Invoice/Bill Selected"
                                    : "Upload Invoice/Bill (Optional)",
                                style: TextStyle(
                                  color: _invoiceBillImg != null
                                      ? AppStyles.secondaryColor
                                      : Colors.grey[600],
                                  fontWeight: _invoiceBillImg != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_invoiceBillImg != null)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else
                              const Icon(Icons.cloud_upload_outlined,
                                  color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(thickness: 1),

                    // SECTION 3: Location Details
                    _buildSectionHeader('> Location Details'),

                    DetectLocationField(onLocationDetected: _onLocationDetected),
                    const SizedBox(height: 15),

                    CustomInputField(
                      controller: _houseAreaController,
                      labelText: 'House No / Building / Area',
                      warning: 'Required',
                      prefixIcon:
                      Icon(Icons.home_outlined, color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _roadLandmarkController,
                      labelText: 'Road / Landmark',
                      warning: 'Required',
                      prefixIcon:
                      Icon(Icons.map_outlined, color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            controller: _cityController,
                            labelText: 'City',
                            warning: 'Required',
                            prefixIcon: Icon(Icons.location_city,
                                color: AppStyles.secondaryColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomInputField(
                            controller: _stateController,
                            labelText: 'State',
                            warning: 'Required',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      controller: _pincodeController,
                      labelText: 'Pincode',
                      warning: 'Required',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.pin_drop_outlined,
                          color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 40),

                  ],
                ),
              ),
            ),
          ),
          // 📌 Fixed Submit Button
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
                  onPressed: _isLoading ? null : _submitForm,
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
                    'Add Rental Item',
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
}
