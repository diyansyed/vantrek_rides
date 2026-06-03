import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/driver_providers.dart';
import '../models/driver_profile_model.dart';
import '../services/ride_request_service.dart';
import '../services/subscription_service.dart';
import '../services/driver_location_service.dart';
import 'driver_subscription_screen.dart';
import 'driver_institution_search_screen.dart';
import 'registered_institutions_screen.dart';
import 'driver_ride_requests_screen.dart';
import 'driver_subscribers_screen.dart';
import 'chat_list_screen.dart';
import 'driver_profile_screen.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState
    extends ConsumerState<DriverDashboardScreen> {
  final DriverLocationService _locationService = DriverLocationService();

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPendingRequestsCount();
    _loadSubscriberCount();
  }

  Future<void> _loadPendingRequestsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final rideRequestService = RideRequestService();
      final count = await rideRequestService.getDriverPendingRequestsCount(user.uid);
      ref.read(pendingRequestsCountProvider.notifier).state = count;
    } catch (e) {
      print('Error loading pending requests: $e');
    }
  }

  Future<void> _loadSubscriberCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final subscriptionService = SubscriptionService();
      final count = await subscriptionService.getDriverSubscriberCount(user.uid);
      ref.read(subscriberCountProvider.notifier).state = count;
    } catch (e) {
      print('Error loading subscriber count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProfile = ref.watch(driverProfileProvider);
    final isOnline = ref.watch(driverOnlineStatusProvider);
    final pendingRequestsCount = ref.watch(pendingRequestsCountProvider);
    final subscriberCount = ref.watch(subscriberCountProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_taxi, color: Colors.white, size: 24),
          ),
        ),
        title: const Text(
          'VANTREK',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => _showDriverMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (driverProfile != null && !driverProfile.isSubscriptionActive)
                _buildSubscriptionBanner(driverProfile),

              _buildStatusToggle(isOnline),

              const SizedBox(height: 16),

              if (isOnline) _buildOnlineMessage(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people_outline,
                      value: subscriberCount.toString(),
                      label: 'Subscribers',
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star_outline,
                      value: driverProfile?.rating.toStringAsFixed(1) ?? '0.0',
                      label: 'Rating',
                      color: Colors.amber[600]!,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildNewRideRequestsCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildYourInstitutionCard()),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildChatWithUserCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMySubscribersCard()),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSubscriptionBanner(DriverProfile profile) {
    final daysLeft = profile.daysRemaining;
    final isExpired = daysLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isExpired ? Colors.red[700] : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Subscription Expired' : 'Subscription Expiring Soon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red[900] : Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isExpired ? 'Renew to share location' : '$daysLeft days remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverSubscriptionScreen(),
                ),
              );
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Status: ',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? Colors.green[700] : Colors.grey[600],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              final profile = ref.read(driverProfileProvider);
              if (profile != null && !profile.isSubscriptionActive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please renew your subscription'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final currentStatus = isOnline;

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                if (currentStatus) {
                  await _locationService.stopSharingLocation();
                  ref.read(driverOnlineStatusProvider.notifier).state = false;
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You are now offline. Location sharing stopped.'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                } else {
                  // Going online - start sharing location
                  await _locationService.startSharingLocation();
                  ref.read(driverOnlineStatusProvider.notifier).state = true;
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You are now online! Subscribers can see your location.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green[400] : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re online and visible to requests',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You can toggle offline to stop receiving new ride requests.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewRideRequestsCard() {
    final pendingRequests = ref.watch(pendingRequestsCountProvider);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DriverRideRequestsScreen(),
          ),
        );
        _loadPendingRequestsCount();
      },
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Ride Requests',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (pendingRequests > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$pendingRequests',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourInstitutionCard() {
    final driverProfile = ref.watch(driverProfileProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisteredInstitutionsScreen(),
          ),
        );
      },
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2196F3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFF2196F3),
                size: 28,
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Institutions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Tap to view all',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatWithUserCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatListScreen(isDriver: true),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Chat with passengers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySubscribersCard() {
    final subscriberCount = ref.watch(subscriberCountProvider);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DriverSubscribersScreen(),
          ),
        );
        _loadSubscriberCount();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.people_outline,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Subscribers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subscriberCount == 0
                        ? 'No subscribers yet'
                        : '$subscriberCount ${subscriberCount == 1 ? 'subscriber' : 'subscribers'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverMenu(BuildContext context) {
    final driverProfile = ref.read(driverProfileProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
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
              leading: const Icon(Icons.person_outline, color: Color(0xFF2196F3)),
              title: const Text('Switch to User Mode'),
              onTap: () {
                Navigator.pop(context);
                ref.read(appModeProvider.notifier).state = AppMode.user;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions),
              title: const Text('Subscription'),
              subtitle: Text(
                driverProfile?.isSubscriptionActive ?? false
                    ? '${driverProfile?.daysRemaining} days left'
                    : 'Expired',
                style: TextStyle(
                  fontSize: 12,
                  color: driverProfile?.isSubscriptionActive ?? false
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverSubscriptionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_location),
              title: const Text('Update Vehicle Info'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.school_outlined,
                label: 'Institutions',
                isActive: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverInstitutionSearchScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                isActive: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(isDriver: true),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isActive: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF2196F3) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF2196F3) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}