import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/appointment.dart';
import '../../models/review.dart';
import '../../providers/auth_controller.dart';
import '../../repositories/review_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';

class LeaveReviewScreen extends StatefulWidget {
  const LeaveReviewScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  String? _successMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _successMessage != null
                ? SectionCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundAlt,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _successMessage!,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_successMessage),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  )
                : SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rating',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.appointment.doctorName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          children: List.generate(
                            5,
                            (index) => ChoiceChip(
                              label: Text('${index + 1}'),
                              selected: _rating == index + 1,
                              onSelected: (_) {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _commentController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Comment',
                            hintText: 'Optional',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Helps others',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReview,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    final reviewRepository = context.read<ReviewRepository>();
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final existingReview = await reviewRepository.fetchPatientReview(
        doctorId: widget.appointment.doctorId,
        patientId: user.uid,
      );
      final review = Review(
        reviewId: existingReview?.reviewId ?? const Uuid().v4(),
        doctorId: widget.appointment.doctorId,
        patientId: user.uid,
        patientName: user.fullName,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await reviewRepository.addReview(review);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _successMessage = 'Review submitted';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted && _successMessage == null) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
