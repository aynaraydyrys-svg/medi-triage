enum UrgencyLevel { canWait, bookToday, emergency }

extension UrgencyLevelX on UrgencyLevel {
  String get value => switch (this) {
    UrgencyLevel.canWait => 'can_wait',
    UrgencyLevel.bookToday => 'book_today',
    UrgencyLevel.emergency => 'emergency',
  };

  String get label => switch (this) {
    UrgencyLevel.canWait => 'Wait',
    UrgencyLevel.bookToday => 'Today',
    UrgencyLevel.emergency => 'Urgent',
  };

  String get shortLabel => switch (this) {
    UrgencyLevel.canWait => 'Wait',
    UrgencyLevel.bookToday => 'Today',
    UrgencyLevel.emergency => 'Urgent',
  };

  String get recommendedAction => switch (this) {
    UrgencyLevel.canWait => 'Monitor',
    UrgencyLevel.bookToday => 'Book now',
    UrgencyLevel.emergency => 'Get help',
  };

  bool get needsImmediateAttention => this == UrgencyLevel.emergency;

  static UrgencyLevel fromValue(String value) {
    return UrgencyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => UrgencyLevel.canWait,
    );
  }
}
