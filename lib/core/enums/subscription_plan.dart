enum SubscriptionPlan { basic, plus, pro }

extension SubscriptionPlanX on SubscriptionPlan {
  String get value => name;

  String get label => switch (this) {
    SubscriptionPlan.basic => 'Basic',
    SubscriptionPlan.plus => 'Plus',
    SubscriptionPlan.pro => 'Pro',
  };

  bool get isPremium => this != SubscriptionPlan.basic;

  String get priceLabel => switch (this) {
    SubscriptionPlan.basic => 'Free',
    SubscriptionPlan.plus => '2,990 ₸ / month',
    SubscriptionPlan.pro => '5,990 ₸ / month',
  };

  int? get photoAnalysisLimit => switch (this) {
    SubscriptionPlan.basic => 3,
    SubscriptionPlan.plus => 10,
    SubscriptionPlan.pro => null,
  };

  int? get aiAnalysisLimit => switch (this) {
    SubscriptionPlan.basic => 3,
    SubscriptionPlan.plus => 10,
    SubscriptionPlan.pro => null,
  };

  int? get familyMemberLimit => switch (this) {
    SubscriptionPlan.basic => 1,
    SubscriptionPlan.plus => 5,
    SubscriptionPlan.pro => null,
  };

  bool get hasAdvancedAiSummary => this == SubscriptionPlan.pro;

  bool get hasPriorityUrgentMatching => this == SubscriptionPlan.pro;

  SubscriptionPlan? get upgradeTarget => switch (this) {
    SubscriptionPlan.basic => SubscriptionPlan.plus,
    SubscriptionPlan.plus => SubscriptionPlan.pro,
    SubscriptionPlan.pro => null,
  };

  List<String> get featureHighlights => switch (this) {
    SubscriptionPlan.basic => const [
      '3 photo / day',
      '3 AI / day',
      '1 family member',
      'Basic AI',
    ],
    SubscriptionPlan.plus => const [
      '10 photo / day',
      '10 AI / day',
      'Up to 5 family',
      'Family digest',
    ],
    SubscriptionPlan.pro => const [
      'Near unlimited',
      'AI summary',
      'Priority',
      'Full family',
    ],
  };

  static SubscriptionPlan fromValue(String value) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.value == value,
      orElse: () => SubscriptionPlan.basic,
    );
  }
}
