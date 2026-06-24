// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/trade_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../authentication/models/user_model.dart';
import '../../chat/models/chat_message.dart';

import '../models/product_model.dart';

/// ViewModel for product-related UI state and operations.
class ProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  final TradeRepository _tradeRepository;
  final NotificationService _notificationService;

  ProductViewModel({
    required ProductRepository productRepository,
    required TradeRepository tradeRepository,
    required NotificationService notificationService,
  })  : _productRepository = productRepository,
        _tradeRepository = tradeRepository,
        _notificationService = notificationService;

  bool _isLoading = false;
  String? _errorMessage;
  List<ProductModel> _userProducts = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductModel> get userProducts => _userProducts;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ─── Product CRUD ─────────────────────────────────────────────────────

  Future<void> loadUserProducts(String userId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _userProducts = await _productRepository.getUserProducts(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<ProductModel>> getUserProducts(String userId) async {
    await loadUserProducts(userId);
    return _userProducts;
  }

  Future<void> addProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _productRepository.addProduct(product);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _productRepository.updateProduct(product);
      // Notify pending trades about the update
      await _notifyPendingTradesAboutUpdate(product);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _productRepository.deleteProduct(productId);
    _userProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<ProductModel?> getProductById(String productId) async {
    return await _productRepository.getProductById(productId);
  }

  Future<List<ProductModel>> getProducts() async {
    return await _productRepository.getProducts();
  }

  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    return await _productRepository.getProductsByIds(productIds);
  }

  Stream<List<ProductModel>> getProductsStream() {
    return _productRepository.getProductsStream();
  }

  Stream<List<ProductModel>> streamUserProducts(String userId) {
    return _productRepository.streamUserProducts(userId);
  }

  Future<void> updateProductAvailability({
    required String productId,
    required bool isAvailable,
    ProductStatus? newStatus,
  }) async {
    await _productRepository.updateProductAvailability(
      productId: productId,
      isAvailable: isAvailable,
      newStatus: newStatus,
    );
  }

  Future<int> getUntradedProductsCount(String userId) async {
    return await _productRepository.getUntradedProductsCount(userId);
  }

  Future<bool> isProductInPendingTrade(String productId) async {
    return await _tradeRepository.isProductInPendingTrade(productId);
  }

  // ─── Image upload ─────────────────────────────────────────────────────

  Future<String> uploadProductImage(XFile imageFile, String fileName) async {
    return await _productRepository.uploadProductImage(imageFile, fileName);
  }

  Future<List<String>> uploadProductImages(
      List<XFile> images, String userId) async {
    return await _productRepository.uploadProductImages(images, userId);
  }

  // ─── Product interactions ─────────────────────────────────────────────

  Future<void> reportProduct({
    required String productId,
    required String userId,
  }) async {
    await _productRepository.reportProduct(
        productId: productId, userId: userId);
  }

  Future<void> incrementProductViewCount(
      String productId, String userId) async {
    await _productRepository.incrementProductViewCount(productId, userId);
  }

  // ─── Favourites ───────────────────────────────────────────────────────

  Future<bool> toggleFavourite(String userId, String productId) async {
    return await _productRepository.toggleFavourite(userId, productId);
  }

  Future<List<ProductModel>> getFavouriteProducts(String userId) async {
    return await _productRepository.getFavouriteProducts(userId);
  }

  Future<bool> isFavourite(String userId, String productId) async {
    return await _productRepository.isFavourite(userId, productId);
  }

  // ─── Private helpers ──────────────────────────────────────────────────

  Future<void> _notifyPendingTradesAboutUpdate(ProductModel product) async {
    try {
      final tradesCollection = _tradeRepository.getTradesCollection();

      final offeredTrades = await tradesCollection
          .where('offeredProductIds', arrayContains: product.id)
          .where('status', isEqualTo: 'pending')
          .get();

      final requestedTrades = await tradesCollection
          .where('requestedProductIds', arrayContains: product.id)
          .where('status', isEqualTo: 'pending')
          .get();

      final allTrades = [...offeredTrades.docs, ...requestedTrades.docs];
      final notifiedTradeIds = <String>{};

      for (final doc in allTrades) {
        if (notifiedTradeIds.contains(doc.id)) continue;

        final trade = doc.data();

        // Determine who to notify
        String userToNotifyId;
        if (product.ownerId == trade.fromUserId) {
          userToNotifyId = trade.toUserId;
        } else {
          userToNotifyId = trade.fromUserId;
        }

        if (userToNotifyId == product.ownerId) continue;

        // In-app notification is created by the Cloud Function `onProductUpdated`.
        // Send Push Notification only.
        final recipientToken =
            await _notificationService.getUserFcmToken(userToNotifyId);
        if (recipientToken != null) {
          await _notificationService.sendPushNotification(
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
    }
  }
}
