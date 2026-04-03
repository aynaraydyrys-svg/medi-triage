import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/formatters.dart';
import '../repositories/user_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    bool enabled = true,
  })  : _enabled = enabled,
        _messaging = enabled ? (messaging ?? FirebaseMessaging.instance) : null,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final bool _enabled;
  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool get _supportsLocalNotifications => !kIsWeb;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'medimatch_booking_channel',
    'MediTriage Appointments',
    description: 'MediTriage confirmations and reminders.',
    importance: Importance.high,
  );

  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'medimatch_booking_channel',
          'MediTriage Appointments',
          channelDescription: 'MediTriage confirmations and reminders.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> initialize() async {
    if (_initialized) return;

    if (_supportsLocalNotifications) {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    if (_enabled) {
      final messaging = _messaging;
      if (messaging == null) {
        _initialized = true;
        return;
      }

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.setAutoInitEnabled(true);

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? 'MediTriage update';
        final body = message.notification?.body ?? 'You have a new alert.';
        showLocalNotification(title: title, body: body);
      });
    }

    _initialized = true;
  }

  Future<void> syncTokenToUser({
    required String uid,
    required UserRepository userRepository,
  }) async {
    if (!_enabled) return;

    final messaging = _messaging;
    if (messaging == null) return;

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await userRepository.saveFcmToken(uid, token);
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen((newToken) {
      userRepository.saveFcmToken(uid, newToken);
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (!_supportsLocalNotifications) return;

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: _notificationDetails,
    );
  }

  Future<void> triggerBookingConfirmation({
    required String doctorName,
    required DateTime slotTime,
  }) async {
    await showLocalNotification(
      title: 'Appointment booked',
      body:
          'Visit with $doctorName: ${AppFormatters.appointment.format(slotTime)}.',
    );
  }

  Future<void> scheduleReminderPlaceholder({
    required String doctorName,
    required DateTime slotTime,
  }) async {
    if (!_supportsLocalNotifications) return;

    final reminderTime = slotTime.subtract(const Duration(hours: 2));
    if (!reminderTime.isAfter(DateTime.now())) return;

    await _localNotifications.zonedSchedule(
      id: slotTime.millisecondsSinceEpoch ~/ 1000,
      title: 'Visit soon',
      body: 'Reminder: $doctorName at ${AppFormatters.timeOnly.format(slotTime)}.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}