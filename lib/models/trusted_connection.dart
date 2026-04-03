import 'package:equatable/equatable.dart';

class TrustedConnection extends Equatable {
  const TrustedConnection({
    required this.ownerId,
    required this.connectionUserId,
    required this.displayName,
    required this.relationshipLabel,
  });

  final String ownerId;
  final String connectionUserId;
  final String displayName;
  final String relationshipLabel;

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'connectionUserId': connectionUserId,
      'displayName': displayName,
      'relationshipLabel': relationshipLabel,
    };
  }

  factory TrustedConnection.fromMap(Map<String, dynamic> map) {
    return TrustedConnection(
      ownerId: map['ownerId']?.toString() ?? '',
      connectionUserId: map['connectionUserId']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      relationshipLabel: map['relationshipLabel']?.toString() ?? 'Contact',
    );
  }

  @override
  List<Object?> get props => [
    ownerId,
    connectionUserId,
    displayName,
    relationshipLabel,
  ];
}
