import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  // Singleton instance of the plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the service for Android (and iOS if needed)
  static Future<void> initialize() async {
    // Android initialization settings using the default app icon
    // Ensure '@mipmap/ic_launcher' exists in your android/app/src/main/res folder
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Here you can handle what happens when a user clicks the notification
        // e.g., navigate to the specific issue page
      },
    );

    // Create a high-importance notification channel for Android 8.0+ 
    // This is required for sound and head-up (pop-up) alerts
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'issue_alerts_channel', // id
      'Issue Expiry Alerts',   // title
      description: 'Alerts for issues that are expiring or have been deleted.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Trigger a sound notification on the phone
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'issue_alerts_channel', // Must match the channel ID created above
      'Issue Expiry Alerts',
      channelDescription: 'Alerts for issues that are expiring or have been deleted.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
}