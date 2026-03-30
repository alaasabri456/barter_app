// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../features/authentication/models/login_request.dart';
import '../features/products/models/product_model.dart';
import '../features/authentication/models/register_request.dart';
import '../features/trade/models/trade_offer.dart';
import '../features/authentication/models/user_model.dart';
import '../features/chat/models/chat_message.dart';
import '../features/reviews/models/review_model.dart';
import '../features/notifications/models/notification_model.dart';
import '../features/admin/models/admin_stats_model.dart';
import '../features/admin/models/category_suggestion_model.dart';
import '../features/payment/models/payment_model.dart';
import '../services/fcm_v1_service.dart';

const Map<String, Map<String, String>> _localizedNotificationStrings = {
  'en': {
    'newOfferTitle': 'New Trade Offer',
    'newOfferBody': '{sender} sent you a trade offer.',
    'counterOfferTitle': 'New Counter Offer',
    'counterOfferBody': '{sender} sent a counter offer.',
    'tradeAcceptedTitle': 'Trade Accepted!',
    'tradeAcceptedBody': 'Your trade offer has been accepted!',
    'tradeRejectedTitle': 'Trade Rejected',
    'tradeRejectedBody': 'Your trade offer was rejected.',
    'tradeAutoRejectedBody':
        'Your offer was cancelled because the item is no longer available.',
    'tradeCompletedTitle': 'Trade Completed!',
    'tradeCompletedBody': 'The trade has been confirmed as completed.',
    'newMessageTitle': 'New Message',
    'newMessageBody': '{sender}: {message}',
    'newReviewTitle': 'New Review received',
    'newReviewBody': '{sender} left you a review: {rating}⭐',
  },
  'ar': {
    'newOfferTitle': 'عرض مبادلة جديد',
    'newOfferBody': 'أرسل لك {sender} عرض مبادلة.',
    'counterOfferTitle': 'عرض مقابل جديد',
    'counterOfferBody': 'أرسل {sender} عرضاً مقابلاً.',
    'tradeAcceptedTitle': 'تم قبول المبادلة!',
    'tradeAcceptedBody': 'تم قبول عرض المبادلة الخاص بك!',
    'tradeRejectedTitle': 'تم رفض المبادلة',
    'tradeRejectedBody': 'تم رفض عرض المبادلة الخاص بك.',
    'tradeAutoRejectedBody': 'تم إلغاء عرضك لأن السلعة لم تعد متوفرة.',
    'tradeCompletedTitle': 'اكتملت المبادلة!',
    'tradeCompletedBody': 'تم تأكيد اكتمال المبادلة.',
    'newMessageTitle': 'رسالة جديدة',
    'newMessageBody': '{sender}: {message}',
    'newReviewTitle': 'تم استلام تقييم جديد',
    'newReviewBody': 'ترك لك {sender} تقييماً: {rating}⭐',
  },
};

class FirebaseService {
  static Future<UserCredential> register(RegisterRequest request) async {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );
    return userCredential;
  }

  static Future<UserCredential> login(LoginRequest request) async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );
    return userCredential;
  }

  static final gsi.GoogleSignIn _google = gsi.GoogleSignIn.instance;
  static bool _isInitialized = false;

  static Future<void> _initSignIn() async {
    if (!_isInitialized) {
      await _google.initialize(
        serverClientId:
            '460987873980-s29ubpkkass8m9c106sf491oc6rbrhrl.apps.googleusercontent.com',
      );
      _isInitialized = true;
    }
  }

  static Future<UserCredential> signInWithGoogle() async {
    await _initSignIn();
    gsi.GoogleSignInAccount account = await _google.authenticate();

    final idToken = account.authentication.idToken;
    final authClient = account.authorizationClient;
    final gsi.GoogleSignInClientAuthorization? auth =
        await authClient.authorizationForScopes(['email', 'profile']);
    final accessToken = auth?.accessToken;

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserModel> handleGoogleSignInUser(User user) async {
    UserModel? existingUser = await getUserFromFireStore(user.uid);

    if (existingUser != null) {
      return existingUser;
    } else {
      UserModel newUser = UserModel(
        id: user.uid,
        name: user.displayName ?? 'Google User',
        email: user.email ?? '',
        favouriteProductIds: [],
      );

      await addUserToFireStore(newUser);
      return newUser;
    }
  }

  static CollectionReference<UserModel> _getUsersCollection() {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference<UserModel> usersCollection = db
        .collection("Users")
        .withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
    return usersCollection;
  }

  static Future<void> addUserToFireStore(UserModel user) {
    CollectionReference<UserModel> usersCollection = _getUsersCollection();
    DocumentReference<UserModel> usersDocument = usersCollection.doc(user.id);
    return usersDocument.set(user);
  }

  static Future<UserModel?> getUserFromFireStore(String uid) async {
    CollectionReference<UserModel> usersCollection = _getUsersCollection();
    DocumentReference<UserModel> usersDocument = usersCollection.doc(uid);
    DocumentSnapshot<UserModel> documentSnapshot = await usersDocument.get();
    return documentSnapshot.data();
  }

  static Future<void> updateUserFcmToken(String userId, String token) async {
    try {
      final usersCollection = _getUsersCollection();
      await usersCollection.doc(userId).update({'fcmToken': token});

      // Update local current user if applicable
      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser?.fcmToken = token;
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  static Future<void> updateUserLanguage(
      String userId, String languageCode) async {
    try {
      final usersCollection = _getUsersCollection();
      await usersCollection.doc(userId).update({'languageCode': languageCode});

      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser?.languageCode = languageCode;
      }
    } catch (e) {
      print('Failed to update language code: $e');
    }
  }

  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
    bool? is2faEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (is2faEnabled != null) updates['is2faEnabled'] = is2faEnabled;

      if (updates.isEmpty) return;

      await _getUsersCollection().doc(userId).update(updates);

      // Update local current user
      if (UserModel.currentUser?.id == userId) {
        if (name != null) UserModel.currentUser!.name = name;
        if (profileImageUrl != null) {
          UserModel.currentUser!.profileImageUrl = profileImageUrl;
        }
        if (is2faEnabled != null) {
          UserModel.currentUser!.is2faEnabled = is2faEnabled;
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  static Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      final usersCollection = _getUsersCollection();
      await usersCollection.doc(userId).update({
        'blockedUserIds': FieldValue.arrayUnion([blockedUserId])
      });

      if (UserModel.currentUser?.id == userId) {
        if (!UserModel.currentUser!.blockedUserIds.contains(blockedUserId)) {
          UserModel.currentUser!.blockedUserIds.add(blockedUserId);
        }
      }
    } catch (e) {
      print('Failed to block user: $e');
      throw Exception('Failed to block user: $e');
    }
  }

  static Future<void> unblockUser(String userId, String unblockedUserId) async {
    try {
      final usersCollection = _getUsersCollection();
      await usersCollection.doc(userId).update({
        'blockedUserIds': FieldValue.arrayRemove([unblockedUserId])
      });

      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser!.blockedUserIds.remove(unblockedUserId);
      }
    } catch (e) {
      print('Failed to unblock user: $e');
      throw Exception('Failed to unblock user: $e');
    }
  }

  static CollectionReference<ProductModel> _getProductsCollection(
    BuildContext? context,
  ) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference<ProductModel> productsCollection =
        db.collection("Products").withConverter<ProductModel>(
              fromFirestore: (snapshot, _) =>
                  ProductModel.fromJson(snapshot.data()!),
              toFirestore: (product, _) => product.toJson(),
            );
    return productsCollection;
  }

  static Future<void> addProductToFireStore(
    ProductModel product,
    BuildContext context,
  ) {
    final productsCollection = _getProductsCollection(context);
    final productDocument = productsCollection.doc();

    final updatedProduct = product.copyWith(
      id: productDocument.id,
      ownerId: UserModel.currentUser!.id,
      ownerName: UserModel.currentUser!.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return productDocument.set(updatedProduct);
  }

  static Future<String?> getUserFcmToken(String userId) async {
    try {
      final user = await getUserFromFireStore(userId);
      return user?.fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> sendPushNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await FcmV1Service.getAccessToken();
      const projectId = 'barter-30a05';
      const url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': recipientToken,
            'notification': {'title': title, 'body': body},
            'data':
                data?.map((key, value) => MapEntry(key, value.toString())) ??
                    {},
          },
        }),
      );

      if (response.statusCode == 200) {
        print('FCM v1 notification sent successfully');
      } else {
        print('FCM v1 notification failed: ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM v1 notification: $e');
    }
  }

  static Future<void> _sendLocalizedNotification({
    required String recipientId,
    required String titleKey,
    required String bodyKey,
    NotificationType type = NotificationType.tradeUpdate,
    Map<String, String>? bodyArgs,
    Map<String, dynamic>? data,
  }) async {
    try {
      final recipient = await getUserFromFireStore(recipientId);
      if (recipient == null) return;

      final lang = recipient.languageCode;
      String title = _localizedNotificationStrings[lang]?[titleKey] ??
          _localizedNotificationStrings['en']![titleKey]!;
      String body = _localizedNotificationStrings[lang]?[bodyKey] ??
          _localizedNotificationStrings['en']![bodyKey]!;

      // Replace placeholders
      if (bodyArgs != null) {
        bodyArgs.forEach((key, value) {
          body = body.replaceAll('{$key}', value);
        });
      }

      // 1. Send In-App Notification (for the badge)
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final notification = NotificationModel(
        id: notificationId,
        userId: recipientId,
        title: title,
        body: body,
        type: type,
        relatedId: data?['tradeId'] ?? data?['conversationId'],
        createdAt: DateTime.now(),
      );
      await sendNotification(notification);

      // 2. Send Push Notification (for the phone tray)
      if (recipient.fcmToken != null) {
        await sendPushNotification(
          recipientToken: recipient.fcmToken!,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      print('Failed to send localized notification: $e');
    }
  }

  static Future<int> getUntradedProductsCount(
    String userId,
    BuildContext context,
  ) async {
    try {
      final products = await getUserProducts(userId, context);
      final untradedCount =
          products.where((p) => p.status != ProductStatus.traded).length;

      return untradedCount;
    } catch (e) {
      print('Error getting untraded products count: $e');
      return 0;
    }
  }

  static Future<bool> isProductInPendingTrade(String productId) async {
    try {
      final tradesCollection = _getTradesCollection();

      // Check if product is in offeredProductIds of any pending trade
      final offeredQuery = await tradesCollection
          .where('offeredProductIds', arrayContains: productId)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .limit(1)
          .get();

      if (offeredQuery.docs.isNotEmpty) return true;

      // Check if product is in requestedProductIds of any pending trade
      final requestedQuery = await tradesCollection
          .where('requestedProductIds', arrayContains: productId)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .limit(1)
          .get();

      return requestedQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking trade constraint: $e');
      return false;
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Products')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<List<ProductModel>> getProductsFromFireStore(
    BuildContext context,
  ) async {
    CollectionReference<ProductModel> productsCollection =
        _getProductsCollection(context);
    QuerySnapshot<ProductModel> querySnapshot =
        await productsCollection.orderBy("createdAt", descending: true).get();
    List<ProductModel> products = querySnapshot.docs
        .map((documentSnapshot) => documentSnapshot.data())
        .toList();
    return products;
  }

  static Future<String> uploadProductImage(
    XFile imageFile,
    String fileName,
  ) async {
    try {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('$fileName.jpg');

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final uploadTask = storageRef.putData(bytes);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        final uploadTask = storageRef.putFile(File(imageFile.path));
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<List<String>> uploadProductImages(
    List<XFile> images,
    String userId,
  ) async {
    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < images.length; i++) {
        final String fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
        final String downloadUrl = await uploadProductImage(
          images[i],
          fileName,
        );
        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  static CollectionReference<TradeOffer> _getTradesCollection() {
    FirebaseFirestore db = FirebaseFirestore.instance;
    return db.collection("Trades").withConverter<TradeOffer>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return TradeOffer.fromJson(data);
          },
          toFirestore: (trade, _) => trade.toJson(),
        );
  }

  static CollectionReference<TradeHistory> _getTradeHistoryCollection() {
    FirebaseFirestore db = FirebaseFirestore.instance;
    return db.collection("TradeHistory").withConverter<TradeHistory>(
          fromFirestore: (snapshot, _) =>
              TradeHistory.fromJson(snapshot.data()!),
          toFirestore: (history, _) => history.toJson(),
        );
  }

  static Future<String> createTradeOffer(TradeOffer trade) async {
    try {
      final tradesCollection = _getTradesCollection();
      final tradeDoc = tradesCollection.doc();

      final tradeWithId = trade.copyWith(id: tradeDoc.id);

      await tradeDoc.set(tradeWithId);

      // Add to trade history
      await _addTradeHistory(
        tradeId: tradeDoc.id,
        action: 'TRADE_CREATED',
        performedByUserId: trade.fromUserId,
        performedByUserName: trade.fromUserName,
        details: {
          'type': trade.type.name,
          'offeredProducts': trade.offeredProductIds,
          'requestedProducts': trade.requestedProductIds,
        },
      );

      // Send Push Notification
      _sendLocalizedNotification(
        recipientId: trade.toUserId,
        titleKey: 'newOfferTitle',
        bodyKey: 'newOfferBody',
        bodyArgs: {'sender': trade.fromUserName},
        data: {
          'type': 'trade_offer',
          'tradeId': tradeDoc.id,
        },
      );

      return tradeDoc.id;
    } catch (e) {
      throw Exception('Failed to create trade offer: $e');
    }
  }

  static Future<bool> isDuplicateTrade({
    required String userId,
    required String targetProductId,
    required List<String> offeredProductIds,
  }) async {
    try {
      final tradesCollection = _getTradesCollection();

      // Check 1: Get all pending trades FROM this user that involve the target product
      final sentTrades = await tradesCollection
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('requestedProductIds', arrayContains: targetProductId)
          .get();

      // Check if any of these trades have the exact same offered items
      for (final doc in sentTrades.docs) {
        final trade = doc.data();

        // Check if offered lists are identical (ignoring order)
        final existingOffered = Set<String>.from(trade.offeredProductIds);
        final newOffered = Set<String>.from(offeredProductIds);

        if (existingOffered.length == newOffered.length &&
            existingOffered.containsAll(newOffered)) {
          return true;
        }
      }

      // Check 2: Get all pending trades TO this user (reverse trades)
      // where someone else is offering what we're requesting and requesting what we're offering
      final receivedTrades = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in receivedTrades.docs) {
        final trade = doc.data();

        // Check if this is a reverse trade:
        // - They're offering what we're requesting (targetProductId)
        // - They're requesting what we're offering (offeredProductIds)
        final theyOffer = Set<String>.from(trade.offeredProductIds);
        final theyRequest = Set<String>.from(trade.requestedProductIds);
        final weOffer = Set<String>.from(offeredProductIds);
        final weRequest = {targetProductId};

        // If they're offering what we want AND requesting what we're offering, it's a reverse trade
        if (theyOffer.containsAll(weRequest) &&
            theyRequest.containsAll(weOffer) &&
            theyOffer.length == weRequest.length &&
            theyRequest.length == weOffer.length) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking for duplicate trades: $e');
      return false; // Fail safe: allow trade if check fails
    }
  }

  static Future<void> debugCheckReceivedTrades(String userId) async {
    try {
      final tradesCollection = _getTradesCollection();
      final querySnapshot =
          await tradesCollection.where('toUserId', isEqualTo: userId).get();

      for (final doc in querySnapshot.docs) {
        final trade = doc.data();
        print('Trade ID: ${trade.id}');
        print('  From: ${trade.fromUserName} (${trade.fromUserId})');
        print('  Status: ${trade.status}');
        print('  Offered: ${trade.offeredProductIds}');
        print('  Requested: ${trade.requestedProductIds}');
        print('  Created: ${trade.createdAt}');
        print('  Expires: ${trade.expiresAt}');
        print('  ---');
      }
    } catch (e) {
      print('=== DEBUG: ERROR checking received trades: $e ===');
    }
  }

  static Future<List<TradeOffer>> getReceivedTrades(String userId) async {
    try {
      final tradesCollection = _getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted'])
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get received trades: $e');
    }
  }

  static Future<List<TradeOffer>> getSentTrades(String userId) async {
    try {
      final tradesCollection = _getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get sent trades: $e');
    }
  }

  static Future<void> updateTradeStatus({
    required String tradeId,
    required TradeStatus newStatus,
    required String userId,
    required String userName,
  }) async {
    try {
      final tradesCollection = _getTradesCollection();
      final tradeDoc = tradesCollection.doc(tradeId);

      // Get current trade data to check for transitions
      final snapshot = await tradeDoc.get();
      final trade = snapshot.data();
      if (trade == null) throw Exception('Trade not found');

      final oldStatus = trade.status;

      await tradeDoc.update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });

      // Handle product availability based on status transition
      if (newStatus == TradeStatus.accepted &&
          oldStatus != TradeStatus.accepted) {
        // Mark products as traded
        final allProductIds = {
          ...trade.offeredProductIds,
          ...trade.requestedProductIds
        };
        for (final pid in allProductIds) {
          await updateProductAvailability(
            productId: pid,
            isAvailable: false,
            newStatus: ProductStatus.traded,
          );
        }
      } else if ((newStatus == TradeStatus.rejected ||
              newStatus == TradeStatus.cancelled) &&
          oldStatus == TradeStatus.accepted) {
        // Reset products to available if they were previously marked as traded
        final allProductIds = {
          ...trade.offeredProductIds,
          ...trade.requestedProductIds
        };
        for (final pid in allProductIds) {
          await updateProductAvailability(
            productId: pid,
            isAvailable: true,
            newStatus: ProductStatus.available,
          );
        }
      }

      // Send Notification to the other party
      final recipientId =
          (userId == trade.fromUserId) ? trade.toUserId : trade.fromUserId;
      String titleKey;
      String bodyKey;

      if (newStatus == TradeStatus.accepted) {
        titleKey = 'tradeAcceptedTitle';
        bodyKey = 'tradeAcceptedBody';
      } else if (newStatus == TradeStatus.completed) {
        titleKey = 'tradeCompletedTitle';
        bodyKey = 'tradeCompletedBody';
      } else {
        titleKey = 'tradeRejectedTitle';
        bodyKey = 'tradeRejectedBody';
      }

      await _sendLocalizedNotification(
        recipientId: recipientId,
        titleKey: titleKey,
        bodyKey: bodyKey,
        data: {
          'type': 'trade_status_update',
          'tradeId': tradeId,
          'status': newStatus.name,
        },
      );

      // AUTO-REJECT CONFLICTING TRADES
      if (newStatus == TradeStatus.accepted) {
        await _rejectConflictingTrades(
          acceptedTrade: trade,
          excludingTradeId: tradeId,
        );
      }

      // Add to trade history
      await _addTradeHistory(
        tradeId: tradeId,
        action: 'STATUS_CHANGED',
        performedByUserId: userId,
        performedByUserName: userName,
        details: {'newStatus': newStatus.name},
      );
    } catch (e) {
      throw Exception('Failed to update trade status: $e');
    }
  }

  /// Automatically reject trades that involve products from a newly accepted trade
  static Future<void> _rejectConflictingTrades({
    required TradeOffer acceptedTrade,
    required String excludingTradeId,
  }) async {
    try {
      final tradesCollection = _getTradesCollection();
      final allProductsInAcceptedTrade = {
        ...acceptedTrade.offeredProductIds,
        ...acceptedTrade.requestedProductIds
      };

      // Find all pending trades across the entire collection
      // For performance, we limit scope to trades involving at least one product ID
      // but Firestore array-contains-any has limits (10).
      // Since most trades have few items, we can iterate or use multiple queries.

      final conflictingTrades = <String, QueryDocumentSnapshot<TradeOffer>>{};

      // We chunk the product IDs to respect Firestore limits if necessary
      final productList = allProductsInAcceptedTrade.toList();
      const chunkSize = 10;

      for (var i = 0; i < productList.length; i += chunkSize) {
        final chunk = productList.sublist(
            i,
            i + chunkSize > productList.length
                ? productList.length
                : i + chunkSize);

        // Check requestedProductIds
        final q1 = await tradesCollection
            .where('status', isEqualTo: TradeStatus.pending.name)
            .where('requestedProductIds', arrayContainsAny: chunk)
            .get();
        for (var doc in q1.docs) {
          if (doc.id != excludingTradeId) conflictingTrades[doc.id] = doc;
        }

        // Check offeredProductIds
        final q2 = await tradesCollection
            .where('status', isEqualTo: TradeStatus.pending.name)
            .where('offeredProductIds', arrayContainsAny: chunk)
            .get();
        for (var doc in q2.docs) {
          if (doc.id != excludingTradeId) conflictingTrades[doc.id] = doc;
        }
      }

      if (conflictingTrades.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in conflictingTrades.values) {
        final otherTrade = doc.data();

        batch.update(doc.reference, {
          'status': TradeStatus.rejected.name,
          'updatedAt': Timestamp.now(),
          'rejectionReason': 'Item no longer available',
        });

        // Notify the requester (sender) of the auto-rejected trade
        await _sendLocalizedNotification(
          recipientId: otherTrade.fromUserId,
          titleKey: 'tradeRejectedTitle',
          bodyKey: 'tradeAutoRejectedBody',
          data: {
            'type': 'trade_status_update',
            'tradeId': doc.id,
            'status': TradeStatus.rejected.name,
            'isAutoRejected': 'true',
          },
        );

        // Add to history
        await _addTradeHistory(
          tradeId: doc.id,
          action: 'AUTO_REJECTED',
          performedByUserId: 'system',
          performedByUserName: 'System',
          details: {'reason': 'Item traded in trade: $excludingTradeId'},
        );
      }

      await batch.commit();
      print('Auto-rejected ${conflictingTrades.length} conflicting trades.');
    } catch (e) {
      print('Error auto-rejecting conflicting trades: $e');
    }
  }

  static Future<void> addCounterOffer({
    required String tradeId,
    required TradeCounterOffer counterOffer,
    required String userId,
    required String userName,
  }) async {
    try {
      final tradesCollection = _getTradesCollection();
      final tradeDoc = tradesCollection.doc(tradeId);

      // Get current trade
      final tradeSnapshot = await tradeDoc.get();
      final currentTrade = tradeSnapshot.data();

      if (currentTrade != null) {
        final updatedCounterOffers = [
          ...currentTrade.counterOffers,
          counterOffer,
        ];

        await tradeDoc.update({
          'counterOffers':
              updatedCounterOffers.map((co) => co.toJson()).toList(),
          'updatedAt': Timestamp.now(),
        });

        // Add to trade history
        await _addTradeHistory(
          tradeId: tradeId,
          action: 'COUNTER_OFFER_ADDED',
          performedByUserId: userId,
          performedByUserName: userName,
          details: {'counterOfferId': counterOffer.id},
        );

        // Send Notification to recipient of counter offer
        _sendLocalizedNotification(
          recipientId: counterOffer.toUserId,
          titleKey: 'counterOfferTitle',
          bodyKey: 'counterOfferBody',
          bodyArgs: {'sender': userName},
          data: {
            'type': 'counter_offer',
            'tradeId': tradeId,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to add counter offer: $e');
    }
  }

  static Future<void> acceptCounterOffer({
    required String tradeId,
    required String counterOfferId,
    required String userId,
    required String userName,
  }) async {
    try {
      final tradesCollection = _getTradesCollection();
      final tradeDoc = tradesCollection.doc(tradeId);

      final tradeSnapshot = await tradeDoc.get();
      final currentTrade = tradeSnapshot.data();

      if (currentTrade != null) {
        final updatedCounterOffers = currentTrade.counterOffers.map((co) {
          if (co.id == counterOfferId) {
            return co.copyWith(isAccepted: true);
          }
          return co;
        }).toList();

        // Update the trade with the accepted counter offer
        final acceptedCounterOffer = updatedCounterOffers.firstWhere(
          (co) => co.id == counterOfferId,
        );

        final updatedTrade = currentTrade.copyWith(
          offeredProductIds: acceptedCounterOffer.offeredProductIds,
          requestedProductIds: acceptedCounterOffer.requestedProductIds,
          counterOffers: updatedCounterOffers,
          status: TradeStatus.accepted,
          updatedAt: DateTime.now(),
        );

        await tradeDoc.set(updatedTrade);

        // Add to trade history
        await _addTradeHistory(
          tradeId: tradeId,
          action: 'COUNTER_OFFER_ACCEPTED',
          performedByUserId: userId,
          performedByUserName: userName,
          details: {'counterOfferId': counterOfferId},
        );
      }
    } catch (e) {
      throw Exception('Failed to accept counter offer: $e');
    }
  }

  static Future<List<TradeHistory>> getTradeHistory(String tradeId) async {
    try {
      final historyCollection = _getTradeHistoryCollection();
      final querySnapshot = await historyCollection
          .where('tradeId', isEqualTo: tradeId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get trade history: $e');
    }
  }

  static Future<void> _addTradeHistory({
    required String tradeId,
    required String action,
    required String performedByUserId,
    required String performedByUserName,
    Map<String, dynamic>? details,
  }) async {
    try {
      final historyCollection = _getTradeHistoryCollection();
      final historyDoc = historyCollection.doc();

      final history = TradeHistory(
        id: historyDoc.id,
        tradeId: tradeId,
        action: action,
        performedByUserId: performedByUserId,
        performedByUserName: performedByUserName,
        timestamp: DateTime.now(),
        details: details,
      );

      await historyDoc.set(history);
    } catch (e) {
      print('Failed to add trade history: $e');
    }
  }

  // Check for expired trades
  static Future<void> checkAndExpireTrades() async {
    try {
      final tradesCollection = _getTradesCollection();
      final now = Timestamp.now();

      final querySnapshot = await tradesCollection
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        final tradeDoc = tradesCollection.doc(doc.id);
        batch.update(tradeDoc, {
          'status': TradeStatus.expired.name,
          'updatedAt': now,
        });

        // Add to history for each expired trade
        doc.data();
        _addTradeHistory(
          tradeId: doc.id,
          action: 'TRADE_EXPIRED',
          performedByUserId: 'system',
          performedByUserName: 'System',
        );
      }

      await batch.commit();
    } catch (e) {
      print('Failed to expire trades: $e');
    }
  }

  // In firebase_service.dart - update the getUserProducts method
  static Future<List<ProductModel>> getUserProducts(
    String userId,
    BuildContext context,
  ) async {
    try {
      print('=== DEBUG: Getting products for user: $userId ===');

      if (userId.isEmpty) {
        throw Exception('User ID is empty');
      }

      final productsCollection = _getProductsCollection(context);

      // First, try a simple query to see if we can get any data
      await productsCollection.limit(1).get();

      // Now query for user's products
      final querySnapshot = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('=== DEBUG: No products found for user $userId ===');
        return [];
      }

      // Convert documents to ProductModel
      final products = <ProductModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final product = doc.data();
          print(
            '=== DEBUG: Product ${product.title} - Available: ${product.isAvailable}, Status: ${product.status}',
          );
          products.add(product);
        } catch (e) {
          print('=== DEBUG: Error parsing product document: $e ===');
        }
      }

      print('=== DEBUG: Returning ${products.length} total products ===');

      // Return ALL products, let the UI filter by status
      return products;
    } catch (e) {
      print('=== DEBUG: ERROR in getUserProducts: $e ===');
      print('=== DEBUG: Error type: ${e.runtimeType} ===');

      if (e is FirebaseException) {
        print('=== DEBUG: Firebase error code: ${e.code} ===');
        print('=== DEBUG: Firebase error message: ${e.message} ===');
      }

      throw Exception(
        'Failed to load your products. Please check your connection and try again.',
      );
    }
  }

  // If you need to get products by IDs (for trade details)
  static Future<List<ProductModel>> getProductsByIds(
    List<String> productIds,
    BuildContext context,
  ) async {
    try {
      if (productIds.isEmpty) return [];

      final productsCollection = _getProductsCollection(context);
      final querySnapshot = await productsCollection
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get products by IDs: $e');
    }
  }

  // Also need to fix the _getProductsCollection method to accept context properly

  // Add this to your firebase_service.dart
  static Future<ProductModel?> getProductById(
    String productId,
    BuildContext context,
  ) async {
    try {
      final productsCollection = _getProductsCollection(context);
      final productDoc = productsCollection.doc(productId);
      final productSnapshot = await productDoc.get();

      if (productSnapshot.exists) {
        return productSnapshot.data();
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Add to FirebaseService class
  static Future<void> updateProductAvailability({
    required String productId,
    required bool isAvailable,
    ProductStatus? newStatus,
  }) async {
    try {
      final status = newStatus ??
          (isAvailable ? ProductStatus.available : ProductStatus.unavailable);

      await FirebaseFirestore.instance
          .collection('Products')
          .doc(productId)
          .update({
        'isAvailable': isAvailable,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product availability: $e');
    }
  }

  // ─── Payments ────────────────────────────────────────────────────────────

  static Future<void> savePayment(PaymentModel payment) async {
    try {
      final ref = FirebaseFirestore.instance.collection('Payments').doc();
      final withId = PaymentModel(
        id: ref.id,
        buyerId: payment.buyerId,
        buyerName: payment.buyerName,
        sellerId: payment.sellerId,
        productId: payment.productId,
        productTitle: payment.productTitle,
        amount: payment.amount,
        currency: payment.currency,
        transactionId: payment.transactionId,
        status: payment.status,
        createdAt: payment.createdAt,
      );
      await ref.set(withId.toJson());
    } catch (e) {
      throw Exception('Failed to save payment: $e');
    }
  }

  static Future<void> rejectOtherTradeOffers({
    required String productId,
    required String acceptedTradeId,
  }) async {
    try {
      // Get all pending trades for this product (in requestedProductIds array)
      final tradesCollection = _getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('requestedProductIds', arrayContains: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Batch update to reject all other trades
      final batch = FirebaseFirestore.instance.batch();
      int rejectedCount = 0;

      for (final doc in querySnapshot.docs) {
        if (doc.id != acceptedTradeId) {
          batch.update(tradesCollection.doc(doc.id), {
            'status': TradeStatus.rejected.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'rejectedReason':
                'Product no longer available - another offer was accepted',
          });
          rejectedCount++;

          // Add to trade history for each rejected trade
          _addTradeHistory(
            tradeId: doc.id,
            action: 'AUTO_REJECTED',
            performedByUserId: 'system',
            performedByUserName: 'System',
            details: {
              'reason': 'Another offer for this product was accepted',
              'acceptedTradeId': acceptedTradeId,
            },
          );
        }
      }

      await batch.commit();
      print(
        '=== DEBUG: Auto-rejected $rejectedCount other trade offers for product $productId ===',
      );
    } catch (e) {
      print('Error rejecting other trades: $e');
      // Don't throw here as this is optional functionality
    }
  }

  // Favourites Management Methods
  static Future<void> addToFavourites(String userId, String productId) async {
    try {
      print('=== DEBUG: Adding to favourites ===');
      print('User ID: $userId');
      print('Product ID: $productId');

      final usersCollection = _getUsersCollection();
      final userDoc = usersCollection.doc(userId);

      await userDoc.update({
        'favouriteProductIds': FieldValue.arrayUnion([productId]),
      });

      print('=== DEBUG: Successfully added to favourites ===');

      // Update current user if it's the same user
      if (UserModel.currentUser?.id == userId) {
        final updatedUser = await getUserFromFireStore(userId);
        if (updatedUser != null) {
          UserModel.currentUser = updatedUser;
        }
      }
    } catch (e) {
      print('=== DEBUG: Error adding to favourites: $e ===');
      throw Exception('Failed to add to favourites: $e');
    }
  }

  static Future<void> removeFromFavourites(
    String userId,
    String productId,
  ) async {
    try {
      final usersCollection = _getUsersCollection();
      final userDoc = usersCollection.doc(userId);

      await userDoc.update({
        'favouriteProductIds': FieldValue.arrayRemove([productId]),
      });

      // Update current user if it's the same user
      if (UserModel.currentUser?.id == userId) {
        final updatedUser = await getUserFromFireStore(userId);
        if (updatedUser != null) {
          UserModel.currentUser = updatedUser;
        }
      }
    } catch (e) {
      throw Exception('Failed to remove from favourites: $e');
    }
  }

  static Future<bool> toggleFavourite(String userId, String productId) async {
    final userRef = _getUsersCollection().doc(userId);
    final productRef = _getProductsCollection(null).doc(productId);

    try {
      // 1. Get current state (standard get allows cache usage)
      final userDoc = await userRef.get();

      // 2. Prepare batch (works offline/optimistically)
      final batch = FirebaseFirestore.instance.batch();
      bool isCurrentlyFavourite = false;

      if (!userDoc.exists) {
        // Create user doc if it doesn't exist
        final user = UserModel(
          id: userId,
          email: UserModel.currentUser?.email ??
              FirebaseAuth.instance.currentUser?.email ??
              '',
          name: UserModel.currentUser?.name ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'User',
          favouriteProductIds: [productId], // Add directly
        );
        batch.set(userRef, user);

        // Add to product interested users
        batch.update(productRef, {
          'interestedUsers': FieldValue.arrayUnion([userId]),
        });

        await batch.commit();
        return true;
      }

      // User exists, check current state
      final user = userDoc.data()!;
      final List<String> currentFavourites = List<String>.from(
        user.favouriteProductIds,
      );
      isCurrentlyFavourite = currentFavourites.contains(productId);

      if (isCurrentlyFavourite) {
        batch.update(userRef, {
          'favouriteProductIds': FieldValue.arrayRemove([productId]),
        });
        batch.update(productRef, {
          'interestedUsers': FieldValue.arrayRemove([userId]),
        });
      } else {
        batch.update(userRef, {
          'favouriteProductIds': FieldValue.arrayUnion([productId]),
        });
        batch.update(productRef, {
          'interestedUsers': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();
      return !isCurrentlyFavourite;
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  static Future<void> reportProduct({
    required String productId,
    required String userId,
  }) async {
    if (userId.isEmpty) return;

    final productRef = _getProductsCollection(null).doc(productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final productDoc = await transaction.get(productRef);
      if (!productDoc.exists) return;

      final product = productDoc.data()!;
      final reportedByUserIds = List<String>.from(product.reportedByUserIds);

      if (!reportedByUserIds.contains(userId)) {
        reportedByUserIds.add(userId);
        transaction.update(productRef, {
          'reportedByUserIds': reportedByUserIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<void> incrementProductViewCount(
    String productId,
    String userId,
  ) async {
    if (userId.isEmpty) return;

    final productRef = _getProductsCollection(null).doc(productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final productDoc = await transaction.get(productRef);
      if (!productDoc.exists) return;

      final product = productDoc.data()!;
      final viewedUserIds = List<String>.from(product.viewedUserIds);

      if (!viewedUserIds.contains(userId)) {
        viewedUserIds.add(userId);
        transaction.update(productRef, {
          'viewCount': FieldValue.increment(1),
          'viewedUserIds': viewedUserIds,
        });
      }
    });
  }

  static Future<List<ProductModel>> getFavouriteProducts(
    String userId,
    BuildContext context,
  ) async {
    try {
      final user = await getUserFromFireStore(userId);
      if (user == null || user.favouriteProductIds.isEmpty) {
        return [];
      }

      // Firebase 'whereIn' has a limit of 10 items, so we need to batch requests
      final favouriteIds = user.favouriteProductIds;
      final List<ProductModel> favouriteProducts = [];

      // Process in batches of 10
      for (int i = 0; i < favouriteIds.length; i += 10) {
        final batch = favouriteIds.skip(i).take(10).toList();
        final products = await getProductsByIds(batch, context);
        favouriteProducts.addAll(products);
      }

      return favouriteProducts;
    } catch (e) {
      throw Exception('Failed to get favourite products: $e');
    }
  }

  static Future<bool> isFavourite(String userId, String productId) async {
    try {
      final user = await getUserFromFireStore(userId);
      if (user == null) return false;

      return user.favouriteProductIds.contains(productId);
    } catch (e) {
      return false;
    }
  }

  // Chat Methods
  static Future<void> sendMessage(ChatMessage message) async {
    try {
      print('=== DEBUG: Sending message to trade: ${message.tradeId} ===');
      final tradesCollection = _getTradesCollection();
      final messagesCollection =
          tradesCollection.doc(message.tradeId).collection('messages');

      await messagesCollection.doc(message.id).set(message.toJson());

      // Update trade with last message info for preview
      await tradesCollection.doc(message.tradeId).update({
        'lastMessage': message.imageUrl != null ? '📷 Photo' : message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': message.senderId,
        'hasUnreadMessages': true,
      });
      print('=== DEBUG: Message sent successfully ===');
    } catch (e) {
      print('=== DEBUG: Failed to send message: $e ===');
      throw Exception('Failed to send message: $e');
    }
  }

  static Stream<List<ChatMessage>> getMessages(String tradeId) {
    print('=== DEBUG: Listening to messages for trade: $tradeId ===');
    final tradesCollection = _getTradesCollection();
    return tradesCollection
        .doc(tradeId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
        '=== DEBUG: Received ${snapshot.docs.length} messages for trade $tradeId ===',
      );
      return snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data()))
          .toList();
    });
  }

  static Future<void> markMessagesAsRead(String tradeId, String userId) async {
    try {
      final tradesCollection = _getTradesCollection();
      final messagesCollection =
          tradesCollection.doc(tradeId).collection('messages');

      final unreadMessages = await messagesCollection
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Update trade unread status
      // This is a simplification; ideally we'd check if there are any other unread messages
      await tradesCollection.doc(tradeId).update({'hasUnreadMessages': false});
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // Find an accepted trade between two users involving a specific product
  static Future<TradeOffer?> getAcceptedTradeBetweenUsers({
    required String userId1,
    required String userId2,
    required String productId,
  }) async {
    try {
      final tradesCollection = _getTradesCollection();

      // Check trades where userId1 is the sender and userId2 is the receiver
      final sentTrades = await tradesCollection
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (final doc in sentTrades.docs) {
        final trade = doc.data();
        if (trade.requestedProductIds.contains(productId) ||
            trade.offeredProductIds.contains(productId)) {
          return trade;
        }
      }

      // Check trades where userId2 is the sender and userId1 is the receiver
      final receivedTrades = await tradesCollection
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (final doc in receivedTrades.docs) {
        final trade = doc.data();
        if (trade.requestedProductIds.contains(productId) ||
            trade.offeredProductIds.contains(productId)) {
          return trade;
        }
      }

      return null;
    } catch (e) {
      print('Failed to find accepted trade: $e');
      return null;
    }
  }

  // ============ CONVERSATION-BASED MESSAGING (Direct Chat) ============

  /// Generate a consistent conversation ID from two user IDs
  static String getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'conversation_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get conversations collection reference
  static CollectionReference _getConversationsCollection() {
    return FirebaseFirestore.instance.collection('Conversations');
  }

  /// Get or create a conversation between two users
  static Future<void> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      final conversationId = getConversationId(userId1, userId2);
      final conversationsCollection = _getConversationsCollection();
      final conversationDoc = conversationsCollection.doc(conversationId);

      final snapshot = await conversationDoc.get();

      if (!snapshot.exists) {
        // Create new conversation
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

  /// Get all conversations for a user
  static Stream<QuerySnapshot> getUserConversations(String userId) {
    return _getConversationsCollection()
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Send a message in a conversation
  static Future<void> sendConversationMessage(
    ChatMessage message,
    String conversationId,
  ) async {
    try {
      print('=== DEBUG: Sending message to conversation: $conversationId ===');
      final conversationsCollection = _getConversationsCollection();
      
      // Determine recipient ID
      final userIds = conversationId.replaceFirst('conversation_', '').split('_');
      final recipientId = userIds.firstWhere((id) => id != message.senderId, orElse: () => '');

      // Check for blocking
      if (recipientId.isNotEmpty) {
        final sender = UserModel.currentUser;
        if (sender != null && sender.blockedUserIds.contains(recipientId)) {
          throw Exception('Cannot send message. You have blocked this user.');
        }

        final recipientSnapshot = await _getUsersCollection().doc(recipientId).get();
        final recipient = recipientSnapshot.data();
        if (recipient != null && recipient.blockedUserIds.contains(message.senderId)) {
          throw Exception('Cannot send message. The recipient has blocked you.');
        }
      }

      final messagesCollection =
          conversationsCollection.doc(conversationId).collection('messages');

      await messagesCollection.doc(message.id).set(message.toJson());

      // Update conversation with last message info
      await conversationsCollection.doc(conversationId).update({
        'lastMessage': message.imageUrl != null ? '📷 Photo' : message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send push notification to the recipient
      if (recipientId.isNotEmpty) {
        final senderName = UserModel.currentUser?.name ?? 'Someone';

      await _sendLocalizedNotification(
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

      print('=== DEBUG: Conversation message sent successfully ===');
    } catch (e) {
      print('=== DEBUG: Failed to send conversation message: $e ===');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages stream for a conversation
  static Stream<List<ChatMessage>> getConversationMessages(
    String conversationId,
  ) {
    print(
      '=== DEBUG: Listening to messages for conversation: $conversationId ===',
    );
    final conversationsCollection = _getConversationsCollection();
    return conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
        '=== DEBUG: Received ${snapshot.docs.length} messages for conversation $conversationId ===',
      );
      return snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data()))
          .toList();
    });
  }

  /// Mark messages as read in a conversation
  static Future<void> markConversationMessagesAsRead(
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

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Failed to mark conversation messages as read: $e');
    }
  }

  // ==================== Notifications ====================

  static CollectionReference _getNotificationsCollection() {
    return FirebaseFirestore.instance.collection('Notifications');
  }

  static Future<void> sendNotification(NotificationModel notification) async {
    try {
      print('=== DEBUG: Sending notification to ${notification.userId} ===');
      await _getNotificationsCollection()
          .doc(notification.id)
          .set(notification.toJson());
      print('=== DEBUG: Notification sent successfully ===');
    } catch (e) {
      print('=== DEBUG: Failed to send notification: $e ===');
      throw Exception('Failed to send notification: $e');
    }
  }

  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _getNotificationsCollection()
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => NotificationModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  static Stream<int> getUnreadNotificationCount(String userId) {
    return _getNotificationsCollection()
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _getNotificationsCollection().doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  static Future<void> updateProductInFireStore(
    ProductModel product,
    BuildContext context,
  ) async {
    try {
      final productsCollection = _getProductsCollection(context);
      final productDocument = productsCollection.doc(product.id);

      // Ensure we don't overwrite critical fields like createdAt or ownerId if they are missing (though they shouldn't be)
      // We also want to update 'updatedAt'
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());

      await productDocument.update(updatedProduct.toJson());

      // Notify users in pending trades about the update
      await _notifyPendingTradesAboutUpdate(product);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> _notifyPendingTradesAboutUpdate(
    ProductModel product,
  ) async {
    try {
      final tradesCollection = _getTradesCollection();

      // Find pending trades where this product is offered
      final offeredTrades = await tradesCollection
          .where('offeredProductIds', arrayContains: product.id)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .get();

      // Find pending trades where this product is requested
      final requestedTrades = await tradesCollection
          .where('requestedProductIds', arrayContains: product.id)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .get();

      final allTrades = [...offeredTrades.docs, ...requestedTrades.docs];

      // Use a set to avoid duplicate notifications
      final notifiedTradeIds = <String>{};

      for (final doc in allTrades) {
        if (notifiedTradeIds.contains(doc.id)) continue;

        final trade = doc.data();
        final conversationId = getConversationId(
          trade.fromUserId,
          trade.toUserId,
        );

        // Determine the other user (the one who needs to be notified)
        // If I am the owner (checked by product.ownerId), I notify the OTHER person in the trade
        // Note: product.ownerId should match one of the trade participants
        String userToNotifyId;
        if (product.ownerId == trade.fromUserId) {
          userToNotifyId = trade.toUserId;
        } else {
          userToNotifyId = trade.fromUserId;
        }

        // Safety check: Don't notify myself if somehow I'm trading with myself or logic is off
        if (userToNotifyId == product.ownerId) continue;

        // 1. Send Chat System Message
        final chatMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: conversationId,
          tradeId: trade.id,
          senderId: 'system',
          text:
              '⚠️ System Alert: The product "${product.title}" in this trade has been updated by the owner. Please review the changes.',
          timestamp: DateTime.now(),
        );

        await sendMessage(chatMessage);

        // 2. Send In-App Notification
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userToNotifyId,
          title: 'Product Updated',
          body:
              'The item "${product.title}" in your pending trade has been updated.',
          type: NotificationType.productUpdate,
          relatedId: trade.id,
          createdAt: DateTime.now(),
        );

        await sendNotification(notification);

        // 3. Send Push Notification
        final recipientToken = await getUserFcmToken(userToNotifyId);
        if (recipientToken != null) {
          await sendPushNotification(
            recipientToken: recipientToken,
            title: 'Product Updated',
            body:
                'The item "${product.title}" in your pending trade has been updated.',
            data: {
              'type': 'productUpdate',
              'tradeId': trade.id,
              'productId': product.id,
            },
          );
        }

        notifiedTradeIds.add(trade.id);
      }
    } catch (e) {
      print('Failed to notify pending trades: $e');
      // Don't throw, as this is a side effect
    }
  }

  // Review Methods
  static Future<void> addReview(ReviewModel review) async {
    try {
      final reviewsCollection = FirebaseFirestore.instance.collection(
        'reviews',
      );
      await reviewsCollection.doc(review.id).set(review.toJson());

      // Notify the user about the new review
      await _sendLocalizedNotification(
        recipientId: review.targetUserId,
        titleKey: 'newReviewTitle',
        bodyKey: 'newReviewBody',
        type: NotificationType.system,
        bodyArgs: {
          'sender': review.reviewerName,
          'rating': review.rating.toString(),
        },
        data: {
          'type': 'new_review',
          'reviewId': review.id,
        },
      );
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  static Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final reviewsCollection = FirebaseFirestore.instance.collection(
        'reviews',
      );
      final snapshot = await reviewsCollection
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reviews: $e');
    }
  }

  // ============ ADMIN METHODS ============

  /// Get all users (admin only)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final usersCollection = _getUsersCollection();
      final querySnapshot = await usersCollection.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Update user role (admin only)
  static Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    try {
      final usersCollection = _getUsersCollection();
      final userDoc = usersCollection.doc(userId);

      await userDoc.update({'role': newRole.name});

      // Update current user if it's the same user
      if (UserModel.currentUser?.id == userId) {
        final updatedUser = await getUserFromFireStore(userId);
        if (updatedUser != null) {
          UserModel.currentUser = updatedUser;
        }
      }
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Suspend user (admin only)
  static Future<void> suspendUser(String userId) async {
    try {
      // Mark all user's products as unavailable
      final productsCollection = _getProductsCollection(null);
      final userProducts =
          await productsCollection.where('ownerId', isEqualTo: userId).get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in userProducts.docs) {
        batch.update(doc.reference, {
          'isAvailable': false,
          'status': ProductStatus.unavailable.name,
        });
      }

      // Reject all pending trades involving this user
      final tradesCollection = _getTradesCollection();
      final sentTrades = await tradesCollection
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final receivedTrades = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in [...sentTrades.docs, ...receivedTrades.docs]) {
        batch.update(doc.reference, {
          'status': TradeStatus.rejected.name,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Delete user and all their data (admin only)
  static Future<void> deleteUserData(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Delete user's products
      final productsCollection = _getProductsCollection(null);
      final userProducts =
          await productsCollection.where('ownerId', isEqualTo: userId).get();

      for (final doc in userProducts.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's trades
      final tradesCollection = _getTradesCollection();
      final sentTrades =
          await tradesCollection.where('fromUserId', isEqualTo: userId).get();

      final receivedTrades =
          await tradesCollection.where('toUserId', isEqualTo: userId).get();

      for (final doc in [...sentTrades.docs, ...receivedTrades.docs]) {
        batch.delete(doc.reference);
      }

      // Delete user document
      final usersCollection = _getUsersCollection();
      batch.delete(usersCollection.doc(userId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Delete product (admin only)
  static Future<void> deleteProductById(
    String productId,
    BuildContext? context,
  ) async {
    try {
      final productsCollection = _getProductsCollection(context);
      await productsCollection.doc(productId).delete();

      // Also reject any pending trades for this product
      final tradesCollection = _getTradesCollection();
      final trades = await tradesCollection
          .where('requestedProductIds', arrayContains: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in trades.docs) {
        batch.update(doc.reference, {
          'status': TradeStatus.rejected.name,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Get all products (admin view)
  static Future<List<ProductModel>> getAllProductsAdmin(
    BuildContext? context,
  ) async {
    try {
      final productsCollection = _getProductsCollection(context);
      final querySnapshot =
          await productsCollection.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  /// Get system statistics (admin only)
  static Future<AdminStats> getSystemStats() async {
    try {
      // Get user counts
      final usersCollection = _getUsersCollection();
      final usersSnapshot = await usersCollection.get();
      final users = usersSnapshot.docs.map((doc) => doc.data()).toList();

      final usersByRole = <String, int>{};
      for (final role in UserRole.values) {
        usersByRole[role.name] = users.where((u) => u.role == role).length;
      }

      // Get product count
      final productsCollection = _getProductsCollection(null);
      final productsSnapshot = await productsCollection.get();

      // Get trade counts
      final tradesCollection = _getTradesCollection();
      final tradesSnapshot = await tradesCollection.get();
      final trades = tradesSnapshot.docs.map((doc) => doc.data()).toList();

      final activeTrades =
          trades.where((t) => t.status == TradeStatus.accepted).length;
      final completedTrades =
          trades.where((t) => t.status == TradeStatus.completed).length;
      final pendingTrades =
          trades.where((t) => t.status == TradeStatus.pending).length;

      return AdminStats(
        totalUsers: users.length,
        totalProducts: productsSnapshot.docs.length,
        totalTrades: trades.length,
        activeTrades: activeTrades,
        completedTrades: completedTrades,
        pendingTrades: pendingTrades,
        usersByRole: usersByRole,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get system stats: $e');
    }
  }

  /// Search users by name or email (admin only)
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final usersCollection = _getUsersCollection();
      final querySnapshot = await usersCollection.get();
      final users = querySnapshot.docs.map((doc) => doc.data()).toList();

      final lowerQuery = query.toLowerCase();
      return users.where((user) {
        return user.name.toLowerCase().contains(lowerQuery) ||
            user.email.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // ==================== Category Management ====================

  static CollectionReference<CategorySuggestion>
      _getCategorySuggestionsCollection() {
    return FirebaseFirestore.instance
        .collection('CategorySuggestions')
        .withConverter<CategorySuggestion>(
          fromFirestore: (snapshot, _) =>
              CategorySuggestion.fromJson(snapshot.data()!),
          toFirestore: (suggestion, _) => suggestion.toJson(),
        );
  }

  static CollectionReference<ApprovedCategory>
      _getApprovedCategoriesCollection() {
    return FirebaseFirestore.instance
        .collection('ApprovedCategories')
        .withConverter<ApprovedCategory>(
          fromFirestore: (snapshot, _) =>
              ApprovedCategory.fromJson(snapshot.data()!),
          toFirestore: (category, _) => category.toJson(),
        );
  }

  /// Suggest a new category
  static Future<String> suggestCategory({
    required String name,
    required String userId,
    required String userName,
  }) async {
    try {
      // Check if category already exists (case-insensitive)
      final existingApproved = await getApprovedCategories();
      if (existingApproved.any(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      )) {
        throw Exception('This category already exists');
      }

      // Check if already suggested
      final existingSuggestions = await _getCategorySuggestionsCollection()
          .where('status', isEqualTo: 'pending')
          .get();

      final hasPending = existingSuggestions.docs.any(
        (doc) => doc.data().suggestedName.toLowerCase() == name.toLowerCase(),
      );

      if (hasPending) {
        throw Exception(
          'This category has already been suggested and is pending approval',
        );
      }

      final docRef = _getCategorySuggestionsCollection().doc();
      final suggestion = CategorySuggestion(
        id: docRef.id,
        suggestedName: name,
        suggestedBy: userId,
        suggestedByName: userName,
        createdAt: DateTime.now(),
      );

      await docRef.set(suggestion);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to suggest category: $e');
    }
  }

  /// Get all category suggestions (admin only)
  static Future<List<CategorySuggestion>> getCategorySuggestions({
    CategoryStatus? status,
  }) async {
    try {
      Query<CategorySuggestion> query = _getCategorySuggestionsCollection();

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get category suggestions: $e');
    }
  }

  /// Approve a category suggestion
  static Future<void> approveCategorySuggestion({
    required String suggestionId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      final suggestionDoc =
          await _getCategorySuggestionsCollection().doc(suggestionId).get();

      if (!suggestionDoc.exists) {
        throw Exception('Suggestion not found');
      }

      final suggestion = suggestionDoc.data()!;

      // Update suggestion status
      await _getCategorySuggestionsCollection().doc(suggestionId).update({
        'status': CategoryStatus.approved.name,
        'reviewedBy': adminId,
        'reviewedByName': adminName,
        'reviewedAt': DateTime.now().toIso8601String(),
      });

      // Add to approved categories
      final approvedDoc = _getApprovedCategoriesCollection().doc();
      final approvedCategory = ApprovedCategory(
        id: approvedDoc.id,
        name: suggestion.suggestedName,
        addedBy: adminId,
        addedByName: adminName,
        addedAt: DateTime.now(),
      );

      await approvedDoc.set(approvedCategory);

      // Update products with this custom category
      await _updateProductsWithApprovedCategory(
        suggestion.suggestedName,
        suggestion.suggestedName,
      );
    } catch (e) {
      throw Exception('Failed to approve category: $e');
    }
  }

  /// Reject a category suggestion
  static Future<void> rejectCategorySuggestion({
    required String suggestionId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _getCategorySuggestionsCollection().doc(suggestionId).update({
        'status': CategoryStatus.rejected.name,
        'reviewedBy': adminId,
        'reviewedByName': adminName,
        'reviewedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to reject category: $e');
    }
  }

  /// Get all approved custom categories
  static Future<List<ApprovedCategory>> getApprovedCategories() async {
    try {
      final snapshot =
          await _getApprovedCategoriesCollection().orderBy('name').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get approved categories: $e');
    }
  }

  /// Update products when a custom category is approved
  static Future<void> _updateProductsWithApprovedCategory(
    String customCategoryName,
    String approvedCategoryName,
  ) async {
    try {
      final productsSnapshot = await _getProductsCollection(
        null,
      ).where('customCategory', isEqualTo: customCategoryName).get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in productsSnapshot.docs) {
        batch.update(doc.reference, {
          'category': approvedCategoryName,
          'customCategory': null, // Clear the custom category field
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating products with approved category: $e');
    }
  }

  /// Delete a category suggestion
  static Future<void> deleteCategorySuggestion(String suggestionId) async {
    try {
      await _getCategorySuggestionsCollection().doc(suggestionId).delete();
    } catch (e) {
      throw Exception('Failed to delete category suggestion: $e');
    }
  }
}
