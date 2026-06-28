import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

// States
abstract class OrderState extends Equatable {
  const OrderState();
  
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCreated extends OrderState {
  final OrderModel order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderHistoryLoaded extends OrderState {
  final List<OrderModel> orders;

  const OrderHistoryLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final OrderModel order;

  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _repository;

  OrderCubit({OrderRepository? repository})
      : _repository = repository ?? OrderRepository(),
        super(OrderInitial());

  Future<void> checkout({
    required List<String> cartItemIds,
    required String paymentMethod,
    String? notes,
  }) async {
    emit(OrderLoading());
    try {
      final order = await _repository.createOrder(
        cartItemIds: cartItemIds,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      emit(OrderCreated(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Creates the order AND immediately processes the payment so a queue number
  /// is generated on the backend. Emits [OrderCreated] with the paid order.
  Future<void> checkoutAndPay({
    required List<String> cartItemIds,
    required String paymentMethod,
    String? notes,
  }) async {
    emit(OrderLoading());
    try {
      final order = await _repository.createOrder(
        cartItemIds: cartItemIds,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      final paidOrder = await _repository.payOrder(
        order.id,
        paymentMethod: paymentMethod,
      );
      emit(OrderCreated(paidOrder));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> loadMyOrders() async {
    emit(OrderLoading());
    try {
      final orders = await _repository.getMyOrders();
      emit(OrderHistoryLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    emit(OrderLoading());
    try {
      final order = await _repository.getOrderDetails(orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> payOrder(String orderId, {required String paymentMethod}) async {
    emit(OrderLoading());
    try {
      final order = await _repository.payOrder(orderId, paymentMethod: paymentMethod);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> cancelOrder(String orderId) async {
    emit(OrderLoading());
    try {
      final order = await _repository.cancelOrder(orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}

