import 'package:flutter/foundation.dart';

import '../../../data/repositories/product_repository.dart';
import '../../products/models/product_model.dart';

/// ViewModel for favourites-related UI state.
class FavouritesViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  FavouritesViewModel({required ProductRepository productRepository})
      : _productRepository = productRepository;

  bool _isLoading = false;
  List<ProductModel> _favouriteProducts = [];

  bool get isLoading => _isLoading;
  List<ProductModel> get favouriteProducts => _favouriteProducts;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadFavourites(String userId) async {
    _setLoading(true);
    try {
      _favouriteProducts =
          await _productRepository.getFavouriteProducts(userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<ProductModel>> getFavouriteProducts(String userId) async {
    await loadFavourites(userId);
    return favouriteProducts;
  }

  Future<bool> toggleFavourite(String userId, String productId) async {
    final result =
        await _productRepository.toggleFavourite(userId, productId);
    // Reload favourites after toggle
    await loadFavourites(userId);
    return result;
  }

  Future<bool> isFavourite(String userId, String productId) async {
    return await _productRepository.isFavourite(userId, productId);
  }
}
