import 'dart:async';
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static const String _messageCountKey = 'daily_message_count';
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _hasPremiumKey = 'has_premium';
  static const String _lastQuotaKey = 'last_quota';
  static const String _lastQuotaDateKey = 'last_quota_date';
  static const int _freeMessageLimit = 5;
  static const int _premiumMessageLimit = 100;

  // Subscription Product IDs
  static const Set<String> _kIds = <String>{
    'premium_monthly', // Monthly subscription ID
    'premium_yearly', // Yearly subscription ID
  };

  // API endpoints
  static const String _baseUrl = 'https://backend-2xqnus4dqq-uc.a.run.app';
  static const String _subscriptionStatusEndpoint = '/subscriptions/status';
  static const String _messageQuotaEndpoint = '/subscriptions/message-quota';
  static const String _verifyPurchaseEndpoint =
      '/subscriptions/verify-purchase';

  final _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Cache for quota and subscription status
  DateTime? _lastQuotaCheck;
  Map<String, dynamic>? _cachedQuotaData;
  DateTime? _lastSubscriptionCheck;
  bool? _cachedPremiumStatus;

  // Cached remaining message count
  int? _cachedRemainingCount;

  // Cache duration for subscription status (5 minutes)
  static const Duration _subscriptionCacheDuration = Duration(minutes: 5);

  SubscriptionService() {
    _listenToPurchaseUpdates();
  }

  // Helper to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
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
        // Verify the purchase with the server
        try {
          await verifyPurchase(
              packageName:
                  'com.company.budgetai', // Replace with actual package name
              subscriptionId: purchaseDetails.productID,
              purchaseToken:
                  purchaseDetails.verificationData.serverVerificationData,
              platform: 'android' // or 'ios' depending on platform
              );

          // Store locally as well as a fallback
          await _savePremiumStatus(true);

          // Clear the cached data to force a refresh
          _cachedPremiumStatus = null;
          _cachedQuotaData = null;
          _lastQuotaCheck = null;
          _lastSubscriptionCheck = null;
        } catch (e) {
          print('Error verifying purchase with server: $e');
        }
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Verify purchase with server
  Future<bool> verifyPurchase({
    required String packageName,
    required String subscriptionId,
    required String purchaseToken,
    required String platform,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_verifyPurchaseEndpoint'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'packageName': packageName,
          'subscriptionId': subscriptionId,
          'purchaseToken': purchaseToken,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Purchase verification successful: ${data['message']}');
        return data['success'] ?? false;
      } else {
        print('Purchase verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error verifying purchase: $e');
      return false;
    }
  }

  Future<void> _savePremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPremiumKey, isPremium);
    _cachedPremiumStatus = isPremium;
  }

  // Check if user can send a message using server API
  Future<bool> canSendMessage() async {
    try {
      // Get quota from server
      final quotaData = await getMessageQuota();
      return quotaData['quota']['hasQuotaLeft'] ?? false;
    } catch (e) {
      print('Error checking message quota from server: $e');

      // Fall back to local check if server check fails
      return _canSendMessageLocal();
    }
  }

  // Local fallback for checking message quota
  Future<bool> _canSendMessageLocal() async {
    final isPremiumUser = await isPremium();
    if (isPremiumUser) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastResetDateString = prefs.getString(_lastResetDateKey);
    final lastResetDate = lastResetDateString != null
        ? DateTime.parse(lastResetDateString)
        : DateTime.now();

    // Reset counter if it's a new day
    if (!isSameDay(lastResetDate, DateTime.now())) {
      print(
          'Resetting daily count locally - last reset: $lastResetDate, now: ${DateTime.now()}');
      await resetDailyCount();
      return true;
    }

    final messageCount = prefs.getInt(_messageCountKey) ?? 0;
    final canSend = messageCount < _freeMessageLimit;
    print(
        'Local check - Can send message: $canSend (count: $messageCount, limit: $_freeMessageLimit)');
    return canSend;
  }

  // Increment message count - calls API to get updated count
  Future<void> incrementMessageCount() async {
    try {
      // The message quota will be updated server-side when a message is sent
      // We'll clear the cache to ensure we get the latest count on next check
      _cachedQuotaData = null;
      _lastQuotaCheck = null;
      _cachedRemainingCount = null;

      // But we'll also update local count as fallback
      await _incrementMessageCountLocal();
    } catch (e) {
      print('Error updating message count: $e');
      // Fall back to local update
      await _incrementMessageCountLocal();
    }
  }

  // Local fallback for incrementing message count
  Future<void> _incrementMessageCountLocal() async {
    if (await isPremium()) return;

    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_messageCountKey) ?? 0;
    await prefs.setInt(_messageCountKey, currentCount + 1);
    print('Local message count incremented to: ${currentCount + 1}');
  }

  Future<void> resetDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final oldCount = prefs.getInt(_messageCountKey) ?? 0;
    await prefs.setInt(_messageCountKey, 0);

    final now = DateTime.now();
    await prefs.setString(_lastResetDateKey, now.toIso8601String());

    print(
        'Daily count reset locally from $oldCount to 0 at ${now.toIso8601String()}');

    // Clear cache
    _cachedQuotaData = null;
    _lastQuotaCheck = null;
    _cachedRemainingCount = null;
  }

  // Get the cached premium status without making an API call
  bool? getCachedPremiumStatus() {
    if (_cachedPremiumStatus != null && _lastSubscriptionCheck != null) {
      final cacheAge = DateTime.now().difference(_lastSubscriptionCheck!);
      if (cacheAge < _subscriptionCacheDuration) {
        print('Using cached premium status: $_cachedPremiumStatus');
        return _cachedPremiumStatus;
      }
    }
    return null;
  }

  // Check premium status using server API
  Future<bool> isPremium() async {
    // Check cache first
    final cachedStatus = getCachedPremiumStatus();
    if (cachedStatus != null) {
      return cachedStatus;
    }

    // Check local storage next
    final localStatus = await _getLocalPremiumStatus();
    if (localStatus) {
      print('Using local premium status (true)');
      return true;
    }

    try {
      print('Fetching premium status from server...');
      final response = await http.get(
        Uri.parse('$_baseUrl$_subscriptionStatusEndpoint'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isPremium = data['isPremium'] ?? false;

        // Update cache and local storage
        _cachedPremiumStatus = isPremium;
        _lastSubscriptionCheck = DateTime.now();
        await _savePremiumStatus(isPremium);

        print('Premium status from server: $isPremium');
        return isPremium;
      } else {
        print('Failed to get subscription status: ${response.statusCode}');
        return localStatus;
      }
    } catch (e) {
      print('Error checking premium status: $e');
      return localStatus;
    }
  }

  Future<bool> _getLocalPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPremiumKey) ?? false;
  }

  // Get initial quota from local storage
  Future<Map<String, dynamic>> getInitialQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final lastQuotaDate = prefs.getString(_lastQuotaDateKey);
    final lastQuota = prefs.getInt(_lastQuotaKey);
    final isPremium = prefs.getBool(_hasPremiumKey) ?? false;
    final limit = isPremium ? _premiumMessageLimit : _freeMessageLimit;

    // If last quota date is not today, reset to full quota
    if (lastQuotaDate == null ||
        !isSameDay(DateTime.parse(lastQuotaDate), DateTime.now())) {
      print('New day detected, resetting quota to full');
      return {
        'quota': {
          'hasQuotaLeft': true,
          'remainingQuota': limit,
          'dailyLimit': limit,
          'isPremium': isPremium
        }
      };
    }

    // Use cached quota if available
    if (lastQuota != null) {
      print('Using cached quota: $lastQuota');
      return {
        'quota': {
          'hasQuotaLeft': lastQuota > 0,
          'remainingQuota': lastQuota,
          'dailyLimit': limit,
          'isPremium': isPremium
        }
      };
    }

    // Default to full quota if no cache
    return {
      'quota': {
        'hasQuotaLeft': true,
        'remainingQuota': limit,
        'dailyLimit': limit,
        'isPremium': isPremium
      }
    };
  }

  // Update local quota cache
  Future<void> updateLocalQuota(int remainingQuota, bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastQuotaKey, remainingQuota);
    await prefs.setString(_lastQuotaDateKey, DateTime.now().toIso8601String());
    await prefs.setBool(_hasPremiumKey, isPremium);
    print(
        'Updated local quota cache: remaining=$remainingQuota, isPremium=$isPremium');
  }

  // Modified getMessageQuota to use local cache first
  Future<Map<String, dynamic>> getMessageQuota() async {
    try {
      // First check if we have fresh cache
      final cachedData = await getCachedQuotaData();
      if (cachedData != null) {
        print('Using cached quota data');
        return cachedData;
      }

      print('Fetching message quota from server...');
      final response = await http.get(
        Uri.parse('$_baseUrl$_messageQuotaEndpoint'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the API response
        await cacheQuotaData(data);

        // Update the cached remaining count
        if (data['quota'] != null) {
          _cachedRemainingCount = data['quota']['remainingQuota'] as int? ?? 0;
        }

        print('Message quota fetched: $data');
        return data;
      } else {
        print('Failed to fetch message quota: ${response.statusCode}');

        // Fall back to cached data if available, even if expired
        final expiredCache = await getCachedQuotaData(checkExpiry: false);
        if (expiredCache != null) {
          return expiredCache;
        }

        return {'error': 'Failed to fetch message quota'};
      }
    } catch (e) {
      print('Error fetching message quota: $e');

      // Try to use cached data in case of error
      final expiredCache = await getCachedQuotaData(checkExpiry: false);
      if (expiredCache != null) {
        return expiredCache;
      }

      return {'error': 'Error fetching message quota: $e'};
    }
  }

  // Store message quota data in local storage
  Future<void> cacheQuotaData(Map<String, dynamic> quotaData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(quotaData);

      await prefs.setString(_lastQuotaKey, jsonString);
      await prefs.setString(
          _lastQuotaDateKey, DateTime.now().toIso8601String());

      // Also update our cached values
      if (quotaData['quota'] != null) {
        final quota = quotaData['quota'];
        _cachedRemainingCount = quota['remainingQuota'] as int? ?? 0;
        _cachedPremiumStatus = quota['isPremium'] as bool? ?? false;
        _cachedQuotaData = quotaData;
        _lastQuotaCheck = DateTime.now();
      }

      print('Message quota data cached successfully');
    } catch (e) {
      print('Error caching quota data: $e');
    }
  }

  // Get cached message quota data
  Future<Map<String, dynamic>?> getCachedQuotaData(
      {bool checkExpiry = true}) async {
    try {
      // If we have cached quota in memory, use that
      if (_cachedQuotaData != null && _lastQuotaCheck != null) {
        final cacheAge = DateTime.now().difference(_lastQuotaCheck!);

        // Use in-memory cache if it's fresh (less than 5 minutes old)
        if (cacheAge < const Duration(minutes: 5)) {
          print('Using in-memory cached quota data');
          return _cachedQuotaData;
        }
      }

      // Otherwise, try to load from persistent storage
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_lastQuotaKey);
      final lastDateStr = prefs.getString(_lastQuotaDateKey);

      if (jsonString == null || lastDateStr == null) {
        return null;
      }

      // Check if cache is expired (older than 1 hour)
      if (checkExpiry) {
        final lastDate = DateTime.parse(lastDateStr);
        final now = DateTime.now();

        if (now.difference(lastDate) > const Duration(hours: 1)) {
          print('Quota cache expired');
          return null;
        }
      }

      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Update in-memory cache
      _cachedQuotaData = data;
      _lastQuotaCheck = DateTime.now();

      if (data['quota'] != null) {
        _cachedRemainingCount = data['quota']['remainingQuota'] as int? ?? 0;
      }

      return data;
    } catch (e) {
      print('Error retrieving cached quota: $e');
      return null;
    }
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Initialize subscriptions
  Future<void> initializeSubscriptions() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('Store not available');
      return;
    }

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_kIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Some product IDs not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('Found ${_products.length} products:');
      for (final product in _products) {
        print('Product: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      print('Error initializing subscriptions: $e');
    }
  }

  // Get available subscription products
  Future<List<ProductDetails>> getAvailableSubscriptions() async {
    if (_products.isEmpty) {
      await initializeSubscriptions();
    }
    return _products;
  }

  // Purchase a subscription
  Future<bool> purchaseSubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print('Purchase initiated: $success');
      return success;
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }

  // Get remaining message count for the current day
  Future<int?> getRemainingMessageCount() async {
    try {
      // If we have a cached value, use it
      if (_cachedRemainingCount != null && _lastQuotaCheck != null) {
        final difference = DateTime.now().difference(_lastQuotaCheck!);
        if (difference.inMinutes < 2) {
          // Cache for 2 minutes
          return _cachedRemainingCount;
        }
      }

      // Otherwise get from server
      final quotaData = await getMessageQuota();
      final quota = quotaData['quota'];
      if (quota != null) {
        return quota['remainingQuota'] as int?;
      }
      return null;
    } catch (e) {
      print('Error getting remaining message count from server: $e');

      // Fall back to local storage
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_messageCountKey) ?? 0;
      final isPremiumUser = await isPremium();
      final limit = isPremiumUser ? _premiumMessageLimit : _freeMessageLimit;
      return limit - count;
    }
  }

  // Get daily message limit based on subscription status
  Future<int> getDailyMessageLimit() async {
    try {
      final quotaData = await getMessageQuota();
      final quota = quotaData['quota'];
      if (quota != null) {
        return quota['dailyLimit'] as int? ?? _freeMessageLimit;
      }

      // Fall back to checking premium status
      final isPremiumUser = await isPremium();
      return isPremiumUser ? _premiumMessageLimit : _freeMessageLimit;
    } catch (e) {
      print('Error getting daily message limit: $e');

      // Fall back to checking local premium status
      final isPremiumUser = await isPremium();
      return isPremiumUser ? _premiumMessageLimit : _freeMessageLimit;
    }
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

    // Clear cache
    _cachedQuotaData = null;
    _lastQuotaCheck = null;
    _cachedRemainingCount = null;
  }

  // Check current message count
  Future<int> getCurrentMessageCount() async {
    try {
      final quotaData = await getMessageQuota();
      final quota = quotaData['quota'];
      if (quota != null) {
        final remaining = quota['remainingQuota'] as int? ?? 0;
        final limit = quota['dailyLimit'] as int? ?? _freeMessageLimit;
        return limit - remaining;
      }

      // Fall back to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_messageCountKey) ?? 0;
    } catch (e) {
      print('Error getting current message count: $e');

      // Fall back to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_messageCountKey) ?? 0;
    }
  }

  // Update quota information from API response
  Future<void> updateQuotaFromResponse({
    required int remainingQuota,
    required int dailyLimit,
    required bool isPremium,
  }) async {
    print(
        "Updating quota from API response: remaining=$remainingQuota, limit=$dailyLimit, isPremium=$isPremium");

    // Update cached values
    Map<String, dynamic> quota = {
      'hasQuotaLeft': remainingQuota > 0,
      'remainingQuota': remainingQuota,
      'dailyLimit': dailyLimit,
      'isPremium': isPremium,
    };

    // Create a full quota response structure like the API would return
    Map<String, dynamic> fullQuotaData = {'success': true, 'quota': quota};

    // Cache the data
    _cachedQuotaData = fullQuotaData;
    _lastQuotaCheck = DateTime.now();
    _cachedRemainingCount = remainingQuota;
    _cachedPremiumStatus = isPremium;
    _lastSubscriptionCheck = DateTime.now();

    // Update local storage for offline access
    final prefs = await SharedPreferences.getInstance();
    final usedCount = dailyLimit - remainingQuota;
    await prefs.setInt(_messageCountKey, usedCount < 0 ? 0 : usedCount);
    await prefs.setBool(_hasPremiumKey, isPremium);

    // Store structured subscription data for more complete offline access
    final Map<String, dynamic> subscriptionData = {
      'isPremium': isPremium,
      'remainingQuota': remainingQuota,
      'dailyLimit': dailyLimit,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    final serialized = jsonEncode(subscriptionData);
    await prefs.setString("subscription_data", serialized);
    print('Stored full subscription data in local storage');
  }
}
