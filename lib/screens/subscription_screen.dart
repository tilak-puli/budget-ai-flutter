import 'package:budget_ai/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  int _remainingMessages = 0;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isRestoring = false;

  // Daily message limit
  static const int _freeMessageLimit = 5;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    // Check current subscription status
    final isPremium = await _subscriptionService.isPremium();

    // Get remaining free messages count
    final prefs = await _subscriptionService.getRemainingMessageCount();

    // Initialize available products
    await _subscriptionService.initializeSubscriptions();
    final products = await _subscriptionService.getAvailableSubscriptions();

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _remainingMessages = _freeMessageLimit - (prefs ?? 0);
        _products = products;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                    Card(
                      elevation: 4,
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
                                'You have $_remainingMessages free messages remaining today.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Upgrade to Premium for unlimited messages!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              const Text(
                                'You have unlimited messages and full access to all features!',
                                style: TextStyle(fontSize: 16),
                              ),
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
                    _buildFeatureItem(Icons.message, 'Unlimited AI Messages'),
                    _buildFeatureItem(
                        Icons.analytics_outlined, 'AI-Powered Weekly Reports'),
                    _buildFeatureItem(
                        Icons.lightbulb_outline, 'Smart Savings Suggestions'),
                    _buildFeatureItem(Icons.speed, 'Priority Processing'),
                    _buildFeatureItem(Icons.file_download, 'Data Export'),

                    const SizedBox(height: 24),

                    // Subscription Options
                    if (!_isPremium) ...[
                      Text(
                        'Subscription Options',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (_products.isEmpty)
                        const Card(
                          child: Padding(
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(product.title),
                                subtitle: Text(product.description),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _purchaseSubscription(product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  child: Text(product.price),
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
