import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/queue_repository.dart';
import '../../theme/damos_dominance_colors.dart';
import '../../widgets/common/error_state.dart';

/// Legacy queue routes redirect to [OrderDetailScreen] via order id.
class QueueRouteRedirectScreen extends StatefulWidget {
  final String queueId;

  const QueueRouteRedirectScreen({super.key, required this.queueId});

  @override
  State<QueueRouteRedirectScreen> createState() => _QueueRouteRedirectScreenState();
}

class _QueueRouteRedirectScreenState extends State<QueueRouteRedirectScreen> {
  final QueueRepository _repository = QueueRepository();
  String? _error;

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
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: DamosDominanceColors.screenBackground,
        body: ErrorState(
          message: _error!,
          onRetry: _redirect,
        ),
      );
    }

    return const Scaffold(
      backgroundColor: DamosDominanceColors.screenBackground,
      body: Center(
        child: CircularProgressIndicator(color: DamosDominanceColors.primary),
      ),
    );
  }
}
