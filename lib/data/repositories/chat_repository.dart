// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/authentication/models/user_model.dart';
import '../../features/chat/models/chat_message.dart';
import '../../features/notifications/models/notification_model.dart';
import '../services/notification_service.dart';

/// Repository responsible for all chat / messaging operations.
class ChatRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  ChatRepository({
    FirebaseFirestore? firestore,
    required NotificationService notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService;

  // ─── Collection helpers ───────────────────────────────────────────────

  CollectionReference<UserModel> _getUsersCollection() {
    return _firestore.collection("Users").withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  CollectionReference _getTradesCollection() {
    return _firestore.collection("Trades");
  }

  CollectionReference _getConversationsCollection() {
    return _firestore.collection('Conversations');
  }

  // ─── Trade-based chat ─────────────────────────────────────────────────

  Future<void> sendMessage(ChatMessage message) async {
    try {
      final tradesCollection = _getTradesCollection();
      final messagesCollection =
          tradesCollection.doc(message.tradeId).collection('messages');

      await messagesCollection.doc(message.id).set(message.toJson());

      await tradesCollection.doc(message.tradeId).update({
        'lastMessage': message.imageUrl != null ? '📷 Photo' : message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': message.senderId,
        'hasUnreadMessages': true,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<ChatMessage>> getMessages(String tradeId) {
    final tradesCollection = _getTradesCollection();
    return tradesCollection
        .doc(tradeId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> markMessagesAsRead(String tradeId, String userId) async {
    try {
      final tradesCollection = _getTradesCollection();
      final messagesCollection =
          tradesCollection.doc(tradeId).collection('messages');

      final unreadMessages = await messagesCollection
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      await tradesCollection.doc(tradeId).update({'hasUnreadMessages': false});
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // ─── Conversation-based chat ──────────────────────────────────────────

  /// Generate a consistent conversation ID from two user IDs.
  String getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'conversation_${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      final conversationId = getConversationId(userId1, userId2);
      final conversationsCollection = _getConversationsCollection();
      final conversationDoc = conversationsCollection.doc(conversationId);

      final snapshot = await conversationDoc.get();

      if (!snapshot.exists) {
        await conversationDoc.set({
          'id': conversationId,
          'participants': [userId1, userId2],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
          'lastMessageSenderId': null,
        });
      }
    } catch (e) {
      print('Failed to get or create conversation: $e');
      throw Exception('Failed to initialize conversation: $e');
    }
  }

  Stream<QuerySnapshot> getUserConversations(String userId) {
    return _getConversationsCollection()
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> sendConversationMessage(
    ChatMessage message,
    String conversationId,
  ) async {
    try {
      final conversationsCollection = _getConversationsCollection();

      // Determine recipient ID
      final userIds =
          conversationId.replaceFirst('conversation_', '').split('_');
      final recipientId = userIds.firstWhere((id) => id != message.senderId,
          orElse: () => '');

      // Check for blocking
      if (recipientId.isNotEmpty) {
        final sender = UserModel.currentUser;
        if (sender != null && sender.blockedUserIds.contains(recipientId)) {
          throw Exception('Cannot send message. You have blocked this user.');
        }

        final recipientSnapshot =
            await _getUsersCollection().doc(recipientId).get();
        final recipient = recipientSnapshot.data();
        if (recipient != null &&
            recipient.blockedUserIds.contains(message.senderId)) {
          throw Exception(
              'Cannot send message. The recipient has blocked you.');
        }
      }

      final messagesCollection =
          conversationsCollection.doc(conversationId).collection('messages');

      await messagesCollection.doc(message.id).set(message.toJson());

      // Update conversation with last message info
      final updateData = <String, dynamic>{
        'lastMessage': message.imageUrl != null ? '📷 Photo' : message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (recipientId.isNotEmpty) {
        updateData['unreadCount_$recipientId'] = FieldValue.increment(1);
      }

      await conversationsCollection.doc(conversationId).update(updateData);

      // Send push notification to the recipient
      if (recipientId.isNotEmpty) {
        final senderName = UserModel.currentUser?.name ?? 'Someone';

        await _notificationService.sendLocalizedNotification(
          recipientId: recipientId,
          titleKey: 'newMessageTitle',
          bodyKey: 'newMessageBody',
          type: NotificationType.chatMessage,
          bodyArgs: {
            'sender': senderName,
            'message':
                message.imageUrl != null ? '📷 Photo' : (message.text ?? ''),
          },
          data: {
            'type': 'chat_message',
            'conversationId': conversationId,
            'senderId': message.senderId,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    final conversationsCollection = _getConversationsCollection();
    return conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> markConversationMessagesAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      final conversationsCollection = _getConversationsCollection();
      final messagesCollection =
          conversationsCollection.doc(conversationId).collection('messages');

      final unreadMessages = await messagesCollection
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      batch.update(conversationsCollection.doc(conversationId), {
        'unreadCount_$userId': 0,
      });

      await batch.commit();
    } catch (e) {
      print('Failed to mark conversation messages as read: $e');
    }
  }
}
