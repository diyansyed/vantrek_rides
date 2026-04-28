import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/driver_profile_model.dart';
import '../providers/driver_providers.dart';
import 'driver_dashboard_screen.dart';

class BecomeDriverScreen extends ConsumerStatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  ConsumerState<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends ConsumerState<BecomeDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Become a Driver',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '03XX XXXXXXX',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 11) {
                      return 'Enter valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CNIC
                _buildTextField(
                  controller: _cnicController,
                  label: 'CNIC Number',
                  hint: 'XXXXX-XXXXXXX-X',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your CNIC';
                    }
                    if (value.length < 13) {
                      return 'Enter valid CNIC';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Vehicle Information Section
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Type Dropdown
                _buildVehicleTypeDropdown(),
                const SizedBox(height: 16),

                // Vehicle Number
                _buildTextField(
                  controller: _vehicleNumberController,
                  label: 'Vehicle Registration Number',
                  hint: 'ABC-1234',
                  icon: Icons.directions_car,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // License Number
                _buildTextField(
                  controller: _licenseNumberController,
                  label: 'Driving License Number',
                  hint: 'Your license number',
                  icon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter license number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 24),

                // Terms
                _buildTermsText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_taxi,
            size: 60,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Start Driving Today!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join our network and connect with students',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<VehicleType>(
        value: _selectedVehicleType,
        decoration: const InputDecoration(
          labelText: 'Vehicle Type',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.directions_car, color: Color(0xFF2196F3)),
        ),
        items: VehicleType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(_getVehicleTypeName(type)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedVehicleType = value!;
          });
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Register as Driver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By registering, you agree to our Terms of Service and Driver Agreement.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  String _getVehicleTypeName(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.van:
        return 'Van';
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.rickshaw:
        return 'Rickshaw';
      case VehicleType.suv:
        return 'SUV';
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('═══════════════════════════════════════');
      print('CREATING DRIVER PROFILE');
      print('User ID: ${user.uid}');
      print('Name: ${_nameController.text.trim()}');
      print('Phone: ${_phoneController.text.trim()}');

      // Create driver profile
      final driverProfile = DriverProfile(
        driverId: user.uid,
        vehicleType: _selectedVehicleType,
        vehicleModel: _getVehicleTypeName(_selectedVehicleType),
        vehicleNumber: _vehicleNumberController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        serviceInstitutionId: '', // Will be set when registering at institution
        serviceInstitutionName: '', // Will be set when registering at institution
        registeredAt: DateTime.now(),
        subscriptionStatus: SubscriptionStatus.active,
        subscriptionStartDate: DateTime.now(),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 30)),
      );

      // CRITICAL: Save to Firestore with name and phoneNumber GUARANTEED
      final driverData = {
        ...driverProfile.toMap(),
        'name': _nameController.text.trim(), // ← ALWAYS SAVED
        'phoneNumber': _phoneController.text.trim(), // ← ALWAYS SAVED
        'cnic': _cnicController.text.trim(),
        'rating': 0.0,
        'totalRides': 0,
        'isOnline': false,
        'subscriberCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .set(driverData);

      print('✅ Driver document created with name and phone');

      // Also update user document with driver info
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isDriver': true,
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'cnic': _cnicController.text.trim(),
      });

      print('✅ User document updated');
      print('═══════════════════════════════════════');

      // Update providers
      ref.read(driverProfileProvider.notifier).state = driverProfile;
      ref.read(isDriverProvider.notifier).state = true;
      ref.read(appModeProvider.notifier).state = AppMode.driver;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Aboard!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You are now registered as a driver!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverDashboardScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go to Dashboard',style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error creating driver: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}