import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/symptom_log.dart';
import '../services/preview_data_store.dart';

class SymptomRepository {
  SymptomRepository({
    FirebaseFirestore? firestore,
    PreviewDataStore? previewStore,
  }) : _symptomLogs = firestore?.collection('symptom_logs'),
       _previewStore = previewStore;

  final CollectionReference<Map<String, dynamic>>? _symptomLogs;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Future<void> createLog(SymptomLog log) {
    if (isPreviewMode) {
      _previewStore!.symptomLogs[log.logId] = log;
      _previewStore.notify();
      return Future.value();
    }

    return _symptomLogs!.doc(log.logId).set(log.toMap());
  }

  Stream<List<SymptomLog>> streamPatientLogs(String patientId) {
    if (isPreviewMode) {
      return _previewStore!.watch(() {
        final logs =
            _previewStore.symptomLogs.values
                .where((log) => log.patientId == patientId)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return logs;
      });
    }

    return _symptomLogs!
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final logs =
              snapshot.docs
                  .map((doc) => SymptomLog.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return logs;
        });
  }
}
