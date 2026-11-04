import 'dart:async';
import 'dart:convert';

import 'package:corestone/core/push/push_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM through firebase_messaging. Android shows foreground messages with
/// flutter_local_notifications; iOS shows them natively.
class FirebasePushMessaging implements PushMessaging {
  static const _channel = AndroidNotificationChannel(
    // Matches default_notification_channel_id in AndroidManifest.xml.
    'default',
    'Notifications',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> initialize({required PushTap onTap}) async {
    try {
      // Reads google-services.json or GoogleService-Info.plist, built into
      // the app only when the flavor has one.
      await Firebase.initializeApp();
    } on Object {
      return false;
    }
    if (_android) await _initializeAndroid(onTap);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onTap(m.data));
    if (await FirebaseMessaging.instance.getInitialMessage() case final m?) {
      onTap(m.data);
    }
    return true;
  }

  Future<void> _initializeAndroid(PushTap onTap) async {
    void tapped(String? payload) => onTap(
      payload == null ? const {} : jsonDecode(payload) as Map<String, Object?>,
    );
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) => tapped(r.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      tapped(launch?.notificationResponse?.payload);
    }
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      unawaited(
        _local.show(
          id: message.messageId.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              importance: Importance.high,
              priority: Priority.high,
              icon: 'ic_notification',
            ),
          ),
          payload: jsonEncode(message.data),
        ),
      );
    });
  }

  @override
  Future<bool> requestPermission() async =>
      _granted(await FirebaseMessaging.instance.requestPermission());

  @override
  Future<bool> hasPermission() async =>
      _granted(await FirebaseMessaging.instance.getNotificationSettings());

  static bool _granted(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;
}
