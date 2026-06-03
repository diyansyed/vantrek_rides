import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';
import 'rate_driver_screen.dart';

class SelectDriverToRateScreen extends StatefulWidget {
  const SelectDriverToRateScreen({super.key});

  @override
  State<SelectDriverToRateScreen> createState() => _SelectDriverToRateScreenState();
}

class _SelectDriverToRateScreenState extends State<SelectDriverToRateScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<DriverSubscription> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final drivers = await _subscriptionService.getUserSubscriptions();
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading drivers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: const Text(
          'Select Driver to Rate',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to drivers to rate them',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return _buildDriverCard(driver);
        },
      ),
    );
  }

  Widget _buildDriverCard(DriverSubscription driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateDriverScreen(
                driverId: driver.driverId,
                driverName: driver.driverName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [

              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF2196F3),
                child: Text(
                  driver.driverName.isNotEmpty
                      ? driver.driverName[0].toUpperCase()
                      : 'D',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: driver.isActive
                                ? Colors.green[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: driver.isActive
                                  ? Colors.green[200]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            driver.isActive ? 'Active' : 'Expired',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: driver.isActive
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${driver.daysRemaining} days left',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),


              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.amber[700],
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}