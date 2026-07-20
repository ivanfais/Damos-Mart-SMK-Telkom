import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../data/repositories/product_repository.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {}

class FavoriteIdsLoaded extends FavoriteState {
  const FavoriteIdsLoaded(this.favoriteIds);

  final Set<String> favoriteIds;

  @override
  List<Object?> get props => [favoriteIds];
}

class FavoriteListLoading extends FavoriteState {
  const FavoriteListLoading(this.favoriteIds);

  final Set<String> favoriteIds;

  @override
  List<Object?> get props => [favoriteIds];
}

class FavoriteListLoaded extends FavoriteState {
  const FavoriteListLoaded({
    required this.favoriteIds,
    required this.products,
    required this.categories,
    required this.selectedCategoryId,
    required this.searchQuery,
  });

  final Set<String> favoriteIds;
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final String searchQuery;

  FavoriteListLoaded copyWith({
    Set<String>? favoriteIds,
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return FavoriteListLoaded(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        favoriteIds,
        products,
        categories,
        selectedCategoryId,
        searchQuery,
      ];
}

class FavoriteError extends FavoriteState {
  const FavoriteError(this.message, {this.favoriteIds = const {}});

  final String message;
  final Set<String> favoriteIds;

  @override
  List<Object?> get props => [message, favoriteIds];
}

class FavoriteCubit extends Cubit<FavoriteState> {
  FavoriteCubit({
    FavoriteRepository? repository,
    ProductRepository? productRepository,
  })  : _repository = repository ?? FavoriteRepository(),
        _productRepository = productRepository ?? ProductRepository(),
        super(FavoriteInitial());

  final FavoriteRepository _repository;
  final ProductRepository _productRepository;

  List<ProductModel> _cachedFavorites = [];
  int _requestId = 0;

  Set<String> get _favoriteIds {
    final state = this.state;
    if (state is FavoriteIdsLoaded) return state.favoriteIds;
    if (state is FavoriteListLoading) return state.favoriteIds;
    if (state is FavoriteListLoaded) return state.favoriteIds;
    if (state is FavoriteError) return state.favoriteIds;
    return {};
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> loadFavoriteIds() async {
    try {
      final ids = await _repository.getFavoriteIds();
      emit(FavoriteIdsLoaded(ids.toSet()));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> loadFavorites({
    String? categoryId,
    String? search,
    bool refresh = false,
  }) async {
    final currentState = state;
    final selectedCategoryId = categoryId ??
        (currentState is FavoriteListLoaded ? currentState.selectedCategoryId : '');
    final searchQuery = search ??
        (currentState is FavoriteListLoaded ? currentState.searchQuery : '');

    if (!refresh &&
        _cachedFavorites.isNotEmpty &&
        currentState is FavoriteListLoaded) {
      emit(
        currentState.copyWith(
          selectedCategoryId: selectedCategoryId,
          searchQuery: searchQuery,
          products: _filteredFavorites(selectedCategoryId, searchQuery),
        ),
      );
      return;
    }

    final currentIds = _favoriteIds;
    final requestId = ++_requestId;

    if (currentState is! FavoriteListLoaded) {
      emit(FavoriteListLoading(currentIds));
    } else {
      emit(
        currentState.copyWith(
          selectedCategoryId: selectedCategoryId,
          searchQuery: searchQuery,
        ),
      );
    }

    try {
      final categories = await _productRepository.getCategories();
      if (requestId != _requestId) return;

      if (_cachedFavorites.isEmpty || refresh) {
        _cachedFavorites = await _repository.getFavorites();
        if (requestId != _requestId) return;
      }

      emit(
        FavoriteListLoaded(
          favoriteIds: _cachedFavorites.map((p) => p.id).toSet(),
          products: _filteredFavorites(selectedCategoryId, searchQuery),
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          searchQuery: searchQuery,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(FavoriteError(e.toString(), favoriteIds: currentIds));
    }
  }

  List<ProductModel> _filteredFavorites(String categoryId, String search) {
    var items = List<ProductModel>.from(_cachedFavorites);

    if (categoryId.isNotEmpty) {
      items = items.where((product) => product.categoryId == categoryId).toList();
    }

    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items
          .where((product) => product.name.toLowerCase().contains(query))
          .toList();
    }

    return items;
  }

  Future<bool> toggleFavorite(String productId) async {
    final previousIds = Set<String>.from(_favoriteIds);
    final wasFavorite = previousIds.contains(productId);
    final optimisticIds = Set<String>.from(previousIds);

    if (wasFavorite) {
      optimisticIds.remove(productId);
    } else {
      optimisticIds.add(productId);
    }

    _emitIds(optimisticIds);

    try {
      final isFavorite = await _repository.toggleFavorite(productId);
      final syncedIds = Set<String>.from(previousIds);
      if (isFavorite) {
        syncedIds.add(productId);
      } else {
        syncedIds.remove(productId);
      }
      _emitIds(syncedIds);
      return isFavorite;
    } catch (e) {
      _emitIds(previousIds);
      rethrow;
    }
  }

  void _emitIds(Set<String> ids) {
    _cachedFavorites =
        _cachedFavorites.where((product) => ids.contains(product.id)).toList();

    final state = this.state;
    if (state is FavoriteListLoaded) {
      emit(
        state.copyWith(
          favoriteIds: ids,
          products: _filteredFavorites(state.selectedCategoryId, state.searchQuery),
        ),
      );
      return;
    }
    emit(FavoriteIdsLoaded(ids));
  }

  void resetSession() {
    _cachedFavorites = [];
    _requestId = 0;
    emit(FavoriteInitial());
  }
}
