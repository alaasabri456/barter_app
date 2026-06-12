// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/admin/models/category_suggestion_model.dart';
import '../../features/products/models/product_model.dart';

/// Repository responsible for category suggestion and management operations.
class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Collection helpers ───────────────────────────────────────────────

  CollectionReference<CategorySuggestion> _getCategorySuggestionsCollection() {
    return _firestore
        .collection('CategorySuggestions')
        .withConverter<CategorySuggestion>(
          fromFirestore: (snapshot, _) =>
              CategorySuggestion.fromJson(snapshot.data()!),
          toFirestore: (suggestion, _) => suggestion.toJson(),
        );
  }

  CollectionReference<ApprovedCategory> _getApprovedCategoriesCollection() {
    return _firestore
        .collection('ApprovedCategories')
        .withConverter<ApprovedCategory>(
          fromFirestore: (snapshot, _) =>
              ApprovedCategory.fromJson(snapshot.data()!),
          toFirestore: (category, _) => category.toJson(),
        );
  }

  CollectionReference<ProductModel> _getProductsCollection() {
    return _firestore.collection("Products").withConverter<ProductModel>(
          fromFirestore: (snapshot, _) =>
              ProductModel.fromJson(snapshot.data()!),
          toFirestore: (product, _) => product.toJson(),
        );
  }

  // ─── Public API ───────────────────────────────────────────────────────

  Future<String> suggestCategory({
    required String name,
    required String userId,
    required String userName,
  }) async {
    try {
      // Check if category already exists
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
        (doc) =>
            doc.data().suggestedName.toLowerCase() == name.toLowerCase(),
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

  Future<List<CategorySuggestion>> getCategorySuggestions({
    CategoryStatus? status,
  }) async {
    try {
      Query<CategorySuggestion> query = _getCategorySuggestionsCollection();

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get category suggestions: $e');
    }
  }

  Future<void> approveCategorySuggestion({
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

      await _getCategorySuggestionsCollection().doc(suggestionId).update({
        'status': CategoryStatus.approved.name,
        'reviewedBy': adminId,
        'reviewedByName': adminName,
        'reviewedAt': DateTime.now().toIso8601String(),
      });

      final approvedDoc = _getApprovedCategoriesCollection().doc();
      final approvedCategory = ApprovedCategory(
        id: approvedDoc.id,
        name: suggestion.suggestedName,
        addedBy: adminId,
        addedByName: adminName,
        addedAt: DateTime.now(),
      );

      await approvedDoc.set(approvedCategory);

      await _updateProductsWithApprovedCategory(
        suggestion.suggestedName,
        suggestion.suggestedName,
      );
    } catch (e) {
      throw Exception('Failed to approve category: $e');
    }
  }

  Future<void> rejectCategorySuggestion({
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

  Future<List<ApprovedCategory>> getApprovedCategories() async {
    try {
      final snapshot =
          await _getApprovedCategoriesCollection().orderBy('name').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get approved categories: $e');
    }
  }

  Future<void> deleteCategorySuggestion(String suggestionId) async {
    try {
      await _getCategorySuggestionsCollection().doc(suggestionId).delete();
    } catch (e) {
      throw Exception('Failed to delete category suggestion: $e');
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────

  Future<void> _updateProductsWithApprovedCategory(
    String customCategoryName,
    String approvedCategoryName,
  ) async {
    try {
      final productsSnapshot = await _getProductsCollection()
          .where('customCategory', isEqualTo: customCategoryName)
          .get();

      final batch = _firestore.batch();

      for (var doc in productsSnapshot.docs) {
        batch.update(doc.reference, {
          'category': approvedCategoryName,
          'customCategory': null,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating products with approved category: $e');
    }
  }
}
