import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';
import '../models/driver_profile_model.dart';
import 'signin_screen.dart';
import 'search_institution_with_places.dart';
import 'user_subscribed_drivers_screen.dart';
import 'chat_driver_screen.dart';
import 'chat_list_screen.dart';
import 'select_driver_to_rate_screen.dart';
import 'become_driver_screen.dart';
import 'driver_dashboard_screen.dart';
import 'profile_screen.dart';
import '../providers/driver_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _driverProfileSubscription;
  String _searchQuery = '';  // NEW: Track search query
  final TextEditingController _searchController = TextEditingController();  // NEW: Search controller

  @override
  void initState() {
    super.initState();
    // Wait for widget to build, then check driver status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDriverStatus();
    });
  }

  @override
  void dispose() {
    _driverProfileSubscription?.cancel();
    _searchController.dispose();  // NEW: Dispose controller
    super.dispose();
  }

  Future<void> _checkDriverStatus() async {
    // Get current Firebase user directly
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      // Set up real-time listener for driver document
      _driverProfileSubscription = FirebaseFirestore.instance
          .collection('drivers')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null && mounted) {
          final driverProfile = DriverProfile.fromMap(snapshot.data()!);
          ref.read(driverProfileProvider.notifier).state = driverProfile;
          ref.read(isDriverProvider.notifier).state = true;
        } else if (mounted) {
          ref.read(isDriverProvider.notifier).state = false;
          ref.read(driverProfileProvider.notifier).state = null;
        }
      });
    } catch (e) {
      print('Could not check driver status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Vantrek Logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 6,
                    top: 10,
                    child: Container(
                      width: 6,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue[300],
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 10,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'VANTREK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              _showDrawer(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 24),

            // Main Action Cards
            if (_shouldShow(['find', 'driver', 'search', 'school']))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMainCard(
                        title: 'Find a Driver',
                        subtitle: 'Search Schools',
                        icon: Icons.directions_car,
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SearchInstitutionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_shouldShow(['live', 'track', 'location', 'gps']))
                      Expanded(
                        child: _buildMainCard(
                          title: 'Live Tracking',
                          subtitle: 'Track Your Drivers',
                          icon: Icons.my_location,
                          color: Colors.white,
                          textColor: const Color(0xFF2196F3),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserSubscribedDriversScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            if (_shouldShow(['find', 'driver', 'search', 'school']) &&
                !_shouldShow(['live', 'track', 'location', 'gps']) &&
                _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildMainCard(
                  title: 'Find a Driver',
                  subtitle: 'Search Schools',
                  icon: Icons.directions_car,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchInstitutionScreen(),
                      ),
                    );
                  },
                ),
              ),

            if (!_shouldShow(['find', 'driver', 'search', 'school']) &&
                _shouldShow(['live', 'track', 'location', 'gps']) &&
                _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildMainCard(
                  title: 'Live Tracking',
                  subtitle: 'Track Your Drivers',
                  icon: Icons.my_location,
                  color: Colors.white,
                  textColor: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserSubscribedDriversScreen(),
                      ),
                    );
                  },
                ),
              ),

            if (_shouldShow(['find', 'driver', 'search', 'school']) ||
                _shouldShow(['live', 'track', 'location', 'gps']))
              const SizedBox(height: 20),

            // Secondary Action Cards
            if (_shouldShow(['message', 'chat', 'driver']) ||
                _shouldShow(['rate', 'feedback', 'review', 'star']))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      if (_shouldShow(['message', 'chat', 'driver']))
                        Expanded(
                          child: _buildSecondaryCard(
                            title: 'Messages',
                            subtitle: 'Chat with Drivers',
                            icon: Icons.chat_bubble,
                            color: const Color(0xFF2196F3),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ChatListScreen(isDriver: false),
                                ),
                              );
                            },
                          ),
                        ),
                      if (_shouldShow(['message', 'chat', 'driver']) &&
                          _shouldShow(['rate', 'feedback', 'review', 'star']))
                        const SizedBox(width: 16),
                      if (_shouldShow(['rate', 'feedback', 'review', 'star']))
                        Expanded(
                          child: _buildSecondaryCard(
                            title: 'Rate Driver',
                            subtitle: 'Give feedback',
                            icon: Icons.star_rate,
                            color: Colors.amber[700]!,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SelectDriverToRateScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Show "No results" message if search has no matches
            if (_searchQuery.isNotEmpty &&
                !_shouldShow(['find', 'driver', 'search', 'school']) &&
                !_shouldShow(['live', 'track', 'location', 'gps']) &&
                !_shouldShow(['message', 'chat']) &&
                !_shouldShow(['rate', 'feedback', 'review', 'star']))
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No results found for "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try searching for: Find Driver, Live Tracking, Messages, or Rate Driver',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSubscribedDriversScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.directions_car, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // NEW: Helper method to determine if a widget should be shown based on search
  bool _shouldShow(List<String> keywords) {
    if (_searchQuery.isEmpty) return true;
    return keywords.any((keyword) => keyword.contains(_searchQuery) || _searchQuery.contains(keyword));
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search features...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          if (_searchQuery.isEmpty)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Icon(Icons.location_on, size: 18, color: Colors.green[700]),
            ),
        ],
      ),
    );
  }

  Widget _buildMainCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final bool isWhite = color == Colors.white;
    final effectiveTextColor = textColor ?? (isWhite ? Colors.blue : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: isWhite
              ? Border.all(color: const Color(0xFF2196F3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isWhite
                  ? Colors.black.withOpacity(0.05)
                  : color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWhite
                    ? const Color(0xFF2196F3).withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: effectiveTextColor,
                size: 28,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: effectiveTextColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(Icons.person, 'Profile', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showDrawer(BuildContext context) async {
    final authState = ref.read(authControllerProvider);
    final user = authState.user;

    // Get current Firebase user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    // REAL-TIME CHECK: Check both collections every time drawer opens
    bool isApprovedDriver = false;
    bool hasPendingApplication = false;

    try {
      // Check if user is in drivers collection (approved)
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(firebaseUser.uid)
          .get();

      isApprovedDriver = driverDoc.exists;

      // If not approved, check for pending application
      if (!isApprovedDriver) {
        final applicationSnapshot = await FirebaseFirestore.instance
            .collection('driver_applications')
            .where('userId', isEqualTo: firebaseUser.uid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        hasPendingApplication = applicationSnapshot.docs.isNotEmpty;
      }

      // Update provider state to match reality
      if (isApprovedDriver && mounted) {
        ref.read(isDriverProvider.notifier).state = true;
        if (driverDoc.data() != null) {
          final driverProfile = DriverProfile.fromMap(driverDoc.data()!);
          ref.read(driverProfileProvider.notifier).state = driverProfile;
        }
      } else if (mounted) {
        ref.read(isDriverProvider.notifier).state = false;
        ref.read(driverProfileProvider.notifier).state = null;
      }

    } catch (e) {
      print('Error checking driver status: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, color: Colors.blue[600]),
              ),
              title: Text(user?.displayName ?? user?.email ?? 'User'),
              subtitle: Text(user?.userType.name.toUpperCase() ?? ''),
            ),
            const Divider(),

            // Driver Mode Toggle - with three states
            ListTile(
              leading: Icon(
                Icons.local_taxi,
                color: isApprovedDriver
                    ? Colors.green
                    : (hasPendingApplication ? Colors.orange : const Color(0xFF2196F3)),
              ),
              title: const Text('Driver Mode'),
              subtitle: Text(
                isApprovedDriver
                    ? 'Approved - Tap to view dashboard'
                    : (hasPendingApplication
                    ? 'Application pending approval'
                    : 'Not registered - Tap to apply'),
              ),
              trailing: Icon(
                isApprovedDriver
                    ? Icons.check_circle
                    : (hasPendingApplication ? Icons.pending : Icons.arrow_forward_ios),
                size: 20,
                color: isApprovedDriver
                    ? Colors.green
                    : (hasPendingApplication ? Colors.orange : null),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer

                if (isApprovedDriver) {
                  // Already approved - go to dashboard
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverDashboardScreen(),
                    ),
                  );
                } else if (hasPendingApplication) {
                  // Application pending - show pending screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BecomeDriverScreen(),
                    ),
                  );
                } else {
                  // Not registered - show registration form
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BecomeDriverScreen(),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ride History'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Ride History');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Help & Support');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}