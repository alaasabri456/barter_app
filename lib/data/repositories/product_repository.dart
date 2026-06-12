// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';

/// Repository responsible for all product-related data operations.
class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Collection helpers ───────────────────────────────────────────────

  CollectionReference<ProductModel> getProductsCollection() {
    return _firestore.collection("Products").withConverter<ProductModel>(
          fromFirestore: (snapshot, _) =>
              ProductModel.fromJson(snapshot.data()!),
          toFirestore: (product, _) => product.toJson(),
        );
  }

  CollectionReference<UserModel> _getUsersCollection() {
    return _firestore.collection("Users").withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  // ─── Product CRUD ─────────────────────────────────────────────────────

  Future<void> addProduct(ProductModel product) {
    final productsCollection = getProductsCollection();
    final productDocument = productsCollection.doc();

    final updatedProduct = product.copyWith(
      id: productDocument.id,
      ownerId: UserModel.currentUser!.id,
      ownerName: UserModel.currentUser!.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isOwnerPremium: UserModel.currentUser!.isPremium,
    );

    return productDocument.set(updatedProduct);
  }

  Future<List<ProductModel>> getProducts() async {
    final productsCollection = getProductsCollection();
    final querySnapshot =
        await productsCollection.orderBy("createdAt", descending: true).get();
    return querySnapshot.docs
        .map((documentSnapshot) => documentSnapshot.data())
        .toList();
  }

  /// Real-time stream of all available products.
  Stream<List<ProductModel>> getProductsStream() {
    final productsCollection = getProductsCollection();
    return productsCollection
        .where('status', isEqualTo: ProductStatus.available.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<List<ProductModel>> getUserProducts(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is empty');
      }

      final productsCollection = getProductsCollection();

      // Warm-up query
      await productsCollection.limit(1).get();

      final querySnapshot = await productsCollection
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final products = <ProductModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          products.add(doc.data());
        } catch (e) {
          print('Error parsing product document: $e');
        }
      }

      return products;
    } catch (e) {
      throw Exception(
        'Failed to load your products. Please check your connection and try again.',
      );
    }
  }

  Stream<List<ProductModel>> streamUserProducts(String userId) {
    final productsCollection = getProductsCollection();
    return productsCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];

      final productsCollection = getProductsCollection();
      final querySnapshot = await productsCollection
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get products by IDs: $e');
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final productsCollection = getProductsCollection();
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

  Future<void> updateProduct(ProductModel product) async {
    try {
      final productsCollection = getProductsCollection();
      final productDocument = productsCollection.doc(product.id);
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await productDocument.update(updatedProduct.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('Products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> updateProductAvailability({
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

  Future<int> getUntradedProductsCount(String userId) async {
    try {
      final products = await getUserProducts(userId);
      return products.where((p) => p.status != ProductStatus.traded).length;
    } catch (e) {
      print('Error getting untraded products count: $e');
      return 0;
    }
  }

  // ─── Image upload ─────────────────────────────────────────────────────

  Future<String> uploadProductImage(XFile imageFile, String fileName) async {
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

  Future<List<String>> uploadProductImages(
    List<XFile> images,
    String userId,
  ) async {
    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < images.length; i++) {
        final String fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
        final String downloadUrl = await uploadProductImage(images[i], fileName);
        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // ─── Product interactions ─────────────────────────────────────────────

  Future<void> reportProduct({
    required String productId,
    required String userId,
  }) async {
    if (userId.isEmpty) return;

    final productRef = getProductsCollection().doc(productId);

    await _firestore.runTransaction((transaction) async {
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

  Future<void> incrementProductViewCount(
    String productId,
    String userId,
  ) async {
    if (userId.isEmpty) return;

    final productRef = getProductsCollection().doc(productId);

    await _firestore.runTransaction((transaction) async {
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

  // ─── Favourites ───────────────────────────────────────────────────────

  Future<void> addToFavourites(String userId, String productId) async {
    try {
      final usersCollection = _getUsersCollection();
      final userDoc = usersCollection.doc(userId);

      await userDoc.update({
        'favouriteProductIds': FieldValue.arrayUnion([productId]),
      });

      if (UserModel.currentUser?.id == userId) {
        final updatedUser = await _getUserFromFireStore(userId);
        if (updatedUser != null) {
          UserModel.currentUser = updatedUser;
        }
      }
    } catch (e) {
      throw Exception('Failed to add to favourites: $e');
    }
  }

  Future<void> removeFromFavourites(String userId, String productId) async {
    try {
      final usersCollection = _getUsersCollection();
      final userDoc = usersCollection.doc(userId);

      await userDoc.update({
        'favouriteProductIds': FieldValue.arrayRemove([productId]),
      });

      if (UserModel.currentUser?.id == userId) {
        final updatedUser = await _getUserFromFireStore(userId);
        if (updatedUser != null) {
          UserModel.currentUser = updatedUser;
        }
      }
    } catch (e) {
      throw Exception('Failed to remove from favourites: $e');
    }
  }

  Future<bool> toggleFavourite(String userId, String productId) async {
    final userRef = _getUsersCollection().doc(userId);
    final productRef = getProductsCollection().doc(productId);

    try {
      final userDoc = await userRef.get();
      final batch = _firestore.batch();
      bool isCurrentlyFavourite = false;

      if (!userDoc.exists) {
        final user = UserModel(
          id: userId,
          email: UserModel.currentUser?.email ??
              FirebaseAuth.instance.currentUser?.email ??
              '',
          name: UserModel.currentUser?.name ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'User',
          favouriteProductIds: [productId],
        );
        batch.set(userRef, user);
        batch.update(productRef, {
          'interestedUsers': FieldValue.arrayUnion([userId]),
        });

        await batch.commit();
        return true;
      }

      final user = userDoc.data()!;
      final List<String> currentFavourites =
          List<String>.from(user.favouriteProductIds);
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

  Future<List<ProductModel>> getFavouriteProducts(String userId) async {
    try {
      final user = await _getUserFromFireStore(userId);
      if (user == null || user.favouriteProductIds.isEmpty) {
        return [];
      }

      final favouriteIds = user.favouriteProductIds;
      final List<ProductModel> favouriteProducts = [];

      for (int i = 0; i < favouriteIds.length; i += 10) {
        final batch = favouriteIds.skip(i).take(10).toList();
        final products = await getProductsByIds(batch);
        favouriteProducts.addAll(products);
      }

      return favouriteProducts;
    } catch (e) {
      throw Exception('Failed to get favourite products: $e');
    }
  }

  Future<bool> isFavourite(String userId, String productId) async {
    try {
      final user = await _getUserFromFireStore(userId);
      if (user == null) return false;
      return user.favouriteProductIds.contains(productId);
    } catch (e) {
      return false;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────

  Future<UserModel?> _getUserFromFireStore(String uid) async {
    final usersCollection = _getUsersCollection();
    final usersDocument = usersCollection.doc(uid);
    final documentSnapshot = await usersDocument.get();
    return documentSnapshot.data();
  }
}
