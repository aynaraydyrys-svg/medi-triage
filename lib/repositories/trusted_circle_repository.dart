import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor_trust_insight.dart';
import '../models/trusted_connection.dart';
import '../services/preview_data_store.dart';

class TrustedCircleRepository {
  TrustedCircleRepository({
    FirebaseFirestore? firestore,
    PreviewDataStore? previewStore,
  }) : _firestore = firestore,
       _connections = firestore?.collection('trusted_connections'),
       _reviews = firestore?.collection('reviews'),
       _appointments = firestore?.collection('appointments'),
       _previewStore = previewStore;

  final FirebaseFirestore? _firestore;
  final CollectionReference<Map<String, dynamic>>? _connections;
  final CollectionReference<Map<String, dynamic>>? _reviews;
  final CollectionReference<Map<String, dynamic>>? _appointments;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Future<void> saveConnections(
    String ownerId,
    List<TrustedConnection> connections,
  ) async {
    if (isPreviewMode) {
      _previewStore!.trustedConnections[ownerId] = connections;
      _previewStore.notify();
      return;
    }

    final firestore = _firestore;
    final connectionCollection = _connections;
    if (firestore == null || connectionCollection == null) {
      return;
    }

    final batch = firestore.batch();
    for (final connection in connections) {
      final docId = '${connection.ownerId}_${connection.connectionUserId}';
      batch.set(connectionCollection.doc(docId), connection.toMap());
    }
    await batch.commit();
  }

  Future<List<TrustedConnection>> fetchConnections(String ownerId) async {
    final previewStore = _previewStore;
    if (previewStore != null) {
      return List<TrustedConnection>.from(
        previewStore.trustedConnections[ownerId] ??
            previewStore.trustedConnections[_previewFallbackOwner(ownerId)] ??
            const <TrustedConnection>[],
      );
    }

    final connectionCollection = _connections;
    if (connectionCollection == null) {
      return const <TrustedConnection>[];
    }

    final snapshot = await connectionCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs
        .map((doc) => TrustedConnection.fromMap(doc.data()))
        .toList();
  }

  Future<Map<String, DoctorTrustInsight>> fetchTrustInsights({
    required String patientId,
    required Iterable<String> doctorIds,
  }) async {
    final ids = doctorIds.toList();
    if (ids.isEmpty) {
      return const <String, DoctorTrustInsight>{};
    }

    final connections = await fetchConnections(patientId);
    if (connections.isEmpty) {
      return <String, DoctorTrustInsight>{
        for (final doctorId in ids)
          doctorId: DoctorTrustInsight.empty(doctorId),
      };
    }

    final namesByConnectionId = <String, String>{
      for (final connection in connections)
        connection.connectionUserId: connection.displayName,
    };

    final previewStore = _previewStore;
    if (previewStore != null) {
      final reviewHits = <String, Set<String>>{
        for (final doctorId in ids) doctorId: <String>{},
      };
      final appointmentHits = <String, Set<String>>{
        for (final doctorId in ids) doctorId: <String>{},
      };

      for (final review in previewStore.reviews.values) {
        if (reviewHits.containsKey(review.doctorId) &&
            namesByConnectionId.containsKey(review.patientId)) {
          reviewHits[review.doctorId]!.add(review.patientId);
        }
      }
      for (final appointment in previewStore.appointments.values) {
        if (appointmentHits.containsKey(appointment.doctorId) &&
            namesByConnectionId.containsKey(appointment.patientId)) {
          appointmentHits[appointment.doctorId]!.add(appointment.patientId);
        }
      }

      return <String, DoctorTrustInsight>{
        for (final doctorId in ids)
          doctorId: _buildInsight(
            doctorId: doctorId,
            connectedVisitorIds: <String>{
              ...reviewHits[doctorId] ?? const <String>{},
              ...appointmentHits[doctorId] ?? const <String>{},
            },
            namesByConnectionId: namesByConnectionId,
          ),
      };
    }

    return <String, DoctorTrustInsight>{
      for (final doctorId in ids)
        doctorId: await _fetchFirestoreInsight(
          doctorId: doctorId,
          namesByConnectionId: namesByConnectionId,
        ),
    };
  }

  Future<DoctorTrustInsight> _fetchFirestoreInsight({
    required String doctorId,
    required Map<String, String> namesByConnectionId,
  }) async {
    final reviewsCollection = _reviews;
    final appointmentsCollection = _appointments;
    if (reviewsCollection == null || appointmentsCollection == null) {
      return DoctorTrustInsight.empty(doctorId);
    }

    final reviewSnapshot = await reviewsCollection
        .where('doctorId', isEqualTo: doctorId)
        .get();
    final appointmentSnapshot = await appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final connectedVisitorIds = <String>{};
    for (final review in reviewSnapshot.docs) {
      final patientId = review.data()['patientId']?.toString();
      if (patientId != null && namesByConnectionId.containsKey(patientId)) {
        connectedVisitorIds.add(patientId);
      }
    }
    for (final appointment in appointmentSnapshot.docs) {
      final patientId = appointment.data()['patientId']?.toString();
      if (patientId != null && namesByConnectionId.containsKey(patientId)) {
        connectedVisitorIds.add(patientId);
      }
    }

    return _buildInsight(
      doctorId: doctorId,
      connectedVisitorIds: connectedVisitorIds,
      namesByConnectionId: namesByConnectionId,
    );
  }

  DoctorTrustInsight _buildInsight({
    required String doctorId,
    required Set<String> connectedVisitorIds,
    required Map<String, String> namesByConnectionId,
  }) {
    final names =
        connectedVisitorIds
            .map((visitorId) => namesByConnectionId[visitorId] ?? visitorId)
            .toList()
          ..sort();
    return DoctorTrustInsight(
      doctorId: doctorId,
      connectedPatientsCount: names.length,
      connectedPatientNames: names,
    );
  }

  String _previewFallbackOwner(String ownerId) {
    if (ownerId.startsWith('preview_')) {
      return 'preview_patient';
    }
    return ownerId;
  }
}
