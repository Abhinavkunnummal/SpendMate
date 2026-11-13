import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Hello Kunal! I'm your SpendMate AI Financial Advisor. I'm connected to your accounts, active trips, and budgets. How can I assist you today?",
      'time': '10:00 AM',
    },
    {
      'isUser': true,
      'text': 'How much did our group spend on the Manali trip so far, and who owes me?',
      'time': '10:01 AM',
    },
    {
      'isUser': false,
      'text': "Your group has spent ₹48,200 across 5 shared expenses in Manali. Because of your contributions, your net standing is +₹960 (you are owed money!).\n\n• Rohan owes you ₹480\n• Pooja owes you ₹480\n\nWould you like me to generate a UPI settlement link or send a gentle reminder?",
      'time': '10:01 AM',
    },
  ];

  final List<String> _suggestions = [
    'How much can I spend safely this week?',
    'Where did most of my money go in October?',
    'Can I hit my Japan trip savings goal on time?',
  ];

  void _sendMessage([String? preset]) {
    final text = preset ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': 'Just now',
      });
      if (preset == null) _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': "Based on your current burn rate of ₹1,405/day and ₹16,000 remaining in your November budget, you have a safe spending capacity of approximately ₹888/day for the next 18 days. You are on track to save ₹1,42,850 this month!",
          'time': 'Just now',
        });
      });
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.purple, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpendMate AI', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                Text('Online · Financial Advisor', style: AppTypography.bodySmall(AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary
                          : (isDark ? AppColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isUser ? Colors.white : primaryTextColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            color: isUser ? Colors.white70 : secondaryTextColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(s),
                    onPressed: () => _sendMessage(s),
                    backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    labelStyle: TextStyle(fontSize: 12, color: primaryTextColor),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about your money or trips...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
