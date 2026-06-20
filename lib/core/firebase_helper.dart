import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/services/laundry_service.dart';
import '../data/models/order_notification.dart';
import '../providers/notification_provider.dart';
import 'notification_helper.dart';

// Top-level background messaging handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling background message: ${message.messageId}');
}

class FirebaseHelper {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Inisialisasi Firebase & local notifications
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Inisialisasi Local Notifications untuk Foreground
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          log('Notification clicked: ${details.payload}');
        },
      );

      // Buat notification channel untuk Android
      const androidChannel = AndroidNotificationChannel(
        'laundry_status_channel',
        'Status Pesanan Laundry',
        description: 'Digunakan untuk memberi tahu perubahan status pesanan Anda.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      log("FirebaseHelper.init error: $e");
    }
  }

  /// Meminta izin notifikasi (Android 13+ & iOS)
  static Future<void> requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      log('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      log("FirebaseHelper.requestPermissions error: $e");
    }
  }

  /// Ambil token FCM dan setor ke backend Laravel
  static Future<void> setupFCMTokenUpdate() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        log("FCM Token: $token");
        await LaundryService().updateFcmToken(token);
      }

      // Dengarkan perubahan token di kemudian waktu
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log("FCM Token refreshed: $newToken");
        await LaundryService().updateFcmToken(newToken);
      }).onError((err) {
        log("Error refreshing FCM Token: $err");
      });
    } catch (e) {
      log("FirebaseHelper.setupFCMTokenUpdate error: $e");
    }
  }

  /// Dengarkan pesan masuk saat aplikasi sedang dibuka (Foreground)
  static void startForegroundListener(BuildContext context, NotificationProvider provider) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.notification?.title}');
      
      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        final String? transactionIdStr = data['transaction_id'];
        final String? invoiceCode = data['invoice_code'];
        final String? status = data['status'];

        if (transactionIdStr != null && invoiceCode != null && status != null) {
          final trxId = int.tryParse(transactionIdStr) ?? 0;
          
          final orderNotif = OrderNotification(
            id: message.messageId ?? '${trxId}_${DateTime.now().millisecondsSinceEpoch}',
            transactionId: trxId,
            invoiceCode: invoiceCode,
            oldStatus: '', // Status lama opsional untuk push
            newStatus: status,
            timestamp: DateTime.now(),
          );

          // Masukkan ke state UI lokal agar badge bertambah & list ter-update
          provider.addNotification(orderNotif);

          // Tampilkan banner meluncur (Overlay in-app)
          if (context.mounted) {
            NotificationHelper.showOrderNotification(
              context,
              orderNotif,
            );
          }
        }

        // Tampilkan juga notifikasi sistem tray bawaan HP
        _showLocalNotification(notification);
      }
    });
  }

  static Future<void> _showLocalNotification(RemoteNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'laundry_status_channel',
      'Status Pesanan Laundry',
      channelDescription: 'Digunakan untuk memberi tahu perubahan status pesanan Anda.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}
