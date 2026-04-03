import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/subscription_plan.dart';
import '../../providers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/section_card.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final currentPlan = auth.subscriptionPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: AppGradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF0F6FFF),
                        Color(0xFF57B4FF),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a plan',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For family and AI',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          auth.currentPlanLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...SubscriptionPlan.values.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlanCard(
                      plan: plan,
                      isCurrent: currentPlan == plan,
                      isBusy: auth.isBusy,
                      onSelect: () => _selectPlan(context, plan),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPlan(BuildContext context, SubscriptionPlan plan) async {
    final auth = context.read<AuthController>();

    if (auth.isBusy) {
      return;
    }

    if (auth.subscriptionPlan == plan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.label} is already active')),
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change plan'),
          content: Text('Switch to ${plan.label}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (approved != true) {
      return;
    }

    try {
      await auth.updateSubscriptionPlan(plan);

      if (!context.mounted) return;

      final updatedPlan = context.read<AuthController>().subscriptionPlan;
      if (updatedPlan == plan) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plan.label} activated')),
        );
        Navigator.of(context).pop(plan);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan did not update. Please try again.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan update failed: $e')),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isBusy,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isBusy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isRecommended = plan == SubscriptionPlan.plus;
    final accent = switch (plan) {
      SubscriptionPlan.basic => AppColors.textSecondary,
      SubscriptionPlan.plus => AppColors.primary,
      SubscriptionPlan.pro => AppColors.success,
    };

    return SectionCard(
      backgroundColor: isCurrent || isRecommended
          ? AppColors.backgroundAlt
          : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.workspace_premium_outlined, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(plan),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.priceLabel,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LimitPill(
                label: _limitLabel('Photo', plan.photoAnalysisLimit),
                accent: accent,
              ),
              _LimitPill(
                label: _limitLabel('AI', plan.aiAnalysisLimit),
                accent: accent,
              ),
              _LimitPill(
                label: _limitLabel('Family', plan.familyMemberLimit),
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: plan.featureHighlights
                .map(
                  (feature) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      feature,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isCurrent || isRecommended
                ? FilledButton(
                    onPressed: isCurrent || isBusy ? null : onSelect,
                    child: Text(isCurrent ? 'Active' : 'Choose'),
                  )
                : FilledButton.tonal(
                    onPressed: isCurrent || isBusy ? null : onSelect,
                    child: Text(isCurrent ? 'Active' : 'Choose'),
                  ),
          ),
        ],
      ),
    );
  }

  String _subtitle(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.basic => 'Starter',
      SubscriptionPlan.plus => 'Best value',
      SubscriptionPlan.pro => 'Advanced',
    };
  }

  String _limitLabel(String title, int? limit) {
    if (title == 'Family') {
      return limit == null ? 'Family: unlimited' : 'Family: up to $limit';
    }
    return limit == null ? '$title: unlimited' : '$title: $limit / day';
  }
}

class _LimitPill extends StatelessWidget {
  const _LimitPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
      ),
    );
  }
}