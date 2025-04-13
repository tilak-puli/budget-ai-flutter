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
    // Get the cached status immediately
    _isPremium = _subscriptionService.getCachedPremiumStatus() ?? false;
    _isLoading = false;
    // Then update in background if needed
    _updateSubscriptionIfNeeded();
  }

  Future<void> _updateSubscriptionIfNeeded() async {
    try {
      final isPremium = await _subscriptionService.isPremium();
      if (mounted && isPremium != _isPremium) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      print('Error updating subscription status: $e');
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
    ).then((_) => _updateSubscriptionIfNeeded());
  }

  /// Creates a standardized setting option item
  Widget _buildSettingOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    Color? backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    return NeumorphicComponents.card(
      context: context,
      color: backgroundColor,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.0,
              color: iconColor ?? defaultIconColor,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
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
                      user?.displayName ?? 'Tilak Puli',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDark
                                    ? NeumorphicColors.darkTextPrimary
                                    : NeumorphicColors.lightTextPrimary,
                              ),
                    ),

                    const SizedBox(height: 8),

                    // User email
                    Text(
                      user?.email ?? 'tilakpuli15@gmail.com',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? NeumorphicColors.darkTextSecondary
                                : NeumorphicColors.lightTextSecondary,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Premium status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isPremium
                            ? Colors.amber
                            : isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
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
                                : isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPremium ? 'Premium User' : 'Free User',
                            style: TextStyle(
                              color: _isPremium
                                  ? Colors.white
                                  : isDark
                                      ? Colors.grey.shade300
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

                    // Dark mode toggle
                    _buildSettingOption(
                      context: context,
                      icon: isDark ? Icons.light_mode : Icons.dark_mode,
                      title: 'Dark Mode',
                      onTap: () {},
                      trailing: ThemeToggleSwitch(
                        isDarkMode: isDark,
                        onToggle: () => themeService.toggleTheme(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Upgrade to Premium option for free users
                    if (!_isPremium)
                      _buildSettingOption(
                        context: context,
                        icon: Icons.diamond_outlined,
                        title: 'Upgrade to Premium',
                        onTap: _navigateToSubscription,
                        iconColor: Colors.amber,
                      ),

                    // Manage subscription option for premium users
                    if (_isPremium)
                      _buildSettingOption(
                        context: context,
                        icon: Icons.settings_applications,
                        title: 'Manage Subscription',
                        onTap: _navigateToSubscription,
                      ),

                    const SizedBox(height: 12),

                    // Sign out option
                    _buildSettingOption(
                      context: context,
                      icon: Icons.logout,
                      title: 'Sign Out',
                      onTap: _signOut,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      backgroundColor: Colors.red.withOpacity(0.05),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
