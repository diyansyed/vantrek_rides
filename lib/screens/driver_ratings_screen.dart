import 'package:flutter/material.dart';
import '../services/rating_service.dart';
import '../models/rating_model.dart';

class DriverRatingsScreen extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverRatingsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverRatingsScreen> createState() => _DriverRatingsScreenState();
}

class _DriverRatingsScreenState extends State<DriverRatingsScreen> {
  final RatingService _ratingService = RatingService();
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _ratingService.getDriverRatingStats(widget.driverId);
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
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
          'Driver Ratings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_stats != null)
            _buildStatsHeader(_stats!),

          Expanded(
            child: StreamBuilder<List<Rating>>(
              stream: _ratingService.getDriverRatings(widget.driverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final ratings = snapshot.data ?? [];

                if (ratings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ratings yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    return _buildRatingCard(ratings[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> stats) {
    final averageRating = stats['averageRating'] as double;
    final totalRatings = stats['totalRatings'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              // Average Rating
              Expanded(
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating.floor()
                              ? Icons.star
                              : (index < averageRating
                              ? Icons.star_half
                              : Icons.star_border),
                          color: Colors.amber[600],
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Distribution
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, stats['fiveStars'] as int, totalRatings),
                    _buildRatingBar(4, stats['fourStars'] as int, totalRatings),
                    _buildRatingBar(3, stats['threeStars'] as int, totalRatings),
                    _buildRatingBar(2, stats['twoStars'] as int, totalRatings),
                    _buildRatingBar(1, stats['oneStar'] as int, totalRatings),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, size: 12, color: Colors.amber[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    rating.userName.isNotEmpty
                        ? rating.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber[600],
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(rating.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rating.review != null && rating.review!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rating.review!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}