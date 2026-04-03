import 'package:equatable/equatable.dart';

class DoctorTrustInsight extends Equatable {
  const DoctorTrustInsight({
    required this.doctorId,
    required this.connectedPatientsCount,
    required this.connectedPatientNames,
  });

  final String doctorId;
  final int connectedPatientsCount;
  final List<String> connectedPatientNames;

  bool get hasTrustedVisits => connectedPatientsCount > 0;

  String get badgeLabel {
    if (connectedPatientsCount <= 0) {
      return 'No circle';
    }
    return connectedPatientsCount == 1
        ? '1 contact'
        : '$connectedPatientsCount contacts';
  }

  String get detailLabel {
    if (connectedPatientsCount <= 0) {
      return 'No circle yet';
    }
    return connectedPatientNames.join(', ');
  }

  factory DoctorTrustInsight.empty(String doctorId) {
    return DoctorTrustInsight(
      doctorId: doctorId,
      connectedPatientsCount: 0,
      connectedPatientNames: const <String>[],
    );
  }

  @override
  List<Object?> get props => [
    doctorId,
    connectedPatientsCount,
    connectedPatientNames,
  ];
}
