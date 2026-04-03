import 'dart:async';

import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/doctor_profile.dart';
import '../models/family_member.dart';
import '../models/review.dart';
import '../models/symptom_log.dart';
import '../models/trusted_connection.dart';

class PreviewDataStore {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  final Map<String, String> localPasswords = <String, String>{};
  final Map<String, AppUser> users = <String, AppUser>{};
  final Map<String, DoctorProfile> doctors = <String, DoctorProfile>{};
  final Map<String, FamilyMember> familyMembers = <String, FamilyMember>{};
  final Map<String, Appointment> appointments = <String, Appointment>{};
  final Map<String, Review> reviews = <String, Review>{};
  final Map<String, SymptomLog> symptomLogs = <String, SymptomLog>{};
  final Map<String, List<TrustedConnection>> trustedConnections =
      <String, List<TrustedConnection>>{};

  Stream<T> watch<T>(T Function() builder) async* {
    yield builder();
    yield* _changes.stream.map((_) => builder());
  }

  void notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
