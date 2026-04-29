import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  String _selectedVehicleType = 'Car';
  bool _isLoading = false;
  bool _hasSubmitted = false;

  final List<String> _vehicleTypes = ['Car', 'Van', 'Bike', 'Rickshaw', 'SUV'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkExistingApplication();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
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

  Future<void> _checkExistingApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final existingApp = await FirebaseFirestore.instance
          .collection('driver_applications')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingApp.docs.isNotEmpty && mounted) {
        setState(() => _hasSubmitted = true);
      }
    } catch (e) {
      print('Error checking application: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return _buildPendingScreen();
    }

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

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+92-XXX-XXXXXXX',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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

                _buildVehicleTypeDropdown(),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _vehicleModelController,
                  label: 'Vehicle Model',
                  hint: 'e.g., Toyota Corolla, Honda Civic',
                  icon: Icons.car_rental,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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

                _buildTextField(
                  controller: _vehicleColorController,
                  label: 'Vehicle Color',
                  hint: 'e.g., White, Black, Silver',
                  icon: Icons.palette,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle color';
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
          'Submit your application and our team will review it',
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
      child: DropdownButtonFormField<String>(
        value: _selectedVehicleType,
        decoration: const InputDecoration(
          labelText: 'Vehicle Type',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.directions_car, color: Color(0xFF2196F3)),
        ),
        items: _vehicleTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type),
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
          'Submit Application',
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
      'By submitting, you agree to our Terms of Service and Driver Agreement. Your application will be reviewed by our admin team.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Submit driver application
      final applicationData = {
        'userId': user.uid,
        'userName': _nameController.text.trim(),
        'email': user.email ?? '',
        'phone': _phoneController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'vehicleType': _selectedVehicleType,
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('driver_applications')
          .add(applicationData);

      setState(() {
        _isLoading = false;
        _hasSubmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPendingScreen() {
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
          'Application Status',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pending_actions,
                  size: 80,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Application Pending',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your driver application has been submitted and is currently under review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'What happens next?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Our admin team will review your application\n'
                          '• You will be notified once approved\n'
                          '• This usually takes 1-2 business days',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}