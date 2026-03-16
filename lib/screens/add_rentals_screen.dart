import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevashare_v4/styles/appstyles.dart';
import '../custom_widgets/custom_inputfield.dart';
import '../services/firebase_service.dart';

class AddRentalItemScreen extends StatefulWidget {
  const AddRentalItemScreen({super.key});

  @override
  State<AddRentalItemScreen> createState() => _AddRentalItemScreenState();
}

class _AddRentalItemScreenState extends State<AddRentalItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Assuming you add a saveRentalDetails method to your existing service file
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
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _deliveryChargeController = TextEditingController();

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

  // Invoice Upload Variables
  File? _invoiceBillImg;
  File? _rentalItemImg;
  final ImagePicker _picker = ImagePicker();

  // Function to pick the invoice image
  Future<void> _selectImage() async {
    try {
      // ImagePicker handles the basic "Ask" on many devices automatically
      final XFile? selectImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (selectImage != null) {
        setState(() => _invoiceBillImg = File(selectImage.path), );
        setState(() => _rentalItemImg = File(selectImage.path));
      }
    } catch (e) {
      _showSnackBar("Error picking image: $e", isError: true);
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
      _offerDelivery = true;
      _invoiceBillImg = null;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {

      if (_contactNoController.text.trim().length != 10) {
        _showSnackBar('Please enter a valid 10-digit contact number.', isError: true);
        return;
      }
      if (_pincodeController.text.trim().length != 6) {
        _showSnackBar('Please enter a valid 6-digit pincode.', isError: true);
        return;
      }

      setState(() => _isLoading = true);

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: You must be logged in to add a rental item.', isError: true);
        return;
      }

      // String? invoiceUrl;
      // if (_invoiceFile != null) {
      //   // Use the same upload function you built for the profile picture!
      //   invoiceUrl = await _firestoreService.uploadProfileImage(_invoiceFile!);
      // }

      // Map all values into a dictionary
      final Map<String, dynamic> rentalData = {
        'currentUser_uid': currentUser.uid,
        // Item Details
        'item_name': _itemNameController.text.trim(),
        'category': _categoryController.text.trim(),
        'model_number': _modelNumberController.text.trim(),
        'description': _descController.text.trim(),
        'purchase_year': int.tryParse(_purchaseYearController.text.trim()) ?? 0,
        // Pricing
        'rent_per_hour': double.tryParse(_rentPerHourController.text.trim()) ?? 0.0,
        'rent_per_day': double.tryParse(_rentPerDayController.text.trim()) ?? 0.0,
        'security_deposit': double.tryParse(_securityDepositController.text.trim()) ?? 0.0,
        'offer_delivery': _offerDelivery,
        'delivery_charge': _offerDelivery
            ? (double.tryParse(_deliveryChargeController.text.trim()) ?? 0.0)
            : 0.0,
        // Ownership
        'owner_name': _ownerNameController.text.trim(),
        'contact_no': _contactNoController.text.trim(),
        'serial_or_proof': _serialNumberController.text.trim(),
        // Location
        'address': {
          'house_area': _houseAreaController.text.trim(),
          'road_landmark': _roadLandmarkController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'created_at': FieldValue.serverTimestamp(),
      };

      // Ensure you add a method called `saveRentalDetails` in your service file!
      final bool success = await _firestoreService.saveRentalsDetails(rentalData);

      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar('Rental item added successfully!');
        _clearForm();
      } else {
        _showSnackBar('Failed to add rental item. Please try again.', isError: true);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // SECTION 1: Item Details & Pricing---------------------------
              _buildSectionHeader('> Item Details & Pricing'),

              // 📸 Images Section Placeholder
              Center(
                child: GestureDetector(
                  onTap: _selectImage,
                  child: AnimatedContainer( // Switched to AnimatedContainer for a smooth feel
                    duration: const Duration(milliseconds: 300),
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // Changes to a soft secondary/primary tint when image is picked
                      color: _rentalItemImg != null ? AppStyles.secondaryColor.withOpacity(0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _rentalItemImg != null ? AppStyles.secondaryColor : Colors.grey.shade400,
                        width: _rentalItemImg != null ? 1 : 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _rentalItemImg == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text('Tap to Add Item Images', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    )
                        : Column( // New UI state for when image is selected
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 40),
                        const SizedBox(height: 8),
                        const Text('Item Image Added', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Tap to change image', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CustomInputField(
                controller: _itemNameController,
                labelText: 'Item Name',
                warning: 'Please enter the item name',
                prefixIcon: Icon(Icons.inventory_2_outlined, color: AppStyles.secondaryColor),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      controller: _categoryController,
                      labelText: 'Category',
                      warning: 'Required',
                      prefixIcon: Icon(Icons.category_outlined, color: AppStyles.secondaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomInputField(
                      controller: _modelNumberController,
                      labelText: 'Model No.',
                      warning: 'Required',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomInputField(
                controller: _descController,
                labelText: 'Item Description & Condition',
                warning: 'Please provide a description',
                maxlines: 3,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                controller: _purchaseYearController,
                labelText: 'Purchase Year (e.g., 2022)',
                warning: 'Required',
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.calendar_today, color: AppStyles.secondaryColor),
              ),
              const SizedBox(height: 16),

              // Pricing Row
              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      controller: _rentPerHourController,
                      labelText: 'Rent / Hour',
                      warning: 'Required',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.currency_rupee, size: 18, color: AppStyles.secondaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomInputField(
                      controller: _rentPerDayController,
                      labelText: 'Rent / Day',
                      warning: 'Required',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.currency_rupee, size: 18, color: AppStyles.secondaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomInputField(
                controller: _securityDepositController,
                labelText: 'Security Deposit (Refundable)',
                warning: 'Required. Enter 0 if none.',
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.shield_outlined, color: AppStyles.secondaryColor),
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
                      style: TextStyle(fontSize: 12)
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

              // 📌 NEW: Conditionally show Delivery Charge field
              if (_offerDelivery) ...[
                const SizedBox(height: 16),
                CustomInputField(
                  controller: _deliveryChargeController,
                  labelText: 'Add Delivery Charge',
                  warning: 'Required',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(Icons.currency_rupee, size: 18, color: AppStyles.secondaryColor),
                ),
              ],
              const Divider(height: 40, thickness: 1),

              // SECTION 2: Ownership Details------------------------------------
              _buildSectionHeader('> Ownership Details'),

              CustomInputField(
                controller: _ownerNameController,
                labelText: 'Owner Name',
                warning: 'Please enter owner name',
                prefixIcon: Icon(Icons.person_outline, color: AppStyles.secondaryColor),
              ),
              const SizedBox(height: 16),

              CustomInputField(
                controller: _contactNoController,
                labelText: 'Contact No.',
                warning: 'Please enter your contact number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(Icons.phone, color: AppStyles.secondaryColor),
              ),
              const SizedBox(height: 16),

              CustomInputField(
                controller: _serialNumberController,
                labelText: 'Serial No./ VIN / IMEI',
                warning: 'Please provide serial number or proof',
                maxlines: 1,
              ),

              const SizedBox(height: 15),
              // Upload Ownership proof
              const Text('> Ownership Proof (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectImage,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _invoiceBillImg != null ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _invoiceBillImg != null ? Colors.green.shade300 : AppStyles.primaryColor_light,
                      width: _invoiceBillImg != null ? 1 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _invoiceBillImg != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_outlined,
                        color: _invoiceBillImg != null ? AppStyles.secondaryColor : AppStyles.secondaryColor,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _invoiceBillImg != null ? 'Invoice Attached' : 'Upload Invoice / Bill Photo',
                              style: TextStyle(
                                color: _invoiceBillImg != null ? AppStyles.secondaryColor : Colors.grey[800],
                                // fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (_invoiceBillImg != null)
                              Text(
                                _invoiceBillImg!.path.split('/').last,
                                style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (_invoiceBillImg != null)
                        GestureDetector(
                          onTap: () => setState(() => _invoiceBillImg = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child:  Icon(
                                Icons.close,
                                color: AppStyles.secondaryColor,
                                size: 25
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 40, thickness: 1),

              // SECTION 3: Location Details--------------------------------

              _buildSectionHeader('> Location Details'),

              CustomInputField(
                controller: _houseAreaController,
                labelText: 'House / Area',
                warning: 'Please enter house/area',
              ),
              const SizedBox(height: 16),

              CustomInputField(
                controller: _roadLandmarkController,
                labelText: 'Road / Landmark',
                warning: 'Please enter road/landmark',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      controller: _cityController,
                      labelText: 'City',
                      warning: 'Required',
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
                warning: 'Please enter pincode',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppStyles.secondaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {},
                  icon: Icon(Icons.my_location, color: AppStyles.primaryColor),
                  label: Text('Detect Location', style: TextStyle(color: AppStyles.primaryColor, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),

              // 📌 Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: AppStyles.primaryButtonStyle.copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.disabled)) {
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                  )
                      : const Text(
                    'Add Rental Item',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40), // Extra padding at bottom for scroll clearance
            ],
          ),
        ),
      ),
    );
  }
}