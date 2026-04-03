import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_controller.dart';
import '../../repositories/review_repository.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/review_card.dart';

class DoctorReviewsScreen extends StatelessWidget {
  const DoctorReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: StreamBuilder(
            stream: context.read<ReviewRepository>().streamDoctorReviews(
              user.uid,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: EmptyStateCard(
                    title: 'No reviews',
                    subtitle: 'After visits',
                    icon: Icons.reviews_outlined,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemBuilder: (context, index) =>
                    ReviewCard(review: reviews[index]),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: reviews.length,
              );
            },
          ),
        ),
      ),
    );
  }
}
