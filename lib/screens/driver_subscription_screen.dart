import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/driver_providers.dart';
import '../models/driver_profile_model.dart';

class DriverSubscriptionScreen extends ConsumerWidget {
  const DriverSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverProfile = ref.watch(driverProfileProvider);

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
          'Subscription',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Subscription Status
              _buildCurrentSubscriptionCard(driverProfile),
              const SizedBox(height: 24),

              // Subscription Benefits
              const Text(
                'Subscription Benefits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildBenefitsCard(),
              const SizedBox(height: 24),

              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildPricingPlan(
                context,
                title: 'Monthly Plan',
                price: 'PKR 1,500',
                period: '/month',
                features: [
                  'Unlimited ride requests',
                  'No commission fees',
                  '24/7 Support',
                  'Flexible schedule',
                ],
                isPopular: true,
              ),
              const SizedBox(height: 16),
              _buildPricingPlan(
                context,
                title: 'Quarterly Plan',
                price: 'PKR 4,000',
                period: '/3 months',
                savings: 'Save PKR 500',
                features: [
                  'All Monthly features',
                  'Priority support',
                  'Early access to new features',
                  'Best value',
                ],
                isPopular: false,
              ),
              const SizedBox(height: 24),

              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(DriverProfile? profile) {
    final isActive = profile?.isSubscriptionActive ?? false;
    final daysLeft = profile?.daysRemaining ?? 0;
    final endDate = profile?.subscriptionEndDate;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.blue[400]!, Colors.blue[600]!]
              : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.blue : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Plan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'EXPIRED',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Monthly Subscription',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isActive
                ? '$daysLeft days remaining'
                : 'Subscription expired',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (endDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Renews on ${endDate.day}/${endDate.month}/${endDate.year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    final benefits = [
      {'icon': Icons.all_inclusive, 'text': 'Unlimited ride requests'},
      {'icon': Icons.money_off, 'text': 'Zero commission on earnings'},
      {'icon': Icons.schedule, 'text': 'Flexible working hours'},
      {'icon': Icons.support_agent, 'text': '24/7 customer support'},
      {'icon': Icons.trending_up, 'text': 'Earnings analytics'},
      {'icon': Icons.verified, 'text': 'Verified driver badge'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: benefits
            .map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(
                benefit['icon'] as IconData,
                color: const Color(0xFF2196F3),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  benefit['text'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildPricingPlan(
      BuildContext context, {
        required String title,
        required String price,
        required String period,
        String? savings,
        required List<String> features,
        required bool isPopular,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: const Color(0xFF2196F3), width: 2)
            : null,
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
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            Text(
                              period,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (savings != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              savings,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showPaymentConfirmation(context, title, price);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          _buildPaymentHistoryItem(
            date: 'Jan 15, 2025',
            amount: 'PKR 1,500',
            status: 'Paid',
            isPaid: true,
          ),
          const Divider(height: 32),
          Center(
            child: Text(
              'No more payment history',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem({
    required String date,
    required String amount,
    required String status,
    required bool isPaid,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPaid ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentConfirmation(
      BuildContext context, String plan, String price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to subscribe to:'),
            const SizedBox(height: 12),
            Text(
              plan,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment will be processed after admin approval.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription request submitted!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}