import "dart:io";

import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_ringtone_player/flutter_ringtone_player.dart";
import "package:senior_citizen_app/services/api_service.dart";

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String emergencyChannelId = "emergency_alerts";
  static const String serviceChannelId = "service_requests";
  static bool _localReady = false;
  static bool _alarmActive = false;
  static final Set<int> _activeEmergencyNotificationIds = <int>{};

  static Future<void> _initLocalNotifications() async {
    if (_localReady) return;
    const androidInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    const emergencyChannel = AndroidNotificationChannel(
      emergencyChannelId,
      "Emergency Alerts",
      description: "Critical SOS and ambulance alerts",
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    const serviceChannel = AndroidNotificationChannel(
      serviceChannelId,
      "Service Requests",
      description: "Regular service request alerts",
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidLocal = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidLocal?.createNotificationChannel(emergencyChannel);
    await androidLocal?.createNotificationChannel(serviceChannel);
    _localReady = true;
  }

  static Future<void> initializeLocalOnly() async {
    await _initLocalNotifications();
  }

  static Future<void> showFromMessage(
    RemoteMessage message, {
    bool playAlarm = true,
  }) async {
    await _initLocalNotifications();
    final type = (message.data["type"] ?? "").toString().toLowerCase();
    if (type.isEmpty) return;
    final requestId = int.tryParse(
      (message.data["request_id"] ?? "").toString(),
    );
    if (type == "emergency_alarm_stop") {
      if (requestId != null) {
        await _localNotifications.cancel(requestId);
        _activeEmergencyNotificationIds.remove(requestId);
      }
      await stopSosAlarm();
      return;
    }
    final emergencyType = (message.data["emergency_type"] ?? "")
        .toString()
        .toLowerCase();
    final shouldAlarm =
        (message.data["alarm"] ?? "").toString().toLowerCase() == "true";

    final title = (message.data["title"] ?? "").toString().isNotEmpty
        ? message.data["title"].toString()
        : (message.notification?.title ??
              (type == "service_request"
                  ? "New Service Request"
                  : "Emergency Alert"));
    final body = (message.data["body"] ?? "").toString().isNotEmpty
        ? message.data["body"].toString()
        : (message.notification?.body ??
              (type == "service_request"
                  ? "A senior requested your help."
                  : "A senior needs assistance nearby."));

    if (shouldAlarm && playAlarm) {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: false,
        volume: 1.0,
        asAlarm: true,
      );
      _alarmActive = true;
    }

    final notificationId =
        requestId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (shouldAlarm) {
      _activeEmergencyNotificationIds.add(notificationId);
    }

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          type == "service_request" ? serviceChannelId : emergencyChannelId,
          type == "service_request" ? "Service Requests" : "Emergency Alerts",
          channelDescription: type == "service_request"
              ? "Regular service request alerts"
              : "Critical SOS and ambulance alerts",
          importance: type == "service_request"
              ? Importance.high
              : Importance.max,
          priority: type == "service_request" ? Priority.high : Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
          ongoing: false,
          autoCancel: true,
          category: shouldAlarm ? AndroidNotificationCategory.alarm : null,
        ),
      ),
    );
  }

  static Future<void> stopSosAlarm() async {
    // Some Android devices keep alarm audio alive briefly; stop in short retries.
    await FlutterRingtonePlayer().stop();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await FlutterRingtonePlayer().stop();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await FlutterRingtonePlayer().stop();
    _alarmActive = false;

    for (final id in _activeEmergencyNotificationIds) {
      await _localNotifications.cancel(id);
    }
    _activeEmergencyNotificationIds.clear();
    await _localNotifications.cancelAll();
  }

  static Future<void> initialize() async {
    await _initLocalNotifications();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setAutoInitEnabled(true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showFromMessage(message);
    });

    _messaging.onTokenRefresh.listen((String refreshedToken) async {
      try {
        final role = await ApiService.getRole();
        if (role != "volunteer" &&
            role != "ambulance" &&
            role != "senior" &&
            role != "admin")
          return;
        await ApiService.saveDeviceToken(
          token: refreshedToken,
          platform: _platform(),
        );
      } catch (_) {
        // Ignore transient token refresh errors.
      }
    });
  }

  static String _platform() {
    if (Platform.isIOS) return "ios";
    if (Platform.isAndroid) return "android";
    return "web";
  }

  static Future<void> syncVolunteerDeviceToken() async {
    try {
      final role = await ApiService.getRole();
      if (role != "volunteer" &&
          role != "ambulance" &&
          role != "senior" &&
          role != "admin")
        return;

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await ApiService.saveDeviceToken(token: token, platform: _platform());
    } catch (_) {
      // Keep app flow working if Firebase is not configured yet.
    }
  }

  static Future<void> removeVolunteerDeviceToken() async {
    try {
      final role = await ApiService.getRole();
      if (role != "volunteer" &&
          role != "ambulance" &&
          role != "senior" &&
          role != "admin")
        return;

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await ApiService.deleteDeviceToken(token);
    } catch (_) {
      // Ignore token delete errors on logout.
    }
  }
}
