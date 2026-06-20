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

  QueueCubit({QueueRepository? repository})
      : _repository = repository ?? QueueRepository(),
        super(QueueInitial());

  Future<void> loadActiveQueues() async {
    emit(QueueLoading());
    try {
      final queues = await _repository.getActiveQueues();
      final stats = await _repository.getCurrentQueueState();
      emit(QueueActiveLoaded(
        activeQueues: queues,
        currentServing: stats['currentServing']?.toString() ?? 'N/A',
        totalWaiting: stats['totalWaiting'] as int? ?? 0,
      ));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> loadQueueDetail(String queueId) async {
    emit(QueueLoading());
    try {
      final queue = await _repository.getQueueDetails(queueId);
      emit(QueueDetailLoaded(queue));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }
  
  // Custom update trigger (e.g. from WebSockets without full loading state)
  void updateActiveQueuesSilently() async {
    if (state is QueueActiveLoaded) {
      try {
        final queues = await _repository.getActiveQueues();
        final stats = await _repository.getCurrentQueueState();
        emit(QueueActiveLoaded(
          activeQueues: queues,
          currentServing: stats['currentServing']?.toString() ?? 'N/A',
          totalWaiting: stats['totalWaiting'] as int? ?? 0,
        ));
      } catch (_) {
        // Fail silently to prevent interrupting user view with error screen
      }
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
