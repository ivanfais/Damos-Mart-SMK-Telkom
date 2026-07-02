import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/repositories/cart_repository.dart';

// States
abstract class CartState extends Equatable {
  const CartState();
  
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> items;
  final int totalItems;
  final double totalPrice;
  final bool isUpdating;

  const CartLoaded({
    required this.items,
    required this.totalItems,
    required this.totalPrice,
    this.isUpdating = false,
  });

  CartLoaded copyWith({
    List<CartItemModel>? items,
    int? totalItems,
    double? totalPrice,
    bool? isUpdating,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      totalPrice: totalPrice ?? this.totalPrice,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [items, totalItems, totalPrice, isUpdating];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class CartCubit extends Cubit<CartState> {
  final CartRepository _repository;

  CartCubit({CartRepository? repository})
      : _repository = repository ?? CartRepository(),
        super(CartInitial());

  Future<void> loadCart() async {
    if (state is CartInitial) {
      emit(CartLoading());
    }
    try {
      final result = await _repository.getCart();
      emit(CartLoaded(
        items: result['items'] as List<CartItemModel>,
        totalItems: result['totalItems'] as int,
        totalPrice: result['totalPrice'] as double,
      ));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> addToCart({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    try {
      await _repository.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      await loadCart();
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        await _repository.updateQuantity(
          cartItemId: cartItemId,
          quantity: quantity,
        );
        final result = await _repository.getCart();
        emit(CartLoaded(
          items: result['items'] as List<CartItemModel>,
          totalItems: result['totalItems'] as int,
          totalPrice: result['totalPrice'] as double,
          isUpdating: false,
        ));
      } catch (e) {
        emit(CartError(e.toString()));
      }
    }
  }

  Future<void> removeCartItem(String cartItemId) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        await _repository.removeCartItem(cartItemId);
        final result = await _repository.getCart();
        emit(CartLoaded(
          items: result['items'] as List<CartItemModel>,
          totalItems: result['totalItems'] as int,
          totalPrice: result['totalPrice'] as double,
          isUpdating: false,
        ));
      } catch (e) {
        emit(CartError(e.toString()));
      }
    }
  }

  Future<void> clearCart() async {
    emit(CartLoading());
    try {
      await _repository.clearCart();
      emit(const CartLoaded(items: [], totalItems: 0, totalPrice: 0.0));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void resetSession() {
    emit(CartInitial());
  }
}

