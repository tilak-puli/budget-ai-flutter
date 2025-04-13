import 'dart:async';
import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/components/create_expense_form.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';

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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      // Try to get quota data from server API
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Text input field
              Expanded(
                child: NeumorphicComponents.textField(
                  context: context,
                  controller: _controller,
                  hintText: "What's the expense?",
                  prefixIcon: Icon(
                    Icons.message_outlined,
                    color: isDark
                        ? NeumorphicColors.darkTextSecondary
                        : NeumorphicColors.lightTextSecondary,
                  ),
                  onSubmitted: (widget.isDisabled ||
                          _remainingMessages <= 0 && !_isPremium)
                      ? null
                      : (value) {
                          _onSendPressed();
                        },
                ),
              ),

              const SizedBox(width: 12),

              // Add expense button (floating action button)
              NeumorphicComponents.circularButton(
                context: context,
                size: 48,
                depth: 4.0,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(isDark ? 0.8 : 0.2),
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                onPressed: _showCreateExpenseForm,
              ),

              const SizedBox(width: 12),

              // Send message button
              NeumorphicComponents.circularButtonWithBadge(
                context: context,
                size: 48,
                depth: 4.0,
                color: (_remainingMessages <= 0 && !_isPremium)
                    ? Colors.grey.withOpacity(0.3)
                    : accentColor.withOpacity(isDark ? 0.3 : 0.1),
                icon: Icon(
                  Icons.send,
                  color: (_remainingMessages <= 0 && !_isPremium)
                      ? Colors.grey
                      : accentColor,
                  size: 20,
                ),
                showBadge: !_isPremium && !_isLoading,
                badgeText: '$_remainingMessages/$_dailyLimit',
                badgeColor: _remainingMessages > 0 ? Colors.green : Colors.red,
                onPressed: (_controller.text.trim().isEmpty ||
                        widget.isDisabled ||
                        (_remainingMessages <= 0 && !_isPremium))
                    ? () {} // Provide an empty function instead of null
                    : () {
                        _onSendPressed();
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
