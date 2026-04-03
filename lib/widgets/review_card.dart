import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/review.dart';
import 'rating_stars.dart';
import 'section_card.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.action});

  final Review review;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.patientName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                AppFormatters.dateOnly.format(review.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          RatingStars(rating: review.rating.toDouble(), size: 18),
          const SizedBox(height: 12),
          Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
