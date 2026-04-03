import 'package:equatable/equatable.dart';

enum FamilyDigestTone { calm, action, alert }

class FamilyDigestItem extends Equatable {
  const FamilyDigestItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.memberId,
  });

  final String id;
  final String title;
  final String subtitle;
  final FamilyDigestTone tone;
  final String? memberId;

  @override
  List<Object?> get props => [id, title, subtitle, tone, memberId];
}
