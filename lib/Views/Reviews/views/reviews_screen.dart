import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Reviews/api/review_service.dart';
import 'package:retilda/Views/Reviews/widgets/review_card.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/review.dart';
import 'package:sizer/sizer.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? productName;

  const ReviewsScreen({
    super.key,
    required this.productId,
    this.productName,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final ReviewService _service = ReviewService();

  bool _loading = true;
  ReviewData? _reviewData;

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final response = await _service.getProductReviews(widget.productId);
      if (!mounted) return;
      if (response.success == true) {
        setState(() {
          _reviewData = response.data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to load reviews'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load reviews')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _showCreateReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateReviewSheet(
        onSubmit: (rating, comment) async {
          final result = await _service.createReview(
            productId: widget.productId,
            rating: rating,
            comment: comment,
          );
          if (!mounted) return;
          Navigator.pop(context);
          final snackBarText = result.success == true
              ? (result.message ?? 'Review created')
              : (result.message ?? 'Failed to create review');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackBarText)),
          );
          await _loadReviews();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              widget.productName ?? 'Reviews',
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: accent,
            onPressed: _showCreateReviewSheet,
            label: const Text('Add Review'),
            icon: const Icon(Icons.rate_review_outlined),
          ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: accent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    children: [
                      _ReviewHeader(
                        avgRating: _reviewData?.avgRating ?? 0,
                        count: _reviewData?.count ?? 0,
                      ),
                      const SizedBox(height: 12),
                      if ((_reviewData?.reviews ?? []).isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 120),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              CustomText(
                                'No reviews yet',
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w600,
                                color: deepBlue,
                              ),
                              const SizedBox(height: 6),
                              CustomText(
                                'Be the first to review this product.',
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        )
                      else
                        ...(_reviewData!.reviews!).map(
                          (review) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewCard(review: review),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final double avgRating;
  final int count;

  const _ReviewHeader({
    required this.avgRating,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                CustomText(
                  avgRating.toStringAsFixed(1),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: deepBlue,
                ),
                const SizedBox(height: 2),
                CustomText(
                  'Avg Rating',
                  fontSize: 10.5.sp,
                  color: Colors.grey[700],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    final filled = avgRating >= index + 1;
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 18,
                      color: filled ? accent : Colors.grey[400],
                    );
                  }),
                ),
                const SizedBox(height: 6),
                CustomText(
                  '$count reviews',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: deepBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateReviewSheet extends StatefulWidget {
  final Future<void> Function(int rating, String comment) onSubmit;

  const _CreateReviewSheet({required this.onSubmit});

  @override
  State<_CreateReviewSheet> createState() => _CreateReviewSheetState();
}

class _CreateReviewSheetState extends State<_CreateReviewSheet> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onSubmit(_rating, _commentController.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomText(
              'Rate this product',
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                final filled = _rating > index;
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? accent : Colors.grey[400],
                    size: 26,
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            CustomText(
              'Write a comment (optional)',
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your thoughts',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
