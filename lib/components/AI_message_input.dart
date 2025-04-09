import 'dart:async';
import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:flutter/material.dart';

class AIMessageInput extends StatefulWidget {
  final void Function(dynamic userMessage) addExpense;

  final bool? disabled;

  const AIMessageInput(this.addExpense, {super.key, this.disabled});

  @override
  State<AIMessageInput> createState() => _AIMessageInputState();
}

class _AIMessageInputState extends State<AIMessageInput> {
  late TextEditingController _controller;
  final SubscriptionService _subscriptionService = SubscriptionService();
  int _remainingMessages = 0;
  bool _isPremium = false;
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Store the free message limit
  static const int _freeMessageLimit = 5;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadSubscriptionData();

    // Set up a timer to refresh the count every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadSubscriptionData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    final isPremium = await _subscriptionService.isPremium();
    final messageCount =
        await _subscriptionService.getRemainingMessageCount() ?? 0;

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _remainingMessages = _freeMessageLimit - messageCount;
        if (_remainingMessages < 0) _remainingMessages = 0;
        _isLoading = false;
      });
    }
  }

  // Method to call when a message is sent successfully
  Future<void> _onMessageSent() async {
    if (!_isPremium) {
      // Wait a moment for the backend to process the message
      await Future.delayed(const Duration(milliseconds: 1000));

      // Reload the actual data - don't change the UI optimistically
      await _loadSubscriptionData();

      print("Message input refreshed count after send");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isPremium && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              _remainingMessages > 0
                  ? '$_remainingMessages free messages remaining today'
                  : 'You\'ve reached your daily limit',
              style: TextStyle(
                fontSize: 12,
                color: _remainingMessages > 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(
          height: 50,
          width: MediaQuery.of(context).size.width - 20,
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                autofocus: false,
                controller: _controller,
                onSubmitted: (widget.disabled == true ||
                        _remainingMessages <= 0 && !_isPremium)
                    ? null
                    : (value) async {
                        final text = value.trim();
                        if (text.isNotEmpty) {
                          widget.addExpense(text);
                          _controller.clear();
                          _onMessageSent();
                        }
                      },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'What\'s the expense?',
                  filled: true,
                  fillColor: Colors.white,
                ),
              )),
              Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Container(
                  height: 50,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (_remainingMessages <= 0 && !_isPremium)
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        color: Colors.white,
                        onPressed: (widget.disabled == true ||
                                _remainingMessages <= 0 && !_isPremium)
                            ? null
                            : () async {
                                final text = _controller.text.trim();
                                if (text.isNotEmpty) {
                                  widget.addExpense(text);
                                  _controller.clear();
                                  _onMessageSent();
                                }
                              },
                        icon: const Icon(Icons.send),
                      ),
                      if (!_isPremium && !_isLoading)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: _remainingMessages > 0
                                  ? Colors.green
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_remainingMessages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
