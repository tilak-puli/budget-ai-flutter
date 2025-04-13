import 'package:budget_ai/components/theme_toggle.dart';
import 'package:budget_ai/screens/subscription_screen.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomProfileScreen extends StatefulWidget {
  const CustomProfileScreen({super.key});

  @override
  State<CustomProfileScreen> createState() => _CustomProfileScreenState();
}

class _CustomProfileScreenState extends State<CustomProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    final isPremium = await _subscriptionService.isPremium();

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _isLoading = false;
      });
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    ).then((_) => _loadSubscriptionData());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeService = ThemeProvider.watch(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(
          color: isDark
              ? NeumorphicColors.darkTextPrimary
              : NeumorphicColors.lightTextPrimary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Profile picture
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Text(
                                  user?.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(fontSize: 40),
                                )
                              : null,
                        ),
                        if (_isPremium)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // User name
                    Text(
                      user?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    const SizedBox(height: 8),

                    // User email
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 8),

                    // Premium status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isPremium ? Colors.amber : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPremium
                                ? Icons.workspace_premium
                                : Icons.workspace_premium_outlined,
                            size: 16,
                            color: _isPremium
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPremium ? 'Premium User' : 'Free User',
                            style: TextStyle(
                              color: _isPremium
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Settings section divider
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? NeumorphicColors.darkTextSecondary
                                    .withOpacity(0.3)
                                : NeumorphicColors.lightTextSecondary
                                    .withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Theme toggle setting
                    NeumorphicComponents.card(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: isDark
                                  ? NeumorphicColors.darkAccent
                                  : NeumorphicColors.lightAccent,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Dark Mode',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ThemeToggleSwitch(
                              isDarkMode: themeService.isDarkMode,
                              onToggle: () => themeService.toggleTheme(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subscription button
                    if (!_isPremium)
                      NeumorphicComponents.button(
                        context: context,
                        onPressed: _navigateToSubscription,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.diamond_outlined),
                            const SizedBox(width: 8),
                            Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Manage subscription button for premium users
                    if (_isPremium)
                      OutlinedButton.icon(
                        onPressed: _navigateToSubscription,
                        icon: const Icon(Icons.settings),
                        label: const Text('Manage Subscription'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Sign out button
                    NeumorphicComponents.button(
                      context: context,
                      color: Colors.red.withOpacity(0.1),
                      onPressed: _signOut,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
