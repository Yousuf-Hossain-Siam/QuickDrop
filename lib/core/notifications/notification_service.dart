import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const settings = AndroidInitializationSettings('ic_notification');
    await _plugin.initialize(const InitializationSettings(android: settings));
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showProgress({
    required int id,
    required String title,
    required int progress,
  }) {
    return _plugin.show(
      id,
      title,
      progress >= 100 ? 'Completed' : '$progress% complete',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'transfers',
          'File transfers',
          icon: 'ic_notification',
          channelDescription: 'Upload and download progress',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress.clamp(0, 100),
        ),
      ),
    );
  }

  Future<void> showResult({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'transfer_results',
          'Transfer results',
          icon: 'ic_notification',
          channelDescription: 'Completed file transfers',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
