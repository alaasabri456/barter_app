import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/chat/models/chat_message.dart';
import '../../firebase/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String? tradeId; // Optional - only present when opened from trade
  final String otherUserId;
  final String otherUserName;
  final String? conversationId; // Optional - will be generated if not provided
  final String? productTitle; // Optional - product context
  final String? productId; // Optional - product context

  const ChatScreen({
    super.key,
    this.tradeId,
    required this.otherUserId,
    required this.otherUserName,
    this.conversationId,
    this.productTitle,
    this.productId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late String _conversationId;

  @override
  void initState() {
    super.initState();
    // Generate conversation ID if not provided
    final currentUserId = UserModel.currentUser?.id ?? '';
    _conversationId =
        widget.conversationId ??
        FirebaseService.getConversationId(currentUserId, widget.otherUserId);

    // Initialize conversation and mark messages as read
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final currentUserId = UserModel.currentUser?.id;
    if (currentUserId != null) {
      // Create conversation if it doesn't exist
      await FirebaseService.getOrCreateConversation(
        currentUserId,
        widget.otherUserId,
      );
      // Mark messages as read
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    final currentUser = UserModel.currentUser;
    if (currentUser != null) {
      await FirebaseService.markConversationMessagesAsRead(
        _conversationId,
        currentUser.id,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = UserModel.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _conversationId,
        tradeId: widget.tradeId, // Optional - only set if opened from trade
        senderId: currentUser.id,
        text: text,
        timestamp: DateTime.now(),
      );

      await FirebaseService.sendConversationMessage(message, _conversationId);
      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            // Show trade badge if opened from trade
            if (widget.tradeId != null)
              Container(
                margin: EdgeInsets.only(top: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Trade #${widget.tradeId!.substring(0, 6)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            // Show product badge if opened from product details
            else if (widget.productTitle != null)
              Container(
                margin: EdgeInsets.only(top: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${widget.productTitle!}${widget.productId != null ? " #${widget.productId!.substring(0, 6)}" : ""}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: FirebaseService.getConversationMessages(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64.w,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.id;
                    final showDate =
                        index == messages.length - 1 ||
                        _shouldShowDate(messages[index + 1], message);

                    return Column(
                      children: [
                        if (showDate) _buildDateHeader(message.timestamp),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  bool _shouldShowDate(ChatMessage prev, ChatMessage curr) {
    final prevDate = prev.timestamp;
    final currDate = curr.timestamp;
    return prevDate.year != currDate.year ||
        prevDate.month != currDate.month ||
        prevDate.day != currDate.day;
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8.h,
          left: isMe ? 64.w : 0,
          right: isMe ? 0 : 64.w,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Colors.grey[300], // Darker grey for better visibility
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
            bottomRight: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    fontSize: 10.sp,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12.w,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
