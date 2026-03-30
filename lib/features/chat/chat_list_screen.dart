import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../firebase/firebase_service.dart';
import '../../features/authentication/models/user_model.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/routes_manager/routes_manager.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = UserModel.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Messages'),
        body: Center(child: Text('Please log in to view your messages')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Messages'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.getUserConversations(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading messages: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation =
                  conversations[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(
                conversation['participants'] ?? [],
              );
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.id,
                orElse: () => '',
              );

              // We need to fetch the other user's details
              return FutureBuilder<UserModel?>(
                future: FirebaseService.getUserFromFireStore(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return SizedBox.shrink(); // Loading or error, just hide for now
                  }

                  final otherUser = userSnapshot.data!;
                  final isBlocked = currentUser.blockedUserIds.contains(otherUser.id);
                  final lastMessage =
                      conversation['lastMessage'] ?? 'No messages yet';
                  final lastMessageTime =
                      conversation['lastMessageTime'] as Timestamp?;
                  final formattedTime = lastMessageTime != null
                      ? DateFormat(
                          'MMM d, h:mm a',
                        ).format(lastMessageTime.toDate())
                      : '';

                  // Simple check for unread messages could be added here if we had detailed unread counts
                  // For now, we just rely on bold text if the last message wasn't from us?
                  // But the schema doesn't seem to store "unread count" on conversation document easily unless we aggregate.
                  // We'll stick to a simple list.

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    leading: CircleAvatar(
                      radius: 24.r,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Text(
                        otherUser.name.isNotEmpty
                            ? otherUser.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUser.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Row(
                        children: [
                          if (isBlocked) ...[
                            Icon(Icons.block, size: 14.sp, color: Colors.red[300]),
                            SizedBox(width: 4.w),
                          ],
                          Expanded(
                            child: Text(
                              isBlocked ? 'Blocked User' : lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isBlocked ? Colors.red[300] : Colors.grey[600],
                                fontSize: 14.sp,
                                fontStyle: isBlocked ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RoutesManager.chat,
                        arguments: {
                          'otherUserId': otherUser.id,
                          'otherUserName': otherUser.name,
                          'conversationId': conversation['id'],
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
