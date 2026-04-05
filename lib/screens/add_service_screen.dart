import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 📌 Added Firestore
import 'package:provider/provider.dart';
import 'package:sevashare_v4/styles/appstyles.dart';

import '../custom_widgets/custom_inputfield.dart';
import '../custom_widgets/detect_location_field.dart';
import '../providers/service_provider.dart';
import '../services/backend_services.dart';
import '../services/location_service.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final StoreAllServiceInfo _firestoreService = StoreAllServiceInfo();

  bool _isLoading = false;

  // --- Personal Details Controllers ---
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _houseAreaController = TextEditingController();
  final TextEditingController _roadLandmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // --- Service Details Controllers ---
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _serviceDescController = TextEditingController();
  final TextEditingController _serviceCategoryController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = [
    'Others',
    'Plumbing',
    'Electrical',
    'AC Repair & Service',
    'Carpentry',
    'Home Cleaning',
    'Appliance Repair',
    'Painting & Wall Work',
    'Pest Control',
    'RO / Water Purifier Service',
    'Gardening & Landscaping',
    'CCTV & Security Installation',
    'Moving & Packing (Packers & Movers)',
  ];

  File? _profileImage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNoController.dispose();
    _houseAreaController.dispose();
    _roadLandmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _professionController.dispose();
    _serviceCategoryController.dispose();
    _serviceDescController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  // 📌 Reusable SnackBar function for alerts
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFA61617) : Colors.green,
      ),
    );
  }

  // Helper function to clear all text fields
  void _clearForm() {
    _fullNameController.clear();
    _contactNoController.clear();
    _houseAreaController.clear();
    _roadLandmarkController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _professionController.clear();
    _serviceCategoryController.clear();
    _serviceDescController.clear();
    _experienceController.clear();
    _hourlyRateController.clear();
    setState(() {
      _profileImage = null;
      _selectedCategory = null;
    });
  }

  Future<void> _pickProfileImage() async {
    final File? pickedImage = await ImagePickerService.pickSingleImage();
    if (pickedImage != null) {
      setState(() {
        _profileImage = pickedImage;
      });
    }
  }

  // 📌 Form Submission & Validation Logic
  Future<void> _submitForm() async {
    // 1. Checks if any fields are empty using your CustomInputField validator
    if (_formKey.currentState!.validate()) {

      // 2. Extra validations for specific fields
      if (_contactNoController.text.trim().length != 10) {
        _showSnackBar('Please enter a valid 10-digit contact number.', isError: true);
        return;
      }
      if (_pincodeController.text.trim().length != 6) {
        _showSnackBar('Please enter a valid 6-digit pincode.', isError: true);
        return;
      }

      setState(() => _isLoading = true);

      // 📌 Latitude & Longitude Detection
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

      print('service provider latitude: ${coordinates['latitude']}');
      print('service provider longitude: ${coordinates['longitude']}');

      // 📌 NEW 1: Get the current logged-in user
      final User? currentUser = FirebaseAuth.instance.currentUser;

      // Safety check: Make sure a user is actually logged in
      if (currentUser == null) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: You must be logged in to add a service.', isError: true);
        return;
      }

      try {
        String? profileImageUrl;
        if (_profileImage != null) {
          _showSnackBar('Uploading profile image...');
          profileImageUrl = await ImgBBService.uploadImage(_profileImage!);
        }

        final servicesProvider = Provider.of<ServiceProvider>(context, listen: false);
        final String serviceId = servicesProvider.generateServiceId(currentUser.uid);

        final String finalCategory = _selectedCategory == 'Other'
            ? _serviceCategoryController.text.trim()
            : _selectedCategory ?? '';

        // 3. Map all values into a dictionary
        final Map<String, dynamic> serviceData = {
          'currentUser_uid': currentUser.uid, // ✨ Added the UID here!
          'service_id': serviceId, // ✨ Added the UID here!
          'profile_image_url': profileImageUrl,
          'full_name': _fullNameController.text.trim(),
          'contact_no': _contactNoController.text.trim(),
          'address': {
            'house_area': _houseAreaController.text.trim(),
            'road_landmark': _roadLandmarkController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'pincode': _pincodeController.text.trim(),
            'latitude': coordinates['latitude'],
            'longitude': coordinates['longitude'],
          },
          'profession': _professionController.text.trim(),
          'service_category': finalCategory,
          'service_description': _serviceDescController.text.trim(),
          // Convert numbers safely, default to 0 if parsing fails
          'experience_years': int.tryParse(_experienceController.text.trim()) ?? 0,
          'hourly_rate': double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
          'created_at': FieldValue.serverTimestamp(), // Save exact time of creation
        };

        // 4. Send to Firestore
        final bool success = await _firestoreService.saveServiceDetails(serviceData, serviceId);

        setState(() => _isLoading = false);


        // 6. Handle the result
        if (success) {
          _showSnackBar('Service added successfully!');
          _clearForm();
          // Optional: clear the form or pop the screen
          // Navigator.pop(context);
        } else {
          _showSnackBar('Failed to save service. Please try again.', isError: true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('An error occurred: $e', isError: true);
      }

    } else {
      _showSnackBar('Please fill in all required fields.', isError: true);
    }
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



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
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
          "Add Service",
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION A: Personal Details
                    _buildSectionHeader('> Personal Details'),

                    // 📸 Profile Image Picker
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? Icon(Icons.add_a_photo, color: Colors.grey[600], size: 35)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_profileImage != null)
                            TextButton(
                              onPressed: () => setState(() => _profileImage = null),
                              child: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                            )
                          else
                            Text('Add Profile Photo', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    CustomInputField(
                      controller: _fullNameController,
                      labelText: 'Full Name',
                      warning: 'Please enter your full name',
                      prefixIcon: Icon(Icons.person, color: AppStyles.secondaryColor),
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

                    const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

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

                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     style: OutlinedButton.styleFrom(
                    //       side: BorderSide(color: AppStyles.secondaryColor),
                    //     ),
                    //     onPressed: () {},
                    //     icon: Icon(Icons.my_location, color: AppStyles.primaryColor),
                    //     label: Text('Detect Location', style: TextStyle(color: AppStyles.primaryColor)),
                    //   ),
                    // ),
                    DetectLocationField(onLocationDetected: _onLocationDetected),
                    const Divider(thickness: 1),

                    // SECTION B: Service Details
                    _buildSectionHeader('> Service Details'),

                    CustomInputField(
                      controller: _professionController,
                      labelText: 'Profession',
                      warning: 'Please enter your profession',
                      prefixIcon: Icon(Icons.work_outline, color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      alignment: AlignmentDirectional.bottomStart,
                      menuMaxHeight: 300,
                      borderRadius: BorderRadius.circular(12),
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Service Category',
                        prefixIcon: Icon(Icons.category_outlined, color: AppStyles.secondaryColor),
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppStyles.secondaryColor, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),

                    // Show custom input if "Other" is selected
                    if (_selectedCategory == 'Other') ...[
                      CustomInputField(
                        controller: _serviceCategoryController,
                        labelText: 'Specify Category',
                        warning: 'Please specify your category',
                        prefixIcon: Icon(Icons.edit_note, color: AppStyles.secondaryColor),
                      ),
                      const SizedBox(height: 16),
                    ],

                    CustomInputField(
                      controller: _serviceDescController,
                      labelText: 'Service Description',
                      warning: 'Please provide a description',
                      maxlines: 3,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            controller: _experienceController,
                            labelText: 'Exp. (Years)',
                            warning: 'Required',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomInputField(
                            controller: _hourlyRateController,
                            labelText: 'Hourly Rate',
                            warning: 'Required',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(Icons.currency_rupee, size: 18, color: AppStyles.secondaryColor),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40, thickness: 1),

                    // SECTION C: KYC Identity Verification
                    _buildSectionHeader('> KYC Identity Verification'),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'KYC Details section coming soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          'Add Service',
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
