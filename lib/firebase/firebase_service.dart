import 'dart:io';
import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/login_request.dart';
import '../models/product_model.dart';
import '../models/register_request.dart';
import '../models/trade_offer.dart';
import '../models/user_model.dart';


class FirebaseService {
  static Future<UserCredential> register(RegisterRequest request) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
        email: request.email, password: request.password);
    return userCredential;
  }


  static Future<UserCredential> login(LoginRequest request) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
        email: request.email, password: request.password);
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
    DocumentReference<UserModel> usersDocument=usersCollection.doc(user.id);
    return usersDocument.set(user);
  }

  static Future<UserModel?> getUserFromFireStore(String uid) async {
    CollectionReference<UserModel> usersCollection = _getUsersCollection();
    DocumentReference<UserModel> usersDocument=usersCollection.doc(uid);
    DocumentSnapshot<UserModel> documentSnapshot =await usersDocument.get();
    return documentSnapshot.data();
  }
  static CollectionReference<ProductModel> _getProductsCollection(BuildContext context) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference<ProductModel> productsCollection = db
        .collection("Products")
        .withConverter<ProductModel>(
      fromFirestore: (snapshot, _) => ProductModel.fromJson(snapshot.data()!),
      toFirestore: (product, _) => product.toJson(),
    );
    return productsCollection;
  }


  static Future<void> addProductToFireStore(ProductModel product, BuildContext context,) {
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


   static  Future<List<ProductModel>>  getProductsFromFireStore(BuildContext context)async{
    CollectionReference<ProductModel> productsCollection =_getProductsCollection(context);
    QuerySnapshot<ProductModel> querySnapshot=await productsCollection.orderBy("createdAt",descending: true).get();
    List<ProductModel>products= querySnapshot.docs.map((documentSnapshot)=>documentSnapshot.data()).toList();
     return products;
   }
  static Future<String> uploadProductImage(File imageFile, String fileName) async {
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
  static Future<List<String>> uploadProductImages(List<String> imagePaths, String userId) async {
    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < imagePaths.length; i++) {
        final File imageFile = File(imagePaths[i]);
        final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
        final String downloadUrl = await uploadProductImage(imageFile, fileName);
        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }

  }



  // static const int maxImageSize = 800; // Max width/height for compressed images
  // static const int imageQuality = 80; // JPEG quality (0-100)
  //
  // static Future<String> compressAndConvertToBase64(File imageFile) async {
  // try {
  // final originalBytes = await imageFile.readAsBytes();
  //
  // // Check file size - if it's too large, compress it
  // if (originalBytes.length > 1024 * 1024) { // 1MB
  // final originalImage = img.decodeImage(originalBytes);
  // if (originalImage == null) {
  // throw Exception('Failed to decode image');
  // }
  //
  // // Resize image if it's too large
  // final resizedImage = img.copyResize(
  // originalImage,
  // width: maxImageSize,
  // height: maxImageSize,
  // maintainAspect: true,
  // );

  // // Convert to JPEG with compression
  // final compressedBytes = img.encodeJpg(resizedImage, quality: imageQuality);
  // return base64Encode(compressedBytes);
  // } else {
  // // Image is small enough, use as-is
  // return base64Encode(originalBytes);
  // }
  // } catch (e) {
  // throw Exception('Failed to process image: $e');
  // }
  // }
  //
  // static Future<List<String>> uploadProductImages(List<String> imagePaths, String userId) async {
  // try {
  // List<String> base64Images = [];
  //
  // for (int i = 0; i < imagePaths.length; i++) {
  // final File imageFile = File(imagePaths[i]);
  // final String base64String = await compressAndConvertToBase64(imageFile);
  // // Store with data URL format for easy display
  // base64Images.add('data:image/jpeg;base64,$base64String');
  // }
  //
  // return base64Images;
  // } catch (e) {
  // throw Exception('Failed to process images: $e');
  // }
  // }
  //
  // // Your existing method for adding product to Firestore
  // static Future<void> addProductToFireStore(ProductModel product, BuildContext context) async {
  // try {
  // await FirebaseFirestore.instance
  //     .collection('products')
  //     .doc(product.id)
  //     .set(product.toJson());
  // } catch (e) {
  // throw Exception('Failed to save product: $e');
  // }
  // }



  static CollectionReference<TradeOffer> _getTradesCollection() {
  FirebaseFirestore db = FirebaseFirestore.instance;
  return db.collection("Trades").withConverter<TradeOffer>(
  fromFirestore: (snapshot, _) => TradeOffer.fromJson(snapshot.data()!),
  toFirestore: (trade, _) => trade.toJson(),
  );
  }

  static CollectionReference<TradeHistory> _getTradeHistoryCollection() {
  FirebaseFirestore db = FirebaseFirestore.instance;
  return db.collection("TradeHistory").withConverter<TradeHistory>(
  fromFirestore: (snapshot, _) => TradeHistory.fromJson(snapshot.data()!),
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
  details: {'type': trade.type.name},
  );

  return tradeDoc.id;
  } catch (e) {
  throw Exception('Failed to create trade offer: $e');
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
  final updatedCounterOffers = [...currentTrade.counterOffers, counterOffer];

  await tradeDoc.update({
  'counterOffers': updatedCounterOffers.map((co) => co.toJson()).toList(),
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
  (co) => co.id == counterOfferId
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

  static Future<List<ProductModel>> getUserProducts(String userId,BuildContext context) async {
    try {
      final productsCollection = _getProductsCollection(context);
      final querySnapshot = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get user products: $e');
    }
  }

  // If you need to get products by IDs (for trade details)
  static Future<List<ProductModel>> getProductsByIds(List<String> productIds,BuildContext context) async {
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
  static Future<ProductModel?> getProductById(String productId,BuildContext context) async {
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

}