import 'package:flutter/material.dart';
import '../services/rating_service.dart';

class RateDriverScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String? rideId;

  const RateDriverScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    this.rideId,
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _reviewController = TextEditingController();

  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _ratingService.rateDriver(
        driverId: widget.driverId,
        driverName: widget.driverName,
        rating: _rating,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        rideId: widget.rideId,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
          'Rate Driver',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2196F3),
                child: Text(
                  widget.driverName.isNotEmpty
                      ? widget.driverName[0].toUpperCase()
                      : 'D',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.driverName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              Container(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = starValue;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              _rating >= starValue
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 44,
                              color: _rating >= starValue
                                  ? Colors.amber[600]
                                  : Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    if (_rating > 0)
                      Text(
                        _getRatingText(_rating),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _getRatingColor(_rating),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
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
                child: TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Share your experience (optional)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Below Average';
    return 'Poor';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    if (rating >= 1.5) return Colors.deepOrange;
    return Colors.red;
  }
}