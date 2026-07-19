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
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return [];
    return QueueDisplayUtils.queuesForUser(queues, userId);
  }

  QueueActiveLoaded _buildActiveLoaded(List<QueueModel> queues, Map<String, dynamic> stats) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return const QueueActiveLoaded(
        activeQueues: [],
        passedQueues: [],
        currentServing: 'N/A',
        totalWaiting: 0,
      );
    }

    final userQueues = _queuesForUser(queues);
    final currentServing = stats['currentServing']?.toString() ?? 'N/A';

    // Daftar aktif mengikuti respons API (selaras admin); tanpa filter giliran client.
    return QueueActiveLoaded(
      activeQueues: userQueues,
      passedQueues: const [],
      currentServing: currentServing,
      totalWaiting: stats['totalWaiting'] as int? ?? 0,
    );
  }

  Future<void> loadActiveQueues({String? userId}) async {
    if (userId != null && userId.isNotEmpty) {
      _currentUserId = userId;
    }

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _cachedActiveQueues = const QueueActiveLoaded(
        activeQueues: [],
        passedQueues: [],
        currentServing: 'N/A',
        totalWaiting: 0,
      );
      emit(_cachedActiveQueues!);
      return;
    }

    emit(QueueLoading());
    _cachedActiveQueues = null;
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
  void restoreActiveQueuesView({String? userId}) {
    if (userId != null && userId.isNotEmpty) {
      _currentUserId = userId;
    }

    if (_cachedActiveQueues != null &&
        _currentUserId != null &&
        _currentUserId!.isNotEmpty) {
      emit(_cachedActiveQueues!);
    }

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      emit(const QueueActiveLoaded(
        activeQueues: [],
        passedQueues: [],
        currentServing: 'N/A',
        totalWaiting: 0,
      ));
      return;
    }

    _refreshActiveQueuesInBackground();
    if (_cachedActiveQueues == null) {
      loadActiveQueues(userId: _currentUserId);
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
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

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
    await loadActiveQueues(userId: userId ?? _currentUserId);
  }
  
  // Custom update trigger (e.g. from WebSockets without full loading state)
  Future<void> updateActiveQueuesSilently({String? userId}) async {
    if (userId != null && userId.isNotEmpty) {
      _currentUserId = userId;
    }
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
