import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/utils/queue_display_utils.dart';
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
  final List<QueueModel> passedQueues;
  final String currentServing;
  final int totalWaiting;

  const QueueActiveLoaded({
    required this.activeQueues,
    this.passedQueues = const [],
    required this.currentServing,
    required this.totalWaiting,
  });

  @override
  List<Object?> get props => [activeQueues, passedQueues, currentServing, totalWaiting];
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

  String? _currentUserId;

  QueueCubit({QueueRepository? repository})
      : _repository = repository ?? QueueRepository(),
        super(QueueInitial());

  void reset() {
    _currentUserId = null;
    _cachedActiveQueues = null;
    emit(QueueInitial());
  }

  List<QueueModel> _queuesForUser(List<QueueModel> queues) {
    if (_currentUserId == null) return queues;
    return queues.where((queue) => queue.userId == _currentUserId).toList();
  }

  QueueActiveLoaded _buildActiveLoaded(List<QueueModel> queues, Map<String, dynamic> stats) {
    final userQueues = _queuesForUser(queues);
    final currentServing = stats['currentServing']?.toString() ?? 'N/A';
    final activeQueues = <QueueModel>[];
    final passedQueues = <QueueModel>[];

    for (final queue in userQueues) {
      if (QueueDisplayUtils.shouldShowInActive(
        queue: queue,
        currentServing: currentServing,
      )) {
        activeQueues.add(queue);
      } else {
        passedQueues.add(queue);
      }
    }

    return QueueActiveLoaded(
      activeQueues: activeQueues,
      passedQueues: passedQueues,
      currentServing: currentServing,
      totalWaiting: stats['totalWaiting'] as int? ?? 0,
    );
  }

  Future<void> loadActiveQueues({String? userId}) async {
    if (userId != null) {
      _currentUserId = userId;
    }
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
    }
    _refreshActiveQueuesInBackground();
    if (_cachedActiveQueues == null) {
      loadActiveQueues();
    }
  }

  Future<void> loadQueueDetail(String queueId) async {
    try {
      final queue = await _repository.getQueueDetails(queueId);
      if (_currentUserId != null && queue.userId != _currentUserId) {
        emit(const QueueError('Antrean tidak ditemukan.'));
        return;
      }
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
      final current = state;
      if (current is QueueActiveLoaded || current is QueueInitial) {
        emit(_cachedActiveQueues!);
      }
    } catch (_) {
      // Keep cached list visible if refresh fails.
    }
  }

  /// Always reloads and emits list state for the Antrean tab.
  Future<void> refreshQueueList({String? userId}) async {
    await loadActiveQueues(userId: userId);
  }
  
  // Custom update trigger (e.g. from WebSockets without full loading state)
  Future<void> updateActiveQueuesSilently() async {
    await _refreshActiveQueuesInBackground();
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
