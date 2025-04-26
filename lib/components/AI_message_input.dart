import 'dart:async';
import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/components/create_expense_form.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/services/initialization_service.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class AIMessageInput extends StatefulWidget {
  final Function(dynamic) onAddMessage;
  final bool isDisabled;
  final int? remainingMessages;
  final int? dailyLimit;
  final bool? isPremium;

  const AIMessageInput({
    super.key,
    required this.onAddMessage,
    this.isDisabled = false,
    this.remainingMessages,
    this.dailyLimit,
    this.isPremium,
  });

  @override
  State<AIMessageInput> createState() => _AIMessageInputState();
}

class _AIMessageInputState extends State<AIMessageInput> {
  final TextEditingController _controller = TextEditingController();
  final SubscriptionService _subscriptionService = SubscriptionService();
  int _remainingMessages = 0;
  int _dailyLimit = 5;
  bool _isPremium = false;
  bool _isLoading = true;
  bool _isShowingHint = false; // Add flag to track dialog state

  // Store the free message limit
  static const int _freeMessageLimit = 5;
  static const int _premiumMessageLimit = 100;

  @override
  void initState() {
    super.initState();

    // Initialize with values from parent if available
    if (widget.remainingMessages != null &&
        widget.dailyLimit != null &&
        widget.isPremium != null) {
      setState(() {
        _remainingMessages = widget.remainingMessages!;
        _dailyLimit = widget.dailyLimit!;
        _isPremium = widget.isPremium!;
        _isLoading = false;
      });
      print(
          "Using quota data from parent: remaining=$_remainingMessages, limit=$_dailyLimit, isPremium=$_isPremium");
    } else {
      // Only call API if parent didn't provide values
      _loadSubscriptionData();
    }

    // Check and show onboarding hint once
    _checkAndShowHint();
  }

  @override
  void didUpdateWidget(AIMessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update state if parent passes new values
    if (widget.remainingMessages != null &&
        widget.dailyLimit != null &&
        widget.isPremium != null) {
      setState(() {
        _remainingMessages = widget.remainingMessages!;
        _dailyLimit = widget.dailyLimit!;
        _isPremium = widget.isPremium!;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Make sure we cleanup if widget is disposed while dialog is showing
    _isShowingHint = false;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      // First try to use cached data
      final cachedData = await _subscriptionService.getCachedQuotaData();
      if (cachedData != null) {
        final quota = cachedData['quota'];
        final remainingQuota = quota['remainingQuota'] as int? ?? 0;
        final dailyLimit = quota['dailyLimit'] as int? ?? _freeMessageLimit;
        final isPremium = quota['isPremium'] as bool? ?? false;

        if (mounted) {
          setState(() {
            _isPremium = isPremium;
            _remainingMessages = remainingQuota;
            _dailyLimit = dailyLimit;
            _isLoading = false;
          });
        }

        print(
            "Using cached quota data: remaining=$_remainingMessages, limit=$_dailyLimit");
      }

      // Then try to get fresh data from server API
      final isPremium = await _subscriptionService.isPremium();
      final remainingMessages =
          await _subscriptionService.getRemainingMessageCount() ?? 0;
      final dailyLimit = await _subscriptionService.getDailyMessageLimit();

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _remainingMessages = remainingMessages;
          _dailyLimit = dailyLimit;
          _isLoading = false;
        });
      }

      print(
          "Quota status: remaining=$_remainingMessages, limit=$_dailyLimit, isPremium=$_isPremium");
    } catch (e) {
      print("Error loading subscription data: $e");

      // Fall back to basic local data if server call fails
      final isPremium = await _subscriptionService.isPremium();
      final messageCount =
          await _subscriptionService.getCurrentMessageCount() ?? 0;
      final limit = isPremium ? _premiumMessageLimit : _freeMessageLimit;

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _remainingMessages = limit - messageCount;
          if (_remainingMessages < 0) _remainingMessages = 0;
          _dailyLimit = limit;
          _isLoading = false;
        });
      }
    }
  }

  // Method to call when a message is sent successfully
  Future<void> _onMessageSent() async {
    // Use cached quota data from the subscription service
    try {
      // Get cached quota data (which was updated by the API response)
      final cachedData = await _subscriptionService.getCachedQuotaData();

      if (cachedData != null && mounted) {
        final quota = cachedData['quota'];
        final remainingQuota = quota['remainingQuota'] as int? ?? 0;
        final dailyLimit = quota['dailyLimit'] as int? ?? _freeMessageLimit;
        final isPremium = quota['isPremium'] as bool? ?? false;

        setState(() {
          _isPremium = isPremium;
          _remainingMessages = remainingQuota;
          _dailyLimit = dailyLimit;
        });

        print(
            "Updated message input from cache: remaining=$remainingQuota, limit=$dailyLimit");
      }
    } catch (e) {
      print("Error updating from cached quota: $e");
    }
  }

  void _onSendPressed() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAddMessage(_controller.text);
      _controller.clear();
      _onMessageSent();
    }
  }

  void _showCreateExpenseForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExpenseForm(
          onExpenseCreated: (Expense expense) {
            // Pass expense directly to onAddMessage
            print(
                "Expense created and being passed to onAddMessage: ${expense.id}");
            widget.onAddMessage(expense);
          },
        ),
      ),
    );
  }

  // Check if hint should be shown and show it only once
  Future<void> _checkAndShowHint() async {
    if (_isShowingHint) return; // Prevent multiple calls

    final shouldShow = await _shouldShowButtonHint();
    if (shouldShow && mounted) {
      _isShowingHint = true;
      // Small delay to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showButtonHint(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Message input area with neumorphic styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            children: [
              // Text input field
              Expanded(
                child: NeumorphicComponents.textField(
                  context: context,
                  controller: _controller,
                  hintText: "Describe your expense (e.g., '250 for lunch')",
                  prefixIcon: Icon(
                    Icons.message_outlined,
                    color: isDark
                        ? NeumorphicColors.darkTextSecondary
                        : NeumorphicColors.lightTextSecondary,
                  ),
                  onSubmitted: (widget.isDisabled || _remainingMessages <= 0)
                      ? null
                      : (value) {
                          _onSendPressed();
                        },
                ),
              ),

              const SizedBox(width: 8), // Reduced spacing from 14 to 8

              // Add expense button (floating action button with tooltip)
              Tooltip(
                message: "Add expense manually",
                preferBelow: false,
                verticalOffset: 20,
                showDuration: const Duration(seconds: 2),
                child: NeumorphicComponents.circularButton(
                  context: context,
                  size: 48,
                  depth: 4.0,
                  color: isDark
                      ? Colors.grey
                          .withOpacity(0.2) // Muted background for dark mode
                      : Colors.grey
                          .withOpacity(0.1), // Muted background for light mode
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: isDark
                            ? Colors
                                .grey[400] // Less vibrant color in dark mode
                            : Colors
                                .grey[600], // Less vibrant color in light mode
                        size: 22,
                      ),
                      Text(
                        "Add",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors
                                  .grey[400] // Less vibrant color in dark mode
                              : Colors.grey[
                                  600], // Less vibrant color in light mode
                        ),
                      ),
                    ],
                  ),
                  onPressed: _showCreateExpenseForm,
                ),
              ),

              const SizedBox(width: 8), // Reduced spacing from 14 to 8

              // Send message button with tooltip
              Tooltip(
                message: "Send expense message",
                preferBelow: false,
                verticalOffset: 20,
                showDuration: const Duration(seconds: 2),
                child: NeumorphicComponents.circularButtonWithBadge(
                  context: context,
                  size: 48,
                  depth: 4.0,
                  // More vibrant color even when disabled
                  color: accentColor.withOpacity(isDark ? 0.4 : 0.2),
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        color: (_remainingMessages <= 0 && !_isPremium)
                            ? accentColor.withOpacity(
                                0.5) // Still colored but dimmed when disabled
                            : accentColor,
                        size: 18,
                      ),
                      Text(
                        "Send",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: (_remainingMessages <= 0 && !_isPremium)
                              ? accentColor.withOpacity(
                                  0.5) // Still colored but dimmed when disabled
                              : accentColor,
                        ),
                      ),
                    ],
                  ),
                  // Only show badge when user isn't premium and has limited messages
                  showBadge: !_isPremium && !_isLoading && _dailyLimit > 0,
                  // Just show the remaining count (simpler)
                  badgeText: '$_remainingMessages',
                  badgeColor: _getMessageCountColor(),
                  isDisabled: _controller.text.trim().isEmpty ||
                      widget.isDisabled ||
                      (_remainingMessages <= 0),
                  onPressed: () {
                    if (!(_controller.text.trim().isEmpty ||
                        widget.isDisabled ||
                        (_remainingMessages <= 0))) {
                      _onSendPressed();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Check if we should show the button hint to new users
  Future<bool> _shouldShowButtonHint() async {
    try {
      // Check if hint is already showing
      if (_isShowingHint) return false;

      // Get stored preference for hint
      final prefs = await SharedPreferences.getInstance();
      final hasSeenHint = prefs.getBool('has_seen_fab_hint') ?? false;

      // Return true if hint has not been seen
      return !hasSeenHint;
    } catch (e) {
      print("Error checking hint preference: $e");
      return false;
    }
  }

  // Mark hint as seen in persistent storage
  Future<void> _markHintAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_fab_hint', true);
      print("Marked onboarding hint as seen");
    } catch (e) {
      print("Error saving hint preference: $e");
    } finally {
      // Always reset the flag
      if (mounted) {
        setState(() {
          _isShowingHint = false;
        });
      }
    }
  }

  // Show a helpful hint about the buttons
  void _showButtonHint(BuildContext context) async {
    // If already showing, don't show it again
    if (!mounted || !_isShowingHint) return;

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: accentColor),
            const SizedBox(width: 10),
            const Text("Quick Expense Entry"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHintItem(
              context,
              icon: Icons.chat_outlined,
              title: "AI-Powered Expense Entry",
              description:
                  "Simply type what you spent money on and let AI figure out the details.",
              example: "\"250 for lunch\"  or  \"1038 face wash\"",
            ),
            const SizedBox(height: 16),
            _buildHintItem(
              context,
              icon: Icons.add_circle_outline,
              title: "Manual Entry",
              description:
                  "Tap the + button to enter expense details manually with categories.",
            ),
            const SizedBox(height: 16),
            _buildHintItem(
              context,
              icon: Icons.send,
              title: "Send Button",
              description:
                  "Tap the send button once you've typed your expense.",
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon:
                Icon(Icons.check_circle_outline, color: accentColor, size: 18),
            label: Text(
              "Got it",
              style: TextStyle(color: accentColor),
            ),
            onPressed: () async {
              // Save that user has seen the hint
              await _markHintAsSeen();

              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ).then((_) {
      // Ensure flag is reset even if dialog is dismissed another way
      if (mounted) {
        setState(() {
          _isShowingHint = false;
        });
      }
    });
  }

  // Helper method to build a consistent hint item
  Widget _buildHintItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    String? example,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final descColor = isDark
        ? NeumorphicColors.darkTextSecondary
        : NeumorphicColors.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: descColor,
                ),
              ),
              if (example != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    "Examples: $example",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: descColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Determine badge color based on remaining messages
  Color _getMessageCountColor() {
    if (_remainingMessages <= 0) {
      return Colors.red;
    } else if (_remainingMessages <= 2) {
      return Colors.orange; // Low count warning
    } else {
      return Colors.green;
    }
  }
}
