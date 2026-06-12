// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/admin/models/admin_stats_model.dart';
import '../../features/admin/models/report_model.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';
import '../../features/trade/models/trade_offer.dart';

/// Repository responsible for admin-only data operations.
class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Collection helpers ───────────────────────────────────────────────

  CollectionReference<UserModel> _getUsersCollection() {
    return _firestore.collection("Users").withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  CollectionReference<ProductModel> _getProductsCollection() {
    return _firestore.collection("Products").withConverter<ProductModel>(
          fromFirestore: (snapshot, _) =>
              ProductModel.fromJson(snapshot.data()!),
          toFirestore: (product, _) => product.toJson(),
        );
  }

  CollectionReference<TradeOffer> _getTradesCollection() {
    return _firestore.collection("Trades").withConverter<TradeOffer>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return TradeOffer.fromJson(data);
          },
          toFirestore: (trade, _) => trade.toJson(),
        );
  }

  // ─── User management ─────────────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() async {
    try {
      final usersCollection = _getUsersCollection();
      final querySnapshot = await usersCollection.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _getUsersCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<List<UserModel>> searchUsers(String query) async {
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

  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    try {
      final usersCollection = _getUsersCollection();
      final userDoc = usersCollection.doc(userId);

      await userDoc.update({'role': newRole.name});

      if (UserModel.currentUser?.id == userId) {
        final updatedUser = await _getUserFromFireStore(userId);
        if (updatedUser != null) {
          UserModel.currentUser = updatedUser;
        }
      }
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<void> suspendUser(String userId) async {
    try {
      final productsCollection = _getProductsCollection();
      final userProducts =
          await productsCollection.where('ownerId', isEqualTo: userId).get();

      final batch = _firestore.batch();

      for (final doc in userProducts.docs) {
        batch.update(doc.reference, {
          'isAvailable': false,
          'status': ProductStatus.unavailable.name,
        });
      }

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

      final usersCollection = _getUsersCollection();
      batch.update(usersCollection.doc(userId), {'isSuspended': true});

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  Future<void> unsuspendUser(String userId) async {
    try {
      final batch = _firestore.batch();

      final usersCollection = _getUsersCollection();
      batch.update(usersCollection.doc(userId), {'isSuspended': false});

      final productsCollection = _getProductsCollection();
      final userProducts = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: ProductStatus.unavailable.name)
          .get();

      for (final doc in userProducts.docs) {
        batch.update(doc.reference, {
          'isAvailable': true,
          'status': ProductStatus.available.name,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unsuspend user: $e');
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      final productsCollection = _getProductsCollection();
      final userProducts =
          await productsCollection.where('ownerId', isEqualTo: userId).get();

      for (final doc in userProducts.docs) {
        batch.delete(doc.reference);
      }

      final tradesCollection = _getTradesCollection();
      final sentTrades =
          await tradesCollection.where('fromUserId', isEqualTo: userId).get();

      final receivedQuery =
          await tradesCollection.where('toUserId', isEqualTo: userId).get();

      for (final doc in [...sentTrades.docs, ...receivedQuery.docs]) {
        batch.delete(doc.reference);
      }

      final usersCollection = _getUsersCollection();
      batch.delete(usersCollection.doc(userId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // ─── Product management ───────────────────────────────────────────────

  Future<void> deleteProductById(String productId) async {
    try {
      final productsCollection = _getProductsCollection();
      await productsCollection.doc(productId).delete();

      final tradesCollection = _getTradesCollection();
      final trades = await tradesCollection
          .where('requestedProductIds', arrayContains: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
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

  Future<List<ProductModel>> getAllProductsAdmin() async {
    try {
      final productsCollection = _getProductsCollection();
      final querySnapshot =
          await productsCollection.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  // ─── Admin helpers ────────────────────────────────────────────────────

  Future<List<String>> getAdminEmails() async {
    try {
      final usersCollection = _getUsersCollection();
      final snapshot = await usersCollection.get();
      final admins = snapshot.docs
          .map((doc) => doc.data())
          .where((user) => user.role == UserRole.admin)
          .toList();
      return admins.map((u) => u.email).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> getAdminUsers() async {
    try {
      final usersCollection = _getUsersCollection();
      final snapshot = await usersCollection.get();
      return snapshot.docs
          .map((doc) => doc.data())
          .where((user) => user.role == UserRole.admin)
          .toList();
    } catch (e) {
      print('Error getting admin users: $e');
      return [];
    }
  }

  // ─── Statistics ───────────────────────────────────────────────────────

  Future<AdminStats> getSystemStats() async {
    try {
      final usersSnapshot = await _getUsersCollection().get();
      final users = usersSnapshot.docs.map((doc) => doc.data()).toList();

      final usersByRole = <String, int>{};
      for (final role in UserRole.values) {
        usersByRole[role.name] = users.where((u) => u.role == role).length;
      }

      final productsSnapshot = await _getProductsCollection().get();

      final tradesSnapshot = await _getTradesCollection().get();
      final trades = tradesSnapshot.docs.map((doc) => doc.data()).toList();

      final activeTrades =
          trades.where((t) => t.status == TradeStatus.accepted).length;
      final completedTrades =
          trades.where((t) => t.status == TradeStatus.completed).length;
      final pendingTrades =
          trades.where((t) => t.status == TradeStatus.pending).length;

      final reportsSnapshot =
          await _firestore.collection('Reports').get();
      final totalReports = reportsSnapshot.docs.length;
      final pendingReports = reportsSnapshot.docs.where((doc) {
        final data = doc.data();
        return (data['status'] ?? 'pending') == 'pending';
      }).length;

      return AdminStats(
        totalUsers: users.length,
        totalProducts: productsSnapshot.docs.length,
        totalTrades: trades.length,
        activeTrades: activeTrades,
        completedTrades: completedTrades,
        pendingTrades: pendingTrades,
        usersByRole: usersByRole,
        totalReports: totalReports,
        pendingReports: pendingReports,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get system stats: $e');
    }
  }

  Stream<AdminStats> streamSystemStats() {
    final controller = StreamController<AdminStats>();

    QuerySnapshot<UserModel>? latestUsers;
    QuerySnapshot<ProductModel>? latestProducts;
    QuerySnapshot<TradeOffer>? latestTrades;
    QuerySnapshot? latestReports;

    void emitUpdate() {
      if (latestUsers == null ||
          latestProducts == null ||
          latestTrades == null ||
          latestReports == null) {
        return;
      }

      final users = latestUsers!.docs.map((doc) => doc.data()).toList();

      final usersByRole = <String, int>{};
      for (final role in UserRole.values) {
        usersByRole[role.name] = users.where((u) => u.role == role).length;
      }

      final trades = latestTrades!.docs.map((doc) => doc.data()).toList();

      final activeTrades =
          trades.where((t) => t.status == TradeStatus.accepted).length;
      final completedTrades =
          trades.where((t) => t.status == TradeStatus.completed).length;
      final pendingTrades =
          trades.where((t) => t.status == TradeStatus.pending).length;

      final totalReports = latestReports!.docs.length;
      final pendingReports = latestReports!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['status'] ?? 'pending') == 'pending';
      }).length;

      final stats = AdminStats(
        totalUsers: users.length,
        totalProducts: latestProducts!.docs.length,
        totalTrades: trades.length,
        activeTrades: activeTrades,
        completedTrades: completedTrades,
        pendingTrades: pendingTrades,
        usersByRole: usersByRole,
        totalReports: totalReports,
        pendingReports: pendingReports,
        lastUpdated: DateTime.now(),
      );
      controller.add(stats);
    }

    final subs = [
      _getUsersCollection().snapshots().listen((snap) {
        latestUsers = snap;
        emitUpdate();
      }),
      _getProductsCollection().snapshots().listen((snap) {
        latestProducts = snap;
        emitUpdate();
      }),
      _getTradesCollection().snapshots().listen((snap) {
        latestTrades = snap;
        emitUpdate();
      }),
      _firestore.collection('Reports').snapshots().listen((snap) {
        latestReports = snap;
        emitUpdate();
      }),
    ];

    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  Stream<Map<String, int>> streamProfileStats(String userId) {
    final controller = StreamController<Map<String, int>>();

    QuerySnapshot<ProductModel>? latestProducts;
    QuerySnapshot<TradeOffer>? latestReceivedTrades;
    QuerySnapshot<TradeOffer>? latestSentTrades;
    QuerySnapshot? latestReviews;

    void emitUpdate() {
      if (latestProducts == null ||
          latestReceivedTrades == null ||
          latestSentTrades == null ||
          latestReviews == null) {
        return;
      }

      final sent = latestSentTrades!.docs.map((d) => d.data());
      final received = latestReceivedTrades!.docs.map((d) => d.data());

      final completedTradesCount = [...sent, ...received]
          .where((t) =>
              t.status == TradeStatus.accepted ||
              t.status == TradeStatus.completed)
          .length;

      controller.add({
        'productsCount': latestProducts!.docs.length,
        'completedTradesCount': completedTradesCount,
        'reviewsCount': latestReviews!.docs.length,
      });
    }

    final subs = [
      _getProductsCollection()
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        latestProducts = snap;
        emitUpdate();
      }),
      _getTradesCollection()
          .where('toUserId', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        latestReceivedTrades = snap;
        emitUpdate();
      }),
      _getTradesCollection()
          .where('fromUserId', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        latestSentTrades = snap;
        emitUpdate();
      }),
      _firestore
          .collection('Users')
          .doc(userId)
          .collection('Reviews')
          .snapshots()
          .listen((snap) {
        latestReviews = snap;
        emitUpdate();
      }),
    ];

    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  // ─── Private helpers ──────────────────────────────────────────────────

  Future<UserModel?> _getUserFromFireStore(String uid) async {
    final usersCollection = _getUsersCollection();
    final usersDocument = usersCollection.doc(uid);
    final documentSnapshot = await usersDocument.get();
    return documentSnapshot.data();
  }
}
