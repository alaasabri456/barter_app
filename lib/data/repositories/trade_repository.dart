// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';
import '../../features/trade/models/trade_offer.dart';
import '../services/notification_service.dart';

/// Repository responsible for all trade-related data operations.
class TradeRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  TradeRepository({
    FirebaseFirestore? firestore,
    required NotificationService notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService;

  // ─── Collection helpers ───────────────────────────────────────────────

  CollectionReference<TradeOffer> getTradesCollection() {
    return _firestore.collection("Trades").withConverter<TradeOffer>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return TradeOffer.fromJson(data);
          },
          toFirestore: (trade, _) => trade.toJson(),
        );
  }

  CollectionReference<TradeHistory> _getTradeHistoryCollection() {
    return _firestore.collection("TradeHistory").withConverter<TradeHistory>(
          fromFirestore: (snapshot, _) =>
              TradeHistory.fromJson(snapshot.data()!),
          toFirestore: (history, _) => history.toJson(),
        );
  }

  CollectionReference<ProductModel> _getProductsCollection() {
    return _firestore.collection("Products").withConverter<ProductModel>(
          fromFirestore: (snapshot, _) =>
              ProductModel.fromJson(snapshot.data()!),
          toFirestore: (product, _) => product.toJson(),
        );
  }

  // ─── Trade CRUD ───────────────────────────────────────────────────────

  Future<String> createTradeOffer(TradeOffer trade) async {
    try {
      final tradesCollection = getTradesCollection();
      final tradeDoc = tradesCollection.doc();

      // Auto-detect counter offer
      String? parentTradeId;
      bool isCounterOffer = trade.isCounterOffer;

      if (!isCounterOffer) {
        final existingTrades = await getPendingTradesForProduct(
          trade.requestedProductIds.first,
        );
        final competingTrades = existingTrades
            .where((t) => t.fromUserId != trade.fromUserId)
            .toList();

        if (competingTrades.isNotEmpty) {
          isCounterOffer = true;
          parentTradeId = competingTrades.first.id;
        }
      }

      final tradeWithId = trade.copyWith(
        id: tradeDoc.id,
        isCounterOffer: isCounterOffer,
        parentTradeId: parentTradeId ?? trade.parentTradeId,
        isFromPremium: UserModel.currentUser?.isPremium ?? false,
      );

      await tradeDoc.set(tradeWithId);

      // Add to trade history
      final action =
          isCounterOffer ? 'COUNTER_OFFER_CREATED' : 'TRADE_CREATED';
      await _addTradeHistory(
        tradeId: tradeDoc.id,
        action: action,
        performedByUserId: trade.fromUserId,
        performedByUserName: trade.fromUserName,
        details: {
          'type': trade.type.name,
          'offeredProducts': trade.offeredProductIds,
          'requestedProducts': trade.requestedProductIds,
          if (parentTradeId != null) 'parentTradeId': parentTradeId,
        },
      );

      // Send Push Notification
      final titleKey = isCounterOffer ? 'counterOfferTitle' : 'newOfferTitle';
      final bodyKey = isCounterOffer ? 'counterOfferBody' : 'newOfferBody';
      _notificationService.sendLocalizedNotification(
        recipientId: trade.toUserId,
        titleKey: titleKey,
        bodyKey: bodyKey,
        bodyArgs: {'sender': trade.fromUserName},
        data: {
          'type': isCounterOffer ? 'counter_offer' : 'trade_offer',
          'tradeId': tradeDoc.id,
        },
      );

      return tradeDoc.id;
    } catch (e) {
      throw Exception('Failed to create trade offer: $e');
    }
  }

  Future<void> updateTradeStatus({
    required String tradeId,
    required TradeStatus newStatus,
    required String userId,
    required String userName,
  }) async {
    try {
      final tradesCollection = getTradesCollection();
      final tradeDoc = tradesCollection.doc(tradeId);

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
        final allProductIds = {
          ...trade.offeredProductIds,
          ...trade.requestedProductIds
        };
        for (final pid in allProductIds) {
          await _updateProductAvailability(
            productId: pid,
            isAvailable: false,
            newStatus: ProductStatus.traded,
          );
        }
      } else if ((newStatus == TradeStatus.rejected ||
              newStatus == TradeStatus.cancelled) &&
          oldStatus == TradeStatus.accepted) {
        final allProductIds = {
          ...trade.offeredProductIds,
          ...trade.requestedProductIds
        };
        for (final pid in allProductIds) {
          await _updateProductAvailability(
            productId: pid,
            isAvailable: true,
            newStatus: ProductStatus.available,
          );
        }
      }

      // Send Notification
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

      await _notificationService.sendLocalizedNotification(
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

  Future<void> addDeliveryProvidedByUser({
    required String tradeId,
    required String userId,
  }) async {
    try {
      final tradesCollection = getTradesCollection();
      await tradesCollection.doc(tradeId).update({
        'deliveryProvidedBy': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update delivery provided status: $e');
    }
  }

  // ─── Trade queries ────────────────────────────────────────────────────

  Future<List<TradeOffer>> getPendingTradesForProduct(
      String productId) async {
    try {
      final tradesCollection = getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('requestedProductIds', arrayContains: productId)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting pending trades for product: $e');
      return [];
    }
  }

  Future<List<TradeOffer>> getCounterOffersForTrade(
      String parentTradeId) async {
    try {
      final tradesCollection = getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('parentTradeId', isEqualTo: parentTradeId)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting counter offers: $e');
      return [];
    }
  }

  Future<int> getPendingTradeCountForProduct(String productId) async {
    try {
      final trades = await getPendingTradesForProduct(productId);
      return trades.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isProductInPendingTrade(String productId) async {
    try {
      final tradesCollection = getTradesCollection();

      final offeredQuery = await tradesCollection
          .where('offeredProductIds', arrayContains: productId)
          .where('status', isEqualTo: TradeStatus.pending.name)
          .limit(1)
          .get();

      if (offeredQuery.docs.isNotEmpty) return true;

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

  Future<bool> isDuplicateTrade({
    required String userId,
    required String targetProductId,
    required List<String> offeredProductIds,
  }) async {
    try {
      final tradesCollection = getTradesCollection();

      final sentTrades = await tradesCollection
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('requestedProductIds', arrayContains: targetProductId)
          .get();

      for (final doc in sentTrades.docs) {
        final trade = doc.data();
        final existingOffered = Set<String>.from(trade.offeredProductIds);
        final newOffered = Set<String>.from(offeredProductIds);

        if (existingOffered.length == newOffered.length &&
            existingOffered.containsAll(newOffered)) {
          return true;
        }
      }

      final receivedTrades = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in receivedTrades.docs) {
        final trade = doc.data();
        final theyOffer = Set<String>.from(trade.offeredProductIds);
        final theyRequest = Set<String>.from(trade.requestedProductIds);
        final weOffer = Set<String>.from(offeredProductIds);
        final weRequest = {targetProductId};

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
      return false;
    }
  }

  Future<List<TradeOffer>> getReceivedTrades(String userId) async {
    try {
      final tradesCollection = getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted'])
          .orderBy('createdAt', descending: true)
          .get();

      final trades = querySnapshot.docs.map((doc) => doc.data()).toList();

      trades.sort((a, b) {
        if (a.isFromPremium != b.isFromPremium) {
          return a.isFromPremium ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return trades;
    } catch (e) {
      throw Exception('Failed to get received trades: $e');
    }
  }

  Stream<List<TradeOffer>> streamReceivedTrades(String userId) {
    final tradesCollection = getTradesCollection();
    return tradesCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots()
        .map((snapshot) {
      final trades = snapshot.docs.map((doc) => doc.data()).toList();
      trades.sort((a, b) {
        if (a.isFromPremium != b.isFromPremium) {
          return a.isFromPremium ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return trades;
    });
  }

  Future<List<TradeOffer>> getSentTrades(String userId) async {
    try {
      final tradesCollection = getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final trades = querySnapshot.docs.map((doc) => doc.data()).toList();
      trades.sort((a, b) {
        if (a.isFromPremium != b.isFromPremium) {
          return a.isFromPremium ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return trades;
    } catch (e) {
      throw Exception('Failed to get sent trades: $e');
    }
  }

  Stream<List<TradeOffer>> streamSentTrades(String userId) {
    final tradesCollection = getTradesCollection();
    return tradesCollection
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final trades = snapshot.docs.map((doc) => doc.data()).toList();
      trades.sort((a, b) {
        if (a.isFromPremium != b.isFromPremium) {
          return a.isFromPremium ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return trades;
    });
  }

  Future<TradeOffer?> getAcceptedTradeBetweenUsers({
    required String userId1,
    required String userId2,
    required String productId,
  }) async {
    try {
      final tradesCollection = getTradesCollection();

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

  // ─── Counter offers ───────────────────────────────────────────────────

  Future<void> addCounterOffer({
    required String tradeId,
    required TradeCounterOffer counterOffer,
    required String userId,
    required String userName,
  }) async {
    try {
      final tradesCollection = getTradesCollection();
      final tradeDoc = tradesCollection.doc(tradeId);

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

        await _addTradeHistory(
          tradeId: tradeId,
          action: 'COUNTER_OFFER_ADDED',
          performedByUserId: userId,
          performedByUserName: userName,
          details: {'counterOfferId': counterOffer.id},
        );

        _notificationService.sendLocalizedNotification(
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

  Future<void> acceptCounterOffer({
    required String tradeId,
    required String counterOfferId,
    required String userId,
    required String userName,
  }) async {
    try {
      final tradesCollection = getTradesCollection();
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

  // ─── Trade history ────────────────────────────────────────────────────

  Future<List<TradeHistory>> getTradeHistory(String tradeId) async {
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

  Future<void> checkAndExpireTrades() async {
    try {
      final tradesCollection = getTradesCollection();
      final now = Timestamp.now();

      final querySnapshot = await tradesCollection
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        final tradeDoc = tradesCollection.doc(doc.id);
        batch.update(tradeDoc, {
          'status': TradeStatus.expired.name,
          'updatedAt': now,
        });

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

  Future<void> rejectOtherTradeOffers({
    required String productId,
    required String acceptedTradeId,
  }) async {
    try {
      final tradesCollection = getTradesCollection();
      final querySnapshot = await tradesCollection
          .where('requestedProductIds', arrayContains: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
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
          'Auto-rejected $rejectedCount other trade offers for product $productId');
    } catch (e) {
      print('Error rejecting other trades: $e');
    }
  }

  Future<void> debugCheckReceivedTrades(String userId) async {
    try {
      final tradesCollection = getTradesCollection();
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

  // ─── Private helpers ──────────────────────────────────────────────────

  Future<void> _addTradeHistory({
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

  Future<void> _rejectConflictingTrades({
    required TradeOffer acceptedTrade,
    required String excludingTradeId,
  }) async {
    try {
      final tradesCollection = getTradesCollection();
      final allProductsInAcceptedTrade = {
        ...acceptedTrade.offeredProductIds,
        ...acceptedTrade.requestedProductIds
      };

      final conflictingTrades =
          <String, QueryDocumentSnapshot<TradeOffer>>{};

      final productList = allProductsInAcceptedTrade.toList();
      const chunkSize = 10;

      for (var i = 0; i < productList.length; i += chunkSize) {
        final chunk = productList.sublist(
            i,
            i + chunkSize > productList.length
                ? productList.length
                : i + chunkSize);

        final q1 = await tradesCollection
            .where('status', isEqualTo: TradeStatus.pending.name)
            .where('requestedProductIds', arrayContainsAny: chunk)
            .get();
        for (var doc in q1.docs) {
          if (doc.id != excludingTradeId) conflictingTrades[doc.id] = doc;
        }

        final q2 = await tradesCollection
            .where('status', isEqualTo: TradeStatus.pending.name)
            .where('offeredProductIds', arrayContainsAny: chunk)
            .get();
        for (var doc in q2.docs) {
          if (doc.id != excludingTradeId) conflictingTrades[doc.id] = doc;
        }
      }

      if (conflictingTrades.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in conflictingTrades.values) {
        final otherTrade = doc.data();

        batch.update(doc.reference, {
          'status': TradeStatus.rejected.name,
          'updatedAt': Timestamp.now(),
          'rejectionReason': 'Item no longer available',
        });

        await _notificationService.sendLocalizedNotification(
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

  Future<void> _updateProductAvailability({
    required String productId,
    required bool isAvailable,
    ProductStatus? newStatus,
  }) async {
    try {
      final status = newStatus ??
          (isAvailable ? ProductStatus.available : ProductStatus.unavailable);

      await _firestore.collection('Products').doc(productId).update({
        'isAvailable': isAvailable,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product availability: $e');
    }
  }
}
