import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _messageCountKey = 'daily_message_count';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _hasPremiumKey = 'has_premium';
  static const int _freeMessageLimit = 5;

  final _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  SubscriptionService() {
    _listenToPurchaseUpdates();
  }

  void _listenToPurchaseUpdates() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) {
        _handlePurchaseUpdates(purchases);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        print('Error in purchase stream: $error');
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show the user the pending purchase UI
        print('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        print('Purchase error: ${purchaseDetails.error?.message}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Grant user entitlement to the purchased product
        await _savePremiumStatus(true);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _savePremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPremiumKey, isPremium);
  }

  Future<bool> canSendMessage() async {
    if (await isPremium()) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastResetDateString = prefs.getString(_lastResetDateKey);
    final lastResetDate = lastResetDateString != null
        ? DateTime.parse(lastResetDateString)
        : DateTime.now();

    // Reset counter if it's a new day
    if (!isSameDay(lastResetDate, DateTime.now())) {
      print(
          'Resetting daily count - last reset: $lastResetDate, now: ${DateTime.now()}');
      await resetDailyCount();
      return true;
    }

    final messageCount = prefs.getInt(_messageCountKey) ?? 0;
    final canSend = messageCount < _freeMessageLimit;
    print(
        'Can send message: $canSend (count: $messageCount, limit: $_freeMessageLimit)');
    return canSend;
  }

  Future<void> incrementMessageCount() async {
    if (await isPremium()) return;

    final prefs = await SharedPreferences.getInstance();
    // Get the current count or default to 0
    final currentCount = prefs.getInt(_messageCountKey) ?? 0;
    // Increment the count
    await prefs.setInt(_messageCountKey, currentCount + 1);
    // Print for debugging
    print('Message count incremented to: ${currentCount + 1}');
  }

  Future<void> resetDailyCount() async {
    final prefs = await SharedPreferences.getInstance();

    // Get current count before reset
    final oldCount = prefs.getInt(_messageCountKey) ?? 0;

    // Reset the message count to 0
    await prefs.setInt(_messageCountKey, 0);

    // Store the current date as the last reset date
    final now = DateTime.now();
    final oldResetDate = prefs.getString(_lastResetDateKey) ?? 'never';
    await prefs.setString(_lastResetDateKey, now.toIso8601String());

    print(
        'Daily count reset from $oldCount to 0. Old reset date: $oldResetDate, new: ${now.toIso8601String()}');
  }

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPremiumKey) ?? false;
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> initializeSubscriptions() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) return;

    // Define product IDs (replace with your actual product IDs)
    const Set<String> _kIds = {
      'budget_ai_premium_monthly',
      'budget_ai_premium_yearly'
    };
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Some products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
  }

  // Get remaining message count for the current day
  Future<int?> getRemainingMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_messageCountKey);
    print('Current message count: $count');
    return count;
  }

  // Get available subscription products
  Future<List<ProductDetails>> getAvailableSubscriptions() async {
    if (_products.isEmpty) {
      await initializeSubscriptions();
    }
    return _products;
  }

  // Cleanup
  void dispose() {
    _subscription?.cancel();
  }

  // Reset message count - for testing purposes
  Future<void> resetMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final oldCount = prefs.getInt(_messageCountKey) ?? 0;
    await prefs.setInt(_messageCountKey, 0);
    print('Message count manually reset from $oldCount to 0 for testing.');
  }

  // Check current message count
  Future<int> getCurrentMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_messageCountKey) ?? 0;
    print('Current raw message count: $count');
    return count;
  }
}
