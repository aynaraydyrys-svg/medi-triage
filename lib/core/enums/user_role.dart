enum UserRole { patient, doctor }

extension UserRoleX on UserRole {
  String get value => name;

  String get label => switch (this) {
    UserRole.patient => 'Patient',
    UserRole.doctor => 'Doctor',
  };

  String get subtitle => switch (this) {
    UserRole.patient => 'Symptoms and booking',
    UserRole.doctor => 'Profile and visits',
  };

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.patient,
    );
  }
}
