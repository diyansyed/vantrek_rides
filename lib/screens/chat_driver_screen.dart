import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
  });
}


final chatMessagesProvider =
StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
      (ref) => ChatMessagesNotifier(),
);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier()
      : super([
    ChatMessage(
      id: '1',
      text: 'Hello! I\'m on my way to pick you up.',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: true,
    ),
    ChatMessage(
      id: '2',
      text: 'Great! How long will it take?',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      isRead: true,
    ),
    ChatMessage(
      id: '3',
      text: 'I\'ll be there in about 5 minutes.',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isRead: true,
    ),
  ]);

  void sendMessage(String text) {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
      isRead: false,
    );

    state = [...state, newMessage];

    Future.delayed(const Duration(seconds: 2), () {
      final responses = [
        'Got it, thanks!',
        'Okay, see you soon!',
        'No problem!',
        'Alright, on my way!',
      ];

      final response = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responses[DateTime.now().second % responses.length],
        isMe: false,
        timestamp: DateTime.now(),
        isRead: false,
      );

      state = [...state, response];
    });
  }

  void markAllAsRead() {
    state = state
        .map((msg) => ChatMessage(
      id: msg.id,
      text: msg.text,
      isMe: msg.isMe,
      timestamp: msg.timestamp,
      isRead: true,
    ))
        .toList();
  }
}

class ChatWithDriverScreen extends ConsumerStatefulWidget {
  const ChatWithDriverScreen({super.key});

  @override
  ConsumerState<ChatWithDriverScreen> createState() =>
      _ChatWithDriverScreenState();
}

class _ChatWithDriverScreenState extends ConsumerState<ChatWithDriverScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).markAllAsRead();
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    ref.read(chatMessagesProvider.notifier).sendMessage(
      _messageController.text.trim(),
    );

    _messageController.clear();

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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: Text(
                'J',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John Smith',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF2196F3)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling driver...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final showAvatar = index == messages.length - 1 ||
                    messages[index + 1].isMe != message.isMe;

                return _buildMessageBubble(message, showAvatar);
              },
            ),
          ),

          _buildQuickReplies(),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Text(
                'J',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (!message.isMe)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe
                    ? const Color(0xFF2196F3)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                  Radius.circular(message.isMe || !showAvatar ? 16 : 4),
                  bottomRight:
                  Radius.circular(!message.isMe || !showAvatar ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isMe
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.lightBlue[200]
                              : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe && showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.green[700],
              ),
            ),
          ] else if (message.isMe)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      'I\'m here',
      'Running 5 min late',
      'Where are you?',
      'Thanks!',
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              ref
                  .read(chatMessagesProvider.notifier)
                  .sendMessage(quickReplies[index]);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2196F3)),
              ),
              child: Text(
                quickReplies[index],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attachments coming soon!'),
                            backgroundColor: Color(0xFF2196F3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 22),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your driver',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Driver'),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Issue'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report feature coming soon'),
                    backgroundColor: Color(0xFF2196F3),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Driver'),
        content: const Text(
          'Are you sure you want to block this driver? You won\'t be able to message them anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver blocked'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}