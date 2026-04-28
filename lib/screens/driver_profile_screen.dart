import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final doc = await _firestore.collection('drivers').doc(currentUser.uid).get();
      if (doc.exists) {
        setState(() {
          _driverData = doc.data();
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NEW: Edit Personal Information Dialog
  Future<void> _editPersonalInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final nameController = TextEditingController(text: _driverData?['name'] ?? '');
    final phoneController = TextEditingController(text: _driverData?['phoneNumber'] ?? '');
    final cnicController = TextEditingController(text: _driverData?['cnic'] ?? '');
    final licenseController = TextEditingController(text: _driverData?['licenseNumber'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Personal Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cnicController,
                decoration: InputDecoration(
                  labelText: 'CNIC',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseController,
                decoration: InputDecoration(
                  labelText: 'License Number',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _updatePersonalInfo(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        cnic: cnicController.text.trim(),
        license: licenseController.text.trim(),
      );
    }
  }

  // NEW: Update Personal Info in Firestore
  Future<void> _updatePersonalInfo({
    required String name,
    required String phone,
    required String cnic,
    required String license,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('═══════════════════════════════════════');
      print('UPDATING DRIVER PERSONAL INFO');
      print('Driver ID: ${currentUser.uid}');
      print('Name: $name');
      print('Phone: $phone');
      print('CNIC: $cnic');
      print('License: $license');

      await _firestore.collection('drivers').doc(currentUser.uid).update({
        'name': name,
        'phoneNumber': phone,
        'cnic': cnic,
        'licenseNumber': license,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Personal info updated successfully');
      print('═══════════════════════════════════════');

      await _loadDriverProfile();

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating personal info: $e');
      print('═══════════════════════════════════════');

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Edit Vehicle Information Dialog
  Future<void> _editVehicleInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final vehicleTypeController = TextEditingController(text: _driverData?['vehicleType'] ?? '');
    final vehicleNumberController = TextEditingController(text: _driverData?['vehicleNumber'] ?? '');
    final vehicleModelController = TextEditingController(text: _driverData?['vehicleModel'] ?? '');
    final vehicleColorController = TextEditingController(text: _driverData?['vehicleColor'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Vehicle Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vehicleTypeController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type (e.g., Car, Motorcycle)',
                  prefixIcon: const Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleNumberController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Number',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleModelController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Model (e.g., Honda Civic 2020)',
                  prefixIcon: const Icon(Icons.car_rental),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleColorController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Color',
                  prefixIcon: const Icon(Icons.palette),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _updateVehicleInfo(
        type: vehicleTypeController.text.trim(),
        number: vehicleNumberController.text.trim(),
        model: vehicleModelController.text.trim(),
        color: vehicleColorController.text.trim(),
      );
    }
  }

  // NEW: Update Vehicle Info in Firestore
  Future<void> _updateVehicleInfo({
    required String type,
    required String number,
    required String model,
    required String color,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('═══════════════════════════════════════');
      print('UPDATING DRIVER VEHICLE INFO');
      print('Driver ID: ${currentUser.uid}');
      print('Type: $type');
      print('Number: $number');
      print('Model: $model');
      print('Color: $color');

      await _firestore.collection('drivers').doc(currentUser.uid).update({
        'vehicleType': type,
        'vehicleNumber': number,
        'vehicleModel': model,
        'vehicleColor': color,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Vehicle info updated successfully');
      print('═══════════════════════════════════════');

      await _loadDriverProfile();

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating vehicle info: $e');
      print('═══════════════════════════════════════');

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _driverData?['name'] ?? 'Driver';
    final email = _driverData?['email'] ?? _auth.currentUser?.email ?? '';
    final phoneNumber = _driverData?['phoneNumber'] ?? '';
    final cnic = _driverData?['cnic'] ?? '';
    final licenseNumber = _driverData?['licenseNumber'] ?? '';
    final vehicleType = _driverData?['vehicleType'] ?? 'Car';
    final vehicleNumber = _driverData?['vehicleNumber'] ?? 'N/A';
    final vehicleModel = _driverData?['vehicleModel'] ?? '';
    final vehicleColor = _driverData?['vehicleColor'] ?? '';
    final rating = (_driverData?['rating'] ?? 0.0).toDouble();
    final totalRides = _driverData?['totalRides'] ?? 0;
    final isOnline = _driverData?['isOnline'] ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2196F3),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2196F3),
                      Color(0xFF1976D2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'D',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${rating.toStringAsFixed(1)} ($totalRides rides)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Online Status Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.circle,
                          color: isOnline ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      trailing: Switch(
                        value: isOnline,
                        onChanged: (value) async {
                          try {
                            await _firestore
                                .collection('drivers')
                                .doc(_auth.currentUser!.uid)
                                .update({'isOnline': value});

                            setState(() {
                              _driverData?['isOnline'] = value;
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value ? 'You are now online' : 'You are now offline'),
                                  backgroundColor: value ? Colors.green : Colors.grey,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Personal Information Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Edit Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _editPersonalInfo,
                                icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                                tooltip: 'Edit Personal Info',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.person, 'Name', name),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.email, 'Email', email),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.phone, 'Phone', phoneNumber),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.badge, 'CNIC', cnic),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.credit_card, 'License Number', licenseNumber),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Vehicle Information Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Edit Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Vehicle Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _editVehicleInfo,
                                icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                                tooltip: 'Edit Vehicle Info',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.directions_car, 'Vehicle Type', vehicleType),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.confirmation_number, 'Vehicle Number', vehicleNumber),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.car_rental, 'Vehicle Model', vehicleModel),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.palette, 'Vehicle Color', vehicleColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Statistics Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  Icons.star,
                                  rating.toStringAsFixed(1),
                                  'Rating',
                                  Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  Icons.local_taxi,
                                  totalRides.toString(),
                                  'Total Rides',
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'Not set' : value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}