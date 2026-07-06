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
  }) async {
    final currentIds = _favoriteIds;
    emit(FavoriteListLoading(currentIds));

    try {
      final categories = await _productRepository.getCategories();
      final products = await _repository.getFavorites(
        categoryId: categoryId,
        search: search,
      );

      emit(
        FavoriteListLoaded(
          favoriteIds: products.map((p) => p.id).toSet(),
          products: products,
          categories: categories,
          selectedCategoryId: categoryId ?? '',
          searchQuery: search ?? '',
        ),
      );
    } catch (e) {
      emit(FavoriteError(e.toString(), favoriteIds: currentIds));
    }
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
    final state = this.state;
    if (state is FavoriteListLoaded) {
      emit(
        state.copyWith(
          favoriteIds: ids,
          products: state.products.where((p) => ids.contains(p.id)).toList(),
        ),
      );
      return;
    }
    emit(FavoriteIdsLoaded(ids));
  }

  void resetSession() {
    emit(FavoriteInitial());
  }
}
