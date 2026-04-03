enum AppointmentStatus { pending, confirmed, completed, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get value => name;

  String get label => switch (this) {
    AppointmentStatus.pending => 'Pending',
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
  };

  static AppointmentStatus fromValue(String value) {
    if (value == 'booked') {
      return AppointmentStatus.confirmed;
    }
    return AppointmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AppointmentStatus.pending,
    );
  }
}
