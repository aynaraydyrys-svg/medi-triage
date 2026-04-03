import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/appointment_status.dart';
import '../models/appointment.dart';
import '../services/preview_data_store.dart';
import 'doctor_repository.dart';

class AppointmentRepository {
  AppointmentRepository({
    FirebaseFirestore? firestore,
    required DoctorRepository doctorRepository,
    PreviewDataStore? previewStore,
  }) : _firestore = firestore,
       _doctorRepository = doctorRepository,
       _appointments = firestore?.collection('appointments'),
       _previewStore = previewStore;

  final FirebaseFirestore? _firestore;
  final DoctorRepository _doctorRepository;
  final CollectionReference<Map<String, dynamic>>? _appointments;
  final PreviewDataStore? _previewStore;

  bool get isPreviewMode => _previewStore != null;

  Stream<List<Appointment>> streamPatientAppointments(String patientId) {
    if (isPreviewMode) {
      return _previewStore!.watch(() {
        final appointments =
            _previewStore.appointments.values
                .where((appointment) => appointment.patientId == patientId)
                .toList()
              ..sort((a, b) => a.slotTime.compareTo(b.slotTime));
        return appointments;
      });
    }

    return _appointments!
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final appointments =
              snapshot.docs
                  .map((doc) => Appointment.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => a.slotTime.compareTo(b.slotTime));
          return appointments;
        });
  }

  Stream<List<Appointment>> streamDoctorAppointments(String doctorId) {
    if (isPreviewMode) {
      return _previewStore!.watch(() {
        final appointments =
            _previewStore.appointments.values
                .where((appointment) => appointment.doctorId == doctorId)
                .toList()
              ..sort((a, b) => a.slotTime.compareTo(b.slotTime));
        return appointments;
      });
    }

    return _appointments!
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final appointments =
              snapshot.docs
                  .map((doc) => Appointment.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => a.slotTime.compareTo(b.slotTime));
          return appointments;
        });
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    if (isPreviewMode) {
      final doctor = await _doctorRepository.fetchDoctor(appointment.doctorId);
      if (doctor == null) {
        throw Exception('Doctor profile unavailable');
      }
      if (!doctor.availableSlots.contains(appointment.slotTime)) {
        throw Exception('Slot already booked');
      }

      _previewStore!.appointments[appointment.appointmentId] = appointment;
      final updatedSlots = [...doctor.availableSlots]
        ..remove(appointment.slotTime);
      await _doctorRepository.upsertDoctorProfile(
        doctor.copyWith(
          availableSlots: updatedSlots,
          updatedAt: DateTime.now(),
        ),
      );
      _previewStore.notify();
      return appointment;
    }

    final firestore = _firestore!;
    final appointmentRef = _appointments!.doc(appointment.appointmentId);
    final doctorRef = firestore.collection('doctors').doc(appointment.doctorId);
    final slotIso = appointment.slotTime.toIso8601String();

    await firestore.runTransaction((transaction) async {
      final doctorSnapshot = await transaction.get(doctorRef);
      if (!doctorSnapshot.exists) {
        throw Exception('Doctor profile unavailable');
      }

      final currentSlots = List<String>.from(
        doctorSnapshot.data()?['availableSlots'] ?? <String>[],
      );
      if (!currentSlots.contains(slotIso)) {
        throw Exception('Slot already booked');
      }

      currentSlots.remove(slotIso);
      transaction.set(appointmentRef, appointment.toMap());
      transaction.update(doctorRef, {
        'availableSlots': currentSlots,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });

    return appointment;
  }

  Future<void> updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus status,
  ) async {
    if (isPreviewMode) {
      _previewStore!.appointments[appointment.appointmentId] = appointment
          .copyWith(status: status, updatedAt: DateTime.now());
      _previewStore.notify();

      if (status == AppointmentStatus.cancelled &&
          appointment.status != AppointmentStatus.cancelled &&
          appointment.slotTime.isAfter(DateTime.now())) {
        await _doctorRepository.restoreSlotIfNeeded(
          appointment.doctorId,
          appointment.slotTime,
        );
      }
      return;
    }

    await _appointments!.doc(appointment.appointmentId).set({
      'status': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    if (status == AppointmentStatus.cancelled &&
        appointment.status != AppointmentStatus.cancelled &&
        appointment.slotTime.isAfter(DateTime.now())) {
      await _doctorRepository.restoreSlotIfNeeded(
        appointment.doctorId,
        appointment.slotTime,
      );
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    if (isPreviewMode) {
      final appointment = _previewStore!.appointments[appointmentId];
      if (appointment == null) {
        return;
      }

      final shouldRestoreSlot =
          (appointment.status == AppointmentStatus.pending ||
              appointment.status == AppointmentStatus.confirmed) &&
          appointment.slotTime.isAfter(DateTime.now());

      _previewStore.appointments.remove(appointmentId);

      if (shouldRestoreSlot) {
        await _doctorRepository.restoreSlotIfNeeded(
          appointment.doctorId,
          appointment.slotTime,
        );
      }

      _previewStore.notify();
      return;
    }

    final appointmentSnapshot = await _appointments!.doc(appointmentId).get();
    if (!appointmentSnapshot.exists) {
      return;
    }

    final appointment = Appointment.fromMap(appointmentSnapshot.data()!);
    final shouldRestoreSlot =
        (appointment.status == AppointmentStatus.pending ||
            appointment.status == AppointmentStatus.confirmed) &&
        appointment.slotTime.isAfter(DateTime.now());

    await _appointments!.doc(appointmentId).delete();

    if (shouldRestoreSlot) {
      await _doctorRepository.restoreSlotIfNeeded(
        appointment.doctorId,
        appointment.slotTime,
      );
    }
  }
}