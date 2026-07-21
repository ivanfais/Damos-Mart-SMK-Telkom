import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/queue_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/loading_shimmer.dart';

/// Legacy queue routes and QUEUE_READY notification refs redirect to order detail.
class QueueRouteRedirectScreen extends StatefulWidget {
  final String queueId;

  const QueueRouteRedirectScreen({super.key, required this.queueId});

  @override
  State<QueueRouteRedirectScreen> createState() => _QueueRouteRedirectScreenState();
}

class _QueueRouteRedirectScreenState extends State<QueueRouteRedirectScreen> {
  final QueueRepository _repository = QueueRepository();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    try {
      final queue = await _repository.getQueueDetails(widget.queueId);
      if (!mounted) return;
      context.go('/orders/${queue.orderId}');
    } catch (_) {
      // Newer notifications may store order id directly in referenceId.
      if (!mounted) return;
      context.go('/orders/${widget.queueId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: DamosOrderDetailShimmer(),
    );
  }
}
