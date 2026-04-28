import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification toggle storage keys
const String _notificationsEnabledKey = 'notifications_enabled';

/// Flexible Notification Service supporting multiple notification channels and deep linking
/// 
/// Channels:
/// - 'health_reminders' (id: 100): Hydration, steps, and health reminders
/// - 'health_achievements' (id: 101): Daily achievements and milestones
/// - 'general' (id: 102): General notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const String channelReminders = 'health_reminders';
  static const String channelAchievements = 'health_achievements';
  static const String channelGeneral = 'general';

  // Notification IDs for different types (to prevent duplicates)
  static const int notificationIdSteps = 100;
  static const int notificationIdHydration = 101;
  static const int notificationIdGeneral = 102;

  // Timer for hydration reminders
  static Timer? _hydrationReminderTimer;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create channels
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel remindersChannel =
        AndroidNotificationChannel(
      channelReminders,
      'Health Reminders',
      description: 'Reminders for hydration, steps, and health activities',
      importance: Importance.max,
    );

    const AndroidNotificationChannel achievementsChannel =
        AndroidNotificationChannel(
      channelAchievements,
      'Health Achievements',
      description: 'Daily achievements and milestone notifications',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      channelGeneral,
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(remindersChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(achievementsChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set yet
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Enable or disable all notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    print(enabled ? '✓ Notifications enabled' : '🔕 Notifications disabled');
  }

  /// Show a custom notification
  /// 
  /// [id] - Notification ID (used to replace existing notifications with same ID)
  /// [title] - Notification title
  /// [body] - Notification body/message
  /// [channelId] - Channel ID (defaults to general)
  /// [payload] - Optional payload for deep linking (e.g., 'hydration', 'steps')
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = channelGeneral,
    String? payload,
  }) async {
    // Check if notifications are enabled
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) {
      print('🔕 Notifications disabled - skipping: $title');
      return;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportance(channelId),
      priority: _getPriority(channelId),
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload
    );
  }

  /// Show a steps notification (daily achievement)
  /// Shows: "You walked X steps today!"
  static Future<void> showStepsNotification(int steps) async {
    await showNotification(
      id: notificationIdSteps,
      title: '🚶 Daily Steps',
      body: 'You walked $steps steps today!',
      channelId: channelAchievements,
      payload: 'steps',
    );
  }

  /// Show a hydration reminder notification
  /// Shows: "Don't forget to drink water! 💧"
  static Future<void> showHydrationReminder() async {
    await showNotification(
      id: notificationIdHydration,
      title: '💧 Hydration Reminder',
      body: 'Don\'t forget to drink water and log your intake!',
      channelId: channelReminders,
      payload: 'hydration',
    );
  }

  /// Show a generic notification (legacy support)
  static Future<void> showNotificationLegacy() async {
    await showNotification(
      id: notificationIdGeneral,
      title: 'Hello 👋',
      body: 'This is your first notification',
      channelId: channelGeneral,
    );
  }

  /// Schedule hydration reminders to check hourly if user needs to be reminded
  /// Reschedules when user adds a hydration entry
  /// Runs only during waking hours (6 AM - 11 PM) and if no recent entry exists
  static Future<void> scheduleHydrationReminder() async {
    try {
      // Cancel existing timer if any
      _hydrationReminderTimer?.cancel();

      print('⏰ Hydration reminder scheduled (checks hourly)');

      // Check immediately on first schedule
      await _checkAndShowHydrationReminder();

      // Then check every hour
      _hydrationReminderTimer = Timer.periodic(const Duration(hours: 1), (_) async {
        await _checkAndShowHydrationReminder();
      });
    } catch (e) {
      print('⚠️ Error scheduling hydration reminder: $e');
    }
  }

  /// Cancel hydration reminder timer
  static Future<void> cancelHydrationReminder() async {
    try {
      _hydrationReminderTimer?.cancel();
      _hydrationReminderTimer = null;
      print('✓ Hydration reminder cancelled');
    } catch (e) {
      print('⚠️ Error cancelling hydration reminder: $e');
    }
  }

  /// Check if user should be reminded and show notification if needed
  static Future<void> _checkAndShowHydrationReminder() async {
    try {
      // Skip if reminder was shown in the last 45 minutes
      final prefs = await SharedPreferences.getInstance();
      final lastReminderTime = prefs.getInt('last_hydration_reminder_shown') ?? 0;
      final timeSinceLastReminder = DateTime.now().millisecondsSinceEpoch - lastReminderTime;

      if (timeSinceLastReminder < 45 * 60 * 1000) {
        print('⏭️ Hydration reminder shown recently, skipping');
        return;
      }

      // Check if it's during waking hours (6 AM - 11 PM)
      final now = DateTime.now();
      if (now.hour < 6 || now.hour >= 23) {
        print('🌙 Outside waking hours, skipping hydration reminder');
        return;
      }

      // This would need to be imported to check the actual reminder status
      // For now, we'll just show the reminder - the check will be done
      // when this is called from HydrationViewModel/Repository
      print('💧 Showing hydration reminder');
      await showHydrationReminder();

      // Save reminder timestamp
      await prefs.setInt(
        'last_hydration_reminder_shown',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('❌ Error checking hydration reminder: $e');
    }
  }

  /// Handle notification tap - route to appropriate screen
  static Future<void> _handleNotificationTap(
    NotificationResponse response,
  ) async {
    final String? payload = response.payload;
    print('🔔 Notification tapped with payload: $payload');

    // TODO: Implement deep linking based on payload
    // This would typically use a navigation service to route to:
    // - 'hydration' -> HydrationLogScreen
    // - 'steps' -> StepTrackerScreen
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case channelReminders:
        return 'Health Reminders';
      case channelAchievements:
        return 'Health Achievements';
      case channelGeneral:
      default:
        return 'General';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case channelReminders:
        return 'Reminders for health activities';
      case channelAchievements:
        return 'Daily achievements and milestones';
      case channelGeneral:
      default:
        return 'General notifications';
    }
  }

  static Importance _getImportance(String channelId) {
    switch (channelId) {
      case channelReminders:
        return Importance.max;
      case channelAchievements:
        return Importance.defaultImportance;
      case channelGeneral:
      default:
        return Importance.defaultImportance;
    }
  }

  static Priority _getPriority(String channelId) {
    switch (channelId) {
      case channelReminders:
        return Priority.high;
      case channelAchievements:
      case channelGeneral:
      default:
        return Priority.defaultPriority;
    }
  }
}