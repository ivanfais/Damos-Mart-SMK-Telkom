import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_response.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/product_repository.dart';

// States
abstract class ProductState extends Equatable {
  const ProductState();
  
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductCatalogLoaded extends ProductState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final String searchQuery;
  final PaginationInfo? pagination;
  final bool isLoadMoreRunning;

  const ProductCatalogLoaded({
    required this.products,
    required this.categories,
    required this.selectedCategoryId,
    required this.searchQuery,
    this.pagination,
    this.isLoadMoreRunning = false,
  });

  ProductCatalogLoaded copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    PaginationInfo? pagination,
    bool? isLoadMoreRunning,
  }) {
    return ProductCatalogLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      pagination: pagination ?? this.pagination,
      isLoadMoreRunning: isLoadMoreRunning ?? this.isLoadMoreRunning,
    );
  }

  @override
  List<Object?> get props => [
        products,
        categories,
        selectedCategoryId,
        searchQuery,
        pagination,
        isLoadMoreRunning,
      ];
}

class ProductDetailLoaded extends ProductState {
  final ProductModel product;
  final List<dynamic> reviews;

  const ProductDetailLoaded({required this.product, required this.reviews});

  @override
  List<Object?> get props => [product, reviews];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit({ProductRepository? repository})
      : _repository = repository ?? ProductRepository(),
        super(ProductInitial());

  Future<void> loadCatalog({String? categoryId, String? search}) async {
    emit(ProductLoading());
    try {
      final categories = await _repository.getCategories();
      
      final result = await _repository.getProducts(
        category: categoryId,
        search: search,
        page: 1,
      );

      emit(ProductCatalogLoaded(
        products: result['products'] as List<ProductModel>,
        categories: categories,
        selectedCategoryId: categoryId ?? '',
        searchQuery: search ?? '',
        pagination: result['pagination'] as PaginationInfo?,
      ));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> filterByCategory(String categoryId) async {
    final currentState = state;
    if (currentState is ProductCatalogLoaded) {
      emit(ProductLoading());
      try {
        final result = await _repository.getProducts(
          category: categoryId,
          search: currentState.searchQuery,
          page: 1,
        );
        emit(currentState.copyWith(
          products: result['products'] as List<ProductModel>,
          selectedCategoryId: categoryId,
          pagination: result['pagination'] as PaginationInfo?,
        ));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    } else {
      await loadCatalog(categoryId: categoryId);
    }
  }

  Future<void> searchProducts(String query) async {
    final currentState = state;
    if (currentState is ProductCatalogLoaded) {
      emit(ProductLoading());
      try {
        final result = await _repository.getProducts(
          category: currentState.selectedCategoryId,
          search: query,
          page: 1,
        );
        emit(currentState.copyWith(
          products: result['products'] as List<ProductModel>,
          searchQuery: query,
          pagination: result['pagination'] as PaginationInfo?,
        ));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    } else {
      await loadCatalog(search: query);
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is ProductCatalogLoaded && !currentState.isLoadMoreRunning) {
      final pagination = currentState.pagination;
      if (pagination != null && pagination.currentPage < pagination.totalPages) {
        emit(currentState.copyWith(isLoadMoreRunning: true));
        try {
          final nextPage = pagination.currentPage + 1;
          final result = await _repository.getProducts(
            category: currentState.selectedCategoryId,
            search: currentState.searchQuery,
            page: nextPage,
          );

          final newProducts = result['products'] as List<ProductModel>;
          final existingIds = currentState.products.map((p) => p.id).toSet();
          final uniqueNew = newProducts.where((p) => !existingIds.contains(p.id)).toList();
          emit(currentState.copyWith(
            products: [...currentState.products, ...uniqueNew],
            pagination: result['pagination'] as PaginationInfo?,
            isLoadMoreRunning: false,
          ));
        } catch (_) {
          emit(currentState.copyWith(isLoadMoreRunning: false));
        }
      }
    }
  }

  Future<void> loadProductDetail(String productId) async {
    emit(ProductLoading());
    try {
      final product = await _repository.getProductDetail(productId);
      
      // Load recent reviews
      final reviewsResult = await _repository.getProductReviews(productId, page: 1, limit: 5);
      final reviews = reviewsResult['reviews'] as List? ?? [];

      emit(ProductDetailLoaded(product: product, reviews: reviews));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}

