import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationExpenseService {
  static final NotificationExpenseService _instance =
      NotificationExpenseService._internal();
  factory NotificationExpenseService() => _instance;
  NotificationExpenseService._internal();

  // UPI app package names
  static const List<String> upiAppPackages = [
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'com.phonepe.app', // PhonePe
    'net.one97.paytm', // Paytm
  ];

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<ServiceNotificationEvent>? _notificationSub;
  bool _initialized = false;

  Future<void> initialize(BuildContext context) async {
    if (_initialized || !Platform.isAndroid) return;
    _initialized = true;

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications (latest API)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // TODO: Handle notification tap for confirmation
      },
    );

    // Listen to notifications from UPI apps
    _notificationSub = NotificationListenerService.notificationsStream.listen((
      event,
    ) {
      if (event.packageName != null &&
          upiAppPackages.contains(event.packageName)) {
        final text = event.content ?? '';
        if (_isPaymentNotification(text)) {
          final parsed = _parsePaymentDetails(text);
          if (parsed != null) {
            _showConfirmationNotification(
              parsed['amount'],
              parsed['merchant'],
              context,
            );
          }
        }
      }
    });
  }

  Future<void> _requestPermissions() async {
    // Request notification listener permission
    final granted = await NotificationListenerService.isPermissionGranted();
    if (!granted) {
      await NotificationListenerService.requestPermission();
    }
    // Optionally request notification permission for local notifications
    await [Permission.notification].request();
  }

  bool _isPaymentNotification(String text) {
    final lower = text.toLowerCase();
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('upi') ||
        lower.contains('payment');
  }

  Map<String, dynamic>? _parsePaymentDetails(String text) {
    final amountRegex = RegExp(r'(?:Rs\.?|INR|₹)\s?(\d+[,.]?\d*)');
    final match = amountRegex.firstMatch(text);
    if (match != null) {
      return {
        'amount': match.group(1),
        'merchant': 'Unknown', // TODO: Extract merchant if possible
        'raw': text,
      };
    }
    return null;
  }

  Future<void> _showConfirmationNotification(
    String? amount,
    String? merchant,
    BuildContext context,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'auto_expense_channel',
          'Auto Expense Detection',
          channelDescription: 'Detects payments and suggests creating expenses',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      1001,
      'Payment detected',
      'Payment of ₹$amount to $merchant detected. Create expense?',
      platformChannelSpecifics,
      payload: 'create_expense',
    );
    // TODO: On tap, show confirmation dialog in app and call API if confirmed
  }

  void dispose() {
    _notificationSub?.cancel();
  }
}
