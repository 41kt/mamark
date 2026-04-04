import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rating_controller.dart';

/// A self-contained star rating widget.
/// Pass [productId] and it will load & submit ratings automatically.
class StarRatingWidget extends StatefulWidget {
  final String productId;

  const StarRatingWidget({super.key, required this.productId});

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late final RatingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = buildRatingController();
    _controller.loadRatings(widget.productId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (_controller.isLoading.value && _controller.averageRating.value == 0) {
        return const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'rate_product'.tr,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (_controller.averageRating.value > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _controller.averageRating.value.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Text('no_ratings'.tr, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => _controller.submitRating(widget.productId, starValue),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      starValue <= _controller.userRating.value
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
