import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/order_model.dart';

class OrderNavigationUtils {
  OrderNavigationUtils._();

  static void openDetail(BuildContext context, OrderModel order) {
    context.push('/orders/history/${order.id}');
  }
}
