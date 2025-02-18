import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static Future<void> initOneSignal() async {
    try {
      // Debug mode for OneSignal
      OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

      // Initialize OneSignal
      await OneSignal.shared.setAppId('44ffcdfa-336a-4785-acbf-b09a23ad8a91');

      // Prompt for push notification permission
      OneSignal.shared.promptUserForPushNotificationPermission(
        fallbackToSettings: true,
      );

      // Log current permission state
      final deviceState = await OneSignal.shared.getDeviceState();
      debugPrint('Notification Permission Granted: ${deviceState?.hasNotificationPermission}');

      // Configure notification handlers
      OneSignal.shared.setNotificationWillShowInForegroundHandler(
          (OSNotificationReceivedEvent event) {
        debugPrint('FOREGROUND NOTIFICATION RECEIVED');
        debugPrint('Notification: ${event.notification.body}');
        event.complete(event.notification);
      });

      OneSignal.shared
          .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
        debugPrint('NOTIFICATION OPENED');
        debugPrint('Notification opened: ${result.notification.body}');
      });

      OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
        debugPrint('PERMISSION OBSERVER');
        debugPrint('Has permission: ${changes.to.hasPrompted}');
      });

      // Log device state details
      if (deviceState?.userId != null) {
        debugPrint('OneSignal User ID: ${deviceState?.userId}');
        debugPrint('Push Token: ${deviceState?.pushToken}');
      } else {
        debugPrint('Failed to get device state');
      }
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  // Method to send a push notification with comprehensive error handling
  static Future<bool> sendPushNotification({
    required String title,
    required String body,
    String? deepLink,
    List<String>? playerIds,
  }) async {
    try {
      // Get current device state
      final deviceState = await OneSignal.shared.getDeviceState();
      
      if (deviceState?.userId == null) {
        debugPrint('No valid OneSignal User ID found');
        return false;
      }

      var notification = OSCreateNotification(
        playerIds: playerIds ?? [deviceState!.userId!], 
        content: body,
        heading: title,
        sendAfter: DateTime.now(),
        androidChannelId: 'church_mobile_channel',
      );

      var response = await OneSignal.shared.postNotification(notification);
      
      debugPrint('Notification Send Response: $response');
      debugPrint('Notification sent successfully to: ${playerIds ?? deviceState?.userId}');
      
      return true;
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }

  // Get the current device's push token with more detailed logging
  static Future<String?> getDeviceToken() async {
    try {
      final deviceState = await OneSignal.shared.getDeviceState();
      
      if (deviceState == null) {
        debugPrint('Device state is null');
        return null;
      }

      debugPrint('Device User ID: ${deviceState.userId}');
      debugPrint('Device Push Token: ${deviceState.pushToken}');
      
      return deviceState.userId;
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return null;
    }
  }

  // Method to check notification permissions
  static Future<bool> checkNotificationPermissions() async {
    final deviceState = await OneSignal.shared.getDeviceState();
    return deviceState?.hasNotificationPermission ?? false;
  }

  // Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    await OneSignal.shared.sendTag(topic, 'subscribed');
  }

  // Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await OneSignal.shared.deleteTag(topic);
  }
}
