import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/repositories/ride_repository.dart';

class ChatMessageItem {
  final String text;
  final bool isUser;
  final String timestamp;
  final bool isEscalated;
  final String? ticketId;

  ChatMessageItem({required this.text, required this.isUser, required this.timestamp, this.isEscalated = false, this.ticketId});
}

class AiChatScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const AiChatScreen({super.key, this.initialQuery});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessageItem> _messages = [
    ChatMessageItem(
      text: 'Hello! I am Rido 24/7 Support Assistant. How can I help you today? Select a common topic or type your question.',
      isUser: false,
      timestamp: 'Just now',
    ),
  ];

  List<String> _quickSuggestions = [
    'I forgot my wallet in the cab',
    'Overcharged on my last ride',
    'Driver was rude to me',
    'Please connect me to a human executive',
  ];

  bool _isSending = false;
  bool _isEscalated = false;
  String? _escalatedTicketId;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now().format(context);

    setState(() {
      _messages.add(ChatMessageItem(text: text, isUser: true, timestamp: now));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final repo = ref.read(rideRepositoryProvider);
    final response = await repo.sendAiChatMessage(text);

    if (mounted) {
      setState(() => _isSending = false);
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _messages.add(
            ChatMessageItem(
              text: data.reply,
              isUser: false,
              timestamp: TimeOfDay.now().format(context),
              isEscalated: data.escalatedToHuman,
              ticketId: data.ticketId,
            ),
          );
          if (data.escalatedToHuman) {
            _isEscalated = true;
            _escalatedTicketId = data.ticketId;
          }
          if (data.quickSuggestions.isNotEmpty) {
            _quickSuggestions = data.quickSuggestions;
          }
        });
        _scrollToBottom();
      } else {
        AppSnackBar.showError(context, title: 'Chat Error', message: response.message ?? 'Failed to send message.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const Gap(10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rido AI Assistant',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '24/7 Instant Support',
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Escalation Banner if triggered
            if (_isEscalated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent, color: Colors.amber, size: 24),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escalated to Human Executive (${_escalatedTicketId ?? "Support Ticket"})',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                          ),
                          const Text(
                            'A live support executive is reviewing your request.',
                            style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildBubble(msg);
                },
              ),
            ),

            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    Gap(8),
                    Text('Rido AI is typing...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),

            // Quick Suggestion Chips
            if (_quickSuggestions.isNotEmpty && !_isSending)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _quickSuggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        label: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _sendMessage(suggestion),
                      ),
                    );
                  },
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _sendMessage(val),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessageItem msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text, style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 14, height: 1.3)),
            const Gap(4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.timestamp, style: TextStyle(color: isUser ? Colors.white70 : AppColors.textSecondary, fontSize: 10)),
                if (msg.isEscalated) ...[
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      'Escalated',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
