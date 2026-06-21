import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/queue_model.dart';
import '../../data/repositories/queue_repository.dart';

// States
abstract class QueueState extends Equatable {
  const QueueState();

  @override
  List<Object?> get props => [];
}

class QueueInitial extends QueueState {}

class QueueLoading extends QueueState {}

class QueueActiveLoaded extends QueueState {
  final List<QueueModel> activeQueues;
  final String currentServing;
  final int totalWaiting;

  const QueueActiveLoaded({
    required this.activeQueues,
    required this.currentServing,
    required this.totalWaiting,
  });

  @override
  List<Object?> get props => [activeQueues, currentServing, totalWaiting];
}

class QueueDetailLoaded extends QueueState {
  final QueueModel queue;

  const QueueDetailLoaded(this.queue);

  @override
  List<Object?> get props => [queue];
}

class QueueError extends QueueState {
  final String message;

  const QueueError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class QueueCubit extends Cubit<QueueState> {
  final QueueRepository _repository;
  QueueActiveLoaded? _cachedActiveQueues;

  QueueCubit({QueueRepository? repository})
      : _repository = repository ?? QueueRepository(),
        super(QueueInitial());

  QueueActiveLoaded _buildActiveLoaded(List<QueueModel> queues, Map<String, dynamic> stats) {
    return QueueActiveLoaded(
      activeQueues: queues,
      currentServing: stats['currentServing']?.toString() ?? 'N/A',
      totalWaiting: stats['totalWaiting'] as int? ?? 0,
    );
  }

  Future<void> loadActiveQueues() async {
    emit(QueueLoading());
    try {
      final queues = await _repository.getActiveQueues();
      final stats = await _repository.getCurrentQueueState();
      _cachedActiveQueues = _buildActiveLoaded(queues, stats);
      emit(_cachedActiveQueues!);
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  /// Restore list view instantly after leaving a detail screen.
  void restoreActiveQueuesView() {
    if (_cachedActiveQueues != null) {
      emit(_cachedActiveQueues!);
      _refreshActiveQueuesInBackground();
      return;
    }
    loadActiveQueues();
  }

  Future<void> loadQueueDetail(String queueId) async {
    try {
      final queue = await _repository.getQueueDetails(queueId);
      emit(QueueDetailLoaded(queue));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _refreshActiveQueuesInBackground() async {
    try {
      final queues = await _repository.getActiveQueues();
      final stats = await _repository.getCurrentQueueState();
      _cachedActiveQueues = _buildActiveLoaded(queues, stats);
      if (state is QueueActiveLoaded) {
        emit(_cachedActiveQueues!);
      }
    } catch (_) {
      // Keep cached list visible if refresh fails.
    }
  }
  
  // Custom update trigger (e.g. from WebSockets without full loading state)
  void updateActiveQueuesSilently() async {
    if (state is QueueActiveLoaded) {
      await _refreshActiveQueuesInBackground();
    }
  }

  void updateQueueDetailSilently(String queueId) async {
    if (state is QueueDetailLoaded) {
      try {
        final queue = await _repository.getQueueDetails(queueId);
        emit(QueueDetailLoaded(queue));
      } catch (_) {
        // Fail silently
      }
    }
  }
}
