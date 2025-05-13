import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:telephony/telephony.dart';
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

  final Telephony _telephony = Telephony.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<dynamic>? _notificationSub;
  StreamSubscription<SmsMessage>? _smsSub;

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
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // TODO: Handle notification tap for confirmation
      },
    );

    // Listen to notifications from UPI apps
    _notificationSub = NotificationListener.receivePort.listen((event) {
      if (event is ReceivedNotificationEvent) {
        if (upiAppPackages.contains(event.packageName)) {
          _handleUpiNotification(event, context);
        }
      }
    });
    await NotificationListener.startService();

    // Listen to SMS
    _smsSub = _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _handleSms(message, context);
      },
      onBackgroundMessage: null, // TODO: Add background handler if needed
    );
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.notification,
      Permission.sms,
      // Permission.receiveSms, // Not needed for permission_handler >= 10.2.0
      // Permission.readSms,    // Not needed for permission_handler >= 10.2.0
    ].request();
  }

  void _handleUpiNotification(
      ReceivedNotificationEvent event, BuildContext context) {
    final String? text = event.text;
    if (text != null && _isPaymentNotification(text)) {
      final parsed = _parsePaymentDetails(text);
      if (parsed != null) {
        _showConfirmationNotification(
            parsed['amount'], parsed['merchant'], context);
      }
    }
  }

  void _handleSms(SmsMessage message, BuildContext context) {
    final String? body = message.body;
    if (body != null && _isPaymentNotification(body)) {
      final parsed = _parsePaymentDetails(body);
      if (parsed != null) {
        _showConfirmationNotification(
            parsed['amount'], parsed['merchant'], context);
      }
    }
  }

  bool _isPaymentNotification(String text) {
    // TODO: Improve regex/logic for payment detection
    final lower = text.toLowerCase();
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('upi') ||
        lower.contains('payment');
  }

  Map<String, dynamic>? _parsePaymentDetails(String text) {
    // TODO: Use regex to extract amount, merchant, etc.
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
      String? amount, String? merchant, BuildContext context) async {
    // Use the latest API for notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'auto_expense_channel',
      'Auto Expense Detection',
      channelDescription: 'Detects payments and suggests creating expenses',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

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
    _smsSub?.cancel();
  }
}
