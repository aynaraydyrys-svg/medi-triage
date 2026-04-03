enum DoctorAvailabilityStatus { accepting, limited, away }

extension DoctorAvailabilityStatusX on DoctorAvailabilityStatus {
  String get value => switch (this) {
    DoctorAvailabilityStatus.accepting => 'accepting',
    DoctorAvailabilityStatus.limited => 'limited',
    DoctorAvailabilityStatus.away => 'away',
  };

  String get label => switch (this) {
    DoctorAvailabilityStatus.accepting => 'Open',
    DoctorAvailabilityStatus.limited => 'Limited',
    DoctorAvailabilityStatus.away => 'Unavailable',
  };

  String get subtitle => switch (this) {
    DoctorAvailabilityStatus.accepting => 'Slots available',
    DoctorAvailabilityStatus.limited => 'Few left',
    DoctorAvailabilityStatus.away => 'No today',
  };

  static DoctorAvailabilityStatus fromValue(String value) {
    return DoctorAvailabilityStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DoctorAvailabilityStatus.accepting,
    );
  }
}
