import 'package:coin_master_ai/components/theme_toggle.dart';
import 'package:coin_master_ai/screens/budget_screen.dart';
import 'package:coin_master_ai/screens/subscription_screen.dart';
import 'package:coin_master_ai/services/subscription_service.dart';
import 'package:coin_master_ai/services/app_init_service.dart';
import 'package:coin_master_ai/theme/index.dart';
import 'package:coin_master_ai/constants/config_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:coin_master_ai/state/expense_store.dart';
import 'package:coin_master_ai/models/expense_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coin_master_ai/components/common_app_bar.dart';
import 'dart:convert';
import 'package:coin_master_ai/screens/contact_us_screen.dart';

class CustomProfileScreen extends StatefulWidget {
  const CustomProfileScreen({super.key});

  @override
  State<CustomProfileScreen> createState() => _CustomProfileScreenState();
}

class _CustomProfileScreenState extends State<CustomProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AppInitService _appInitService = AppInitService();
  bool _isPremium = false;
  bool _isLoading = true;

  // Default Discord URL as fallback
  String _discordUrl = 'https://discord.gg/DghUAx8387';

  @override
  void initState() {
    super.initState();
    // Get the cached status immediately
    _isPremium = _subscriptionService.getCachedPremiumStatus() ?? false;
    // Initialize data
    _initData();
  }

  // Function to get config data from local storage
  Future<Map<String, dynamic>?> getConfigDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString("config_data");

      if (storedData == null || storedData.isEmpty) {
        return null;
      }

      // Parse the JSON
      final configData = jsonDecode(storedData) as Map<String, dynamic>;
      return configData['config'] as Map<String, dynamic>;
    } catch (e) {
      print("ERROR RETRIEVING CONFIG DATA: $e");
      return null;
    }
  }

  Future<void> _initData() async {
    try {
      // First try to get config from local storage
      final storedConfig = await getConfigDataFromStorage();
      if (storedConfig != null &&
          storedConfig.containsKey(ConfigKeys.discordUrl)) {
        setState(() {
          _discordUrl = storedConfig[ConfigKeys.discordUrl] as String;
          _isLoading = false;
        });
        print('Using Discord URL from local storage: $_discordUrl');
      } else {
        // If not in local storage, try to get from app init service cached data
        final initData = _appInitService.cachedData;
        if (initData != null &&
            initData.config.containsKey(ConfigKeys.discordUrl)) {
          setState(() {
            _discordUrl = initData.config[ConfigKeys.discordUrl] as String;
            _isLoading = false;
          });
          print('Using Discord URL from cached init data: $_discordUrl');
        } else {
          // As a last resort, try to get fresh data
          final freshData = await _appInitService.fetchAppInitData();
          if (freshData != null &&
              freshData.config.containsKey(ConfigKeys.discordUrl)) {
            setState(() {
              _discordUrl = freshData.config[ConfigKeys.discordUrl] as String;
              _isLoading = false;
            });
            print('Using Discord URL from fresh config: $_discordUrl');
          } else {
            // Use default if not available anywhere
            setState(() {
              _isLoading = false;
            });
            print('Using default Discord URL: $_discordUrl');
          }
        }
      }

      // Update subscription status
      await _updateSubscriptionIfNeeded();
    } catch (e) {
      print('Error initializing profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
    try {
      print("\n------- SIGNING OUT -------");
      // Clear local storage first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("expenses");
      await prefs.remove("subscription_data");
      await prefs.remove("config_data");
      await prefs.remove("app_init_data");
      print("Cleared local storage");

      // Clear expense store if available
      if (mounted) {
        final expenseStore = Provider.of<ExpenseStore>(context, listen: false);
        expenseStore.setExpenses(Expenses(List.empty()));
        print("Reset expense store");
      }

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      print("Signed out from Firebase");

      if (mounted) {
        Navigator.of(context).pop();
      }
      print("------- SIGN OUT COMPLETE -------\n");
    } catch (e) {
      print("Error during sign out: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
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
            Icon(icon, size: 24.0, color: iconColor ?? defaultIconColor),
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

  // Method to launch Discord URL
  Future<void> _launchDiscord() async {
    final Uri url = Uri.parse(_discordUrl);

    print('Attempting to launch Discord URL: $_discordUrl');

    try {
      // Try basic URL launch with universal option first
      print('Attempting with universal link mode');
      bool launched = await launchUrl(url, mode: LaunchMode.platformDefault);

      print('Universal link launch result: $launched');

      if (!launched) {
        print('URL launch returned false - could not launch');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open Discord community. Please try again later.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('ERROR launching Discord URL: $e');
      print('Stack trace: ${StackTrace.current}');

      // Fallback to a more basic approach if we got a platform exception
      if (e.toString().contains('PlatformException') ||
          e.toString().contains('channel-error')) {
        print('Trying fallback with just canLaunchUrl + launchUrl');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
            print('Fallback launch successful');
          } else {
            print('canLaunchUrl returned false');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cannot open Discord. Please try manually visiting $_discordUrl',
                  ),
                ),
              );
            }
          }
        } catch (fallbackError) {
          print('Fallback error: $fallbackError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening Discord: $fallbackError')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening Discord community: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeService = ThemeProvider.watch(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground;

    return Scaffold(
      appBar: CommonAppBar(title: 'Profile'),
      body:
          _isLoading
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
                            backgroundImage:
                                user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null,
                            child:
                                user?.photoURL == null
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color:
                              isDark
                                  ? NeumorphicColors.darkTextPrimary
                                  : NeumorphicColors.lightTextPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // User email
                      Text(
                        user?.email ?? 'tilakpuli15@gmail.com',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              isDark
                                  ? NeumorphicColors.darkTextSecondary
                                  : NeumorphicColors.lightTextSecondary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Premium status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _isPremium
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
                              color:
                                  _isPremium
                                      ? Colors.white
                                      : isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isPremium ? 'Premium User' : 'Free User',
                              style: TextStyle(
                                color:
                                    _isPremium
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Divider(
                              color:
                                  isDark
                                      ? NeumorphicColors.darkTextSecondary
                                          .withOpacity(0.3)
                                      : NeumorphicColors.lightTextSecondary
                                          .withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Budget management option
                      _buildSettingOption(
                        context: context,
                        icon: Icons.account_balance_wallet,
                        title: 'Budget Management',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BudgetScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

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

                      // Discord Support option
                      _buildSettingOption(
                        context: context,
                        icon: Icons.forum,
                        title: 'Join Discord Community',
                        onTap: _launchDiscord,
                        iconColor: const Color(
                          0xFF5865F2,
                        ), // Discord brand color
                      ),

                      const SizedBox(height: 12),

                      // Contact Us option
                      _buildSettingOption(
                        context: context,
                        icon: Icons.email,
                        title: 'Contact Us',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsScreen(),
                            ),
                          );
                        },
                        iconColor: Theme.of(context).colorScheme.primary,
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
