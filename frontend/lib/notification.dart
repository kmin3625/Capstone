import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'party_chat.dart';

class NotificationSettings {
  static bool shouldReceiveNotifications = true;
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print('notification payload: ${response.payload}');
          handleMessageClick(response.payload!);
        }
      },
    );

    // 알림 권한 요청
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }

    if (status.isGranted) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a foreground message: ${message.messageId}');
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          showNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Message clicked! ${message.messageId}');
        handleMessageClick(jsonEncode(message.data));
      });
    } else {
      print('Notification permission denied');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
    showNotification(message);
  }

  static Future<void> showNotification(RemoteMessage message) async {
    if (!NotificationSettings.shouldReceiveNotifications) {
      print('Notification suppressed due to active screen.');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  static void handleMessageClick(String payload) {
    print('Notification clicked with payload: $payload');
    final data = jsonDecode(payload);

    final partyIDString = data['partyID'];
    if (partyIDString != null) {
      try {
        final partyID = int.parse(partyIDString); // partyID를 int로 변환
        _navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => PartyChat(),
          settings: RouteSettings(arguments: partyID), // partyID를 arguments로 전달
        ));
      } catch (e) {
        print('Error parsing partyID: $e');
      }
    } else {
      print('partyID not found in payload');
    }
  }

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}