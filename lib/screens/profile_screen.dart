import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../providers/driver_providers.dart';
import 'signin_screen.dart';
import 'driver_dashboard_screen.dart';
import 'become_driver_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && mounted) {
          setState(() {
            _userData = userDoc.data();
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _showEditProfileDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: _userData?['name'] ?? '');
    final phoneController = TextEditingController(text: _userData?['phoneNumber'] ?? '');
    final cnicController = TextEditingController(text: _userData?['cnic'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
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
      await _updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        cnic: cnicController.text.trim(),
      );
    }
  }

  Future<void> _updateProfile({
    required String name,
    required String phone,
    required String cnic,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('═══════════════════════════════════════');
      print('UPDATING USER PROFILE');
      print('User ID: ${user.uid}');
      print('Name: $name');
      print('Phone: $phone');
      print('CNIC: $cnic');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': name,
        'phoneNumber': phone,
        'cnic': cnic,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Profile updated successfully');
      print('═══════════════════════════════════════');

      await _loadUserData();

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      print('═══════════════════════════════════════');

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDriver = ref.watch(isDriverProvider);
    final driverProfile = ref.watch(driverProfileProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAccountSection(user),
                const SizedBox(height: 16),
                _buildSettingsSection(),
                const SizedBox(height: 16),
                _buildDangerZone(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(User user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF2196F3),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                    (_userData?['name']?.isNotEmpty == true
                        ? _userData!['name'][0]
                        : (user.displayName?.isNotEmpty == true
                        ? user.displayName![0]
                        : 'U'))
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _userData?['name']?.isNotEmpty == true
                      ? _userData!['name']
                      : (user.displayName ?? 'User'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                // NEW: Edit Button
                IconButton(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
          ),
          _buildInfoTile(
            icon: Icons.person,
            title: 'Name',
            value: _userData?['name'] ?? user.displayName ?? 'Not set',
          ),
          _buildInfoTile(
            icon: Icons.email,
            title: 'Email',
            value: user.email ?? 'Not set',
          ),
          _buildInfoTile(
            icon: Icons.phone,
            title: 'Phone',
            value: _userData?['phoneNumber'] ?? 'Not set',
          ),
          _buildInfoTile(
            icon: Icons.badge,
            title: 'CNIC',
            value: _userData?['cnic'] ?? 'Not set',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Settings & More',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          if (!ref.watch(isDriverProvider))
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_taxi, color: Colors.orange),
              ),
              title: const Text('Become a Driver'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BecomeDriverScreen(),
                  ),
                );
              },
            ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: Color(0xFF2196F3)),
            ),
            title: const Text('Ride History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help, color: Colors.purple),
            ),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.policy, color: Colors.green),
            ),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
        onTap: _handleLogout,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF2196F3)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
              (route) => false,
        );
      }
    }
  }
}