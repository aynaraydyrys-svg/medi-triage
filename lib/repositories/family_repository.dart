import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_member.dart';
import '../services/preview_data_store.dart';

class FamilyRepository {
  FamilyRepository({
    FirebaseFirestore? firestore,
    PreviewDataStore? previewStore,
  }) : _members = firestore?.collection('family_members'),
       _previewStore = previewStore;

  final CollectionReference<Map<String, dynamic>>? _members;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Stream<List<FamilyMember>> streamFamilyMembers(String ownerId) {
    if (isPreviewMode) {
      return _previewStore!.watch(() => _buildPreviewMembers(ownerId));
    }

    return _members!
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FamilyMember.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<List<FamilyMember>> fetchFamilyMembers(String ownerId) async {
    if (isPreviewMode) {
      return _buildPreviewMembers(ownerId);
    }

    final snapshot = await _members!.where('ownerId', isEqualTo: ownerId).get();
    final members =
        snapshot.docs.map((doc) => FamilyMember.fromMap(doc.data())).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return members;
  }

  Future<FamilyMember?> fetchFamilyMember(String memberId) async {
    if (isPreviewMode) {
      return _previewStore!.familyMembers[memberId];
    }

    final snapshot = await _members!.doc(memberId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return FamilyMember.fromMap(snapshot.data()!);
  }

  Future<void> upsertFamilyMember(FamilyMember member) {
    if (isPreviewMode) {
      _previewStore!.familyMembers[member.memberId] = member;
      _previewStore.notify();
      return Future.value();
    }

    return _members!
        .doc(member.memberId)
        .set(member.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteFamilyMember(String memberId) {
    if (isPreviewMode) {
      _previewStore!.familyMembers.remove(memberId);
      _previewStore.notify();
      return Future.value();
    }

    return _members!.doc(memberId).delete();
  }

  Future<void> appendVisitHistory({
    required String memberId,
    required String entry,
  }) async {
    if (isPreviewMode) {
      final member = _previewStore!.familyMembers[memberId];
      if (member == null) {
        return;
      }
      _previewStore.familyMembers[memberId] = member.copyWith(
        visitHistory: <String>[entry, ...member.visitHistory].take(8).toList(),
        updatedAt: DateTime.now(),
      );
      _previewStore.notify();
      return;
    }

    final member = await fetchFamilyMember(memberId);
    if (member == null) {
      return;
    }

    final updatedHistory = <String>[
      entry,
      ...member.visitHistory,
    ].take(8).toList();
    await _members!.doc(memberId).set({
      'visitHistory': updatedHistory,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  List<FamilyMember> _buildPreviewMembers(String ownerId) {
    final members =
        _previewStore!.familyMembers.values
            .where((member) => member.ownerId == ownerId)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return members;
  }
}
