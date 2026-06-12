// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/chat_repository.dart';
import '../../chat/models/chat_message.dart';

/// ViewModel for chat-related UI state and operations.
class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;

  ChatViewModel({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ─── Trade-based chat ─────────────────────────────────────────────────

  Future<void> sendMessage(ChatMessage message) async {
    await _chatRepository.sendMessage(message);
  }

  Stream<List<ChatMessage>> getMessages(String tradeId) {
    return _chatRepository.getMessages(tradeId);
  }

  Future<void> markMessagesAsRead(String tradeId, String userId) async {
    await _chatRepository.markMessagesAsRead(tradeId, userId);
  }

  // ─── Conversation-based chat ──────────────────────────────────────────

  String getConversationId(String userId1, String userId2) {
    return _chatRepository.getConversationId(userId1, userId2);
  }

  Future<void> getOrCreateConversation(String userId1, String userId2) async {
    _setLoading(true);
    try {
      await _chatRepository.getOrCreateConversation(userId1, userId2);
    } finally {
      _setLoading(false);
    }
  }

  Stream<QuerySnapshot> getUserConversations(String userId) {
    return _chatRepository.getUserConversations(userId);
  }

  Future<void> sendConversationMessage(
    ChatMessage message,
    String conversationId,
  ) async {
    await _chatRepository.sendConversationMessage(message, conversationId);
  }

  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    return _chatRepository.getConversationMessages(conversationId);
  }

  Future<void> markConversationMessagesAsRead(
    String conversationId,
    String userId,
  ) async {
    await _chatRepository.markConversationMessagesAsRead(
        conversationId, userId);
  }
}
