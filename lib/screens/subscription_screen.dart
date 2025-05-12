import 'package:budget_ai/services/app_init_service.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:budget_ai/theme/neumorphic_box.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:intl/intl.dart';
import 'package:budget_ai/components/common_app_bar.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AppInitService _appInitService = AppInitService();
  bool _isLoading = true;
  bool _isRestoring = false;
  bool _isPremium = false;
  int _remainingMessages = 0;
  int _dailyMessageLimit = 5;
  DateTime? _lastResetDate;
  DateTime? _expiryDate;
  bool? _autoRenewing;
  String? _purchaseToken;
  List<ProductDetails> _products = [];

  // Message quotas
  static const int _freeMessageLimit = 5;
  static const int _premiumMessageLimit = 100;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      // Use the app init service to get quota data if available
      final initData = await _appInitService.fetchAppInitData();

      if (initData != null) {
        // Get quota from unified API
        final quota = initData.quota;
        final isPremium = quota.isPremium;
        final remainingMessages = quota.remainingQuota;
        final dailyLimit = quota.dailyLimit;

        // Initialize available products
        await _subscriptionService.initializeSubscriptions();
        final products = await _subscriptionService.getAvailableSubscriptions();

        if (mounted) {
          setState(() {
            _isPremium = isPremium;
            _remainingMessages = remainingMessages;
            _dailyMessageLimit = dailyLimit;
            _products = products;
            _isLoading = false;
          });
        }
        return;
      }

      // Fall back to subscription service if app init data is not available
      // Check current subscription status
      final isPremium = await _subscriptionService.isPremium();

      // Get quota information from server
      final quotaData = await _subscriptionService.getMessageQuota();
      final quota = quotaData['quota'];
      int remainingMessages = 0;
      int dailyLimit = _freeMessageLimit;

      if (quota != null) {
        remainingMessages = quota['remainingQuota'] ?? 0;
        dailyLimit = quota['dailyLimit'] ??
            (isPremium ? _premiumMessageLimit : _freeMessageLimit);
      }

      // Initialize available products
      await _subscriptionService.initializeSubscriptions();
      final products = await _subscriptionService.getAvailableSubscriptions();

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _remainingMessages = remainingMessages;
          _dailyMessageLimit = dailyLimit;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading subscription data: $e');

      // Fall back to local data
      try {
        // Check current subscription status locally
        final isPremium = await _subscriptionService.isPremium();

        // Get remaining messages
        final remainingCount =
            await _subscriptionService.getRemainingMessageCount() ?? 0;
        final limit = isPremium ? _premiumMessageLimit : _freeMessageLimit;

        // Initialize available products
        await _subscriptionService.initializeSubscriptions();
        final products = await _subscriptionService.getAvailableSubscriptions();

        if (mounted) {
          setState(() {
            _isPremium = isPremium;
            _remainingMessages = remainingCount;
            _dailyMessageLimit = limit;
            _products = products;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading local subscription data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _purchaseSubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

    // Refresh subscription status after purchase attempt
    await _loadSubscriptionData();
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
    });

    await _subscriptionService.restorePurchases();

    // Wait a moment for the purchase stream to process the restored purchases
    await Future.delayed(const Duration(seconds: 2));

    // Reload subscription data
    await _loadSubscriptionData();

    setState(() {
      _isRestoring = false;
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored')),
      );
    }
  }

  // Helper function to clean product title
  String _cleanProductTitle(String title) {
    // Get everything before the first parenthesis and trim whitespace
    return title.split('(')[0].trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Premium Subscription',
        actions: [
          if (_isRestoring)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _restorePurchases,
              child: const Text(
                'Restore',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Status
                    Container(
                      decoration: NeumorphicBox.cardDecoration(
                        context: context,
                        borderRadius: 16.0,
                        depth: 5.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPremium ? 'Premium Account' : 'Free Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _isPremium ? Colors.amber : null),
                            ),
                            const SizedBox(height: 8),
                            if (!_isPremium) ...[
                              Text(
                                'You have $_remainingMessages/${_dailyMessageLimit} free messages remaining today.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Upgrade to Premium for unlimited messages!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Text(
                                'You have $_remainingMessages/${_dailyMessageLimit} premium messages remaining.',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              if (_expiryDate != null) ...[
                                Text(
                                  'Subscription expires: $_expiryDate',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Auto-renewing: ${_autoRenewing == true ? 'Yes' : 'No'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Features Section
                    Text(
                      'Premium Features',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(Icons.message, '100 AI Messages per day'),
                    _buildFeatureItem(Icons.analytics_outlined,
                        'AI-Powered Weekly Reports [coming soon]'),
                    _buildFeatureItem(Icons.lightbulb_outline,
                        'Smart Savings Suggestions [coming soon]'),
                    _buildFeatureItem(
                        Icons.file_download, 'Data Export [coming soon]'),

                    const SizedBox(height: 24),

                    // Subscription Options
                    if (!_isPremium) ...[
                      Text(
                        'Subscription Options',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (_products.isEmpty)
                        Container(
                          decoration: NeumorphicBox.cardDecoration(
                            context: context,
                            borderRadius: 16.0,
                            depth: 3.0,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                                'No subscription options available at the moment.'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: NeumorphicBox.cardDecoration(
                                context: context,
                                borderRadius: 12.0,
                                depth: 4.0,
                              ),
                              child: ListTile(
                                title: Text(_cleanProductTitle(product.title)),
                                subtitle: product.description.isNotEmpty
                                    ? Text(product.description)
                                    : null,
                                trailing: Container(
                                  decoration: NeumorphicBox.buttonDecoration(
                                    context: context,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: 8.0,
                                  ),
                                  child: InkWell(
                                    onTap: () => _purchaseSubscription(product),
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        product.price,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
