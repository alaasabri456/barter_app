import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../features/authentication/models/login_request.dart';
import '../features/products/models/product_model.dart';
import '../features/authentication/models/register_request.dart';
import '../features/trade/models/trade_offer.dart';
import '../features/authentication/models/user_model.dart';
import '../features/chat/models/chat_message.dart';
import '../features/reviews/models/review_model.dart';
import '../features/admin/models/admin_stats_model.dart';
import '../features/admin/models/category_suggestion_model.dart';

class FirebaseService {
  static Future<UserCredential> register(RegisterRequest request) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: request.email,
          password: request.password,
        );
    return userCredential;
  }

  static Future<UserCredential> login(LoginRequest request) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: request.email,
          password: request.password,
        );
    return userCredential;
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

  static CollectionReference<ProductModel> _getProductsCollection(
    BuildContext? context,
  ) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference<ProductModel> productsCollection = db
        .collection("Products")
        .withConverter<ProductModel>(
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

  static Future<List<ProductModel>> getProductsFromFireStore(
    BuildContext context,
  ) async {
    CollectionReference<ProductModel> productsCollection =
        _getProductsCollection(context);
    QuerySnapshot<ProductModel> querySnapshot = await productsCollection
        .orderBy("createdAt", descending: true)
        .get();
    List<ProductModel> products = querySnapshot.docs
        .map((documentSnapshot) => documentSnapshot.data())
        .toList();
    return products;
  }

  static Future<String> uploadProductImage(
    File imageFile,
    String fileName,
  ) async {
    try {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('$fileName.jpg');

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<List<String>> uploadProductImages(
    List<String> imagePaths,
    String userId,
  ) async {
    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < imagePaths.length; i++) {
        final File imageFile = File(imagePaths[i]);
        final String fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
        final String downloadUrl = await uploadProductImage(
          imageFile,
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
    return db
        .collection("Trades")
        .withConverter<TradeOffer>(
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
    return db
        .collection("TradeHistory")
        .withConverter<TradeHistory>(
          fromFirestore: (snapshot, _) =>
              TradeHistory.fromJson(snapshot.data()!),
          toFirestore: (history, _) => history.toJson(),
        );
  }

  static Future<String> createTradeOffer(TradeOffer trade) async {
    try {
      print('=== DEBUG: Creating trade offer ===');
      print('From: ${trade.fromUserId} (${trade.fromUserName})');
      print('To: ${trade.toUserId} (${trade.toUserName})');
      print('Offered Products: ${trade.offeredProductIds}');
      print('Requested Products: ${trade.requestedProductIds}');
      print('Type: ${trade.type}');
      print('Status: ${trade.status}');

      final tradesCollection = _getTradesCollection();
      final tradeDoc = tradesCollection.doc();

      final tradeWithId = trade.copyWith(id: tradeDoc.id);

      print('=== DEBUG: Saving trade to Firestore with ID: ${tradeDoc.id} ===');

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

      print(
        '=== DEBUG: Trade created successfully with ID: ${tradeDoc.id} ===',
      );

      return tradeDoc.id;
    } catch (e) {
      print('=== DEBUG: ERROR creating trade offer: $e ===');
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
      print('=== DEBUG: Checking received trades for user: $userId ===');

      final tradesCollection = _getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .get();

      print(
        '=== DEBUG: Found ${querySnapshot.docs.length} trades for user $userId ===',
      );

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

      await tradeDoc.update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });

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
          'counterOffers': updatedCounterOffers
              .map((co) => co.toJson())
              .toList(),
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
        final trade = doc.data();
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
      print('=== DEBUG: Products collection reference created ===');

      // First, try a simple query to see if we can get any data
      final testQuery = await productsCollection.limit(1).get();
      print('=== DEBUG: Test query successful, collection exists ===');

      // Now query for user's products
      final querySnapshot = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
        '=== DEBUG: Query completed, found ${querySnapshot.docs.length} documents ===',
      );

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
      final status =
          newStatus ??
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

  static Future<void> rejectOtherTradeOffers({
    required String productId,
    required String acceptedTradeId,
  }) async {
    try {
      // Get all pending trades for this product except the accepted one
      final querySnapshot = await FirebaseFirestore.instance
          .collection('trades')
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Batch update to reject all other trades
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        if (doc.id != acceptedTradeId) {
          batch.update(doc.reference, {
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
            'rejectedReason': 'Product no longer available',
          });
        }
      }

      await batch.commit();
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
          email:
              UserModel.currentUser?.email ??
              FirebaseAuth.instance.currentUser?.email ??
              '',
          name:
              UserModel.currentUser?.name ??
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
      final messagesCollection = tradesCollection
          .doc(message.tradeId)
          .collection('messages');

      await messagesCollection.doc(message.id).set(message.toJson());

      // Update trade with last message info for preview
      await tradesCollection.doc(message.tradeId).update({
        'lastMessage': message.text,
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
      final messagesCollection = tradesCollection
          .doc(tradeId)
          .collection('messages');

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

  /// Send a message in a conversation
  static Future<void> sendConversationMessage(
    ChatMessage message,
    String conversationId,
  ) async {
    try {
      print('=== DEBUG: Sending message to conversation: $conversationId ===');
      final conversationsCollection = _getConversationsCollection();
      final messagesCollection = conversationsCollection
          .doc(conversationId)
          .collection('messages');

      await messagesCollection.doc(message.id).set(message.toJson());

      // Update conversation with last message info
      await conversationsCollection.doc(conversationId).update({
        'lastMessage': message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
      final messagesCollection = conversationsCollection
          .doc(conversationId)
          .collection('messages');

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
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Review Methods
  static Future<void> addReview(ReviewModel review) async {
    try {
      final reviewsCollection = FirebaseFirestore.instance.collection(
        'reviews',
      );
      await reviewsCollection.doc(review.id).set(review.toJson());
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
      final userProducts = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .get();

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
      final userProducts = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .get();

      for (final doc in userProducts.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's trades
      final tradesCollection = _getTradesCollection();
      final sentTrades = await tradesCollection
          .where('fromUserId', isEqualTo: userId)
          .get();

      final receivedTrades = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .get();

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
      final querySnapshot = await productsCollection
          .orderBy('createdAt', descending: true)
          .get();

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

      final activeTrades = trades
          .where((t) => t.status == TradeStatus.accepted)
          .length;
      final completedTrades = trades
          .where((t) => t.status == TradeStatus.completed)
          .length;
      final pendingTrades = trades
          .where((t) => t.status == TradeStatus.pending)
          .length;

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
      final suggestionDoc = await _getCategorySuggestionsCollection()
          .doc(suggestionId)
          .get();

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
      final snapshot = await _getApprovedCategoriesCollection()
          .orderBy('name')
          .get();
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
