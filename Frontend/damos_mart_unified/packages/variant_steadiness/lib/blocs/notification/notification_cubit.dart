import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final DateTime updatedAt;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, updatedAt];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(NotificationInitial());

  Future<void> loadNotifications({bool showLoading = true}) async {
    if (showLoading || state is! NotificationLoaded) {
      emit(NotificationLoading());
    }
    try {
      final list = await _repository.getNotifications();
      _emitLoaded(list);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> refreshSilently() async {
    if (state is NotificationLoading) return;
    try {
      final list = await _repository.getNotifications();
      _emitLoaded(list);
    } catch (_) {}
  }

  void _emitLoaded(List<NotificationModel> list) {
    final unread = list.where((n) => !n.isRead).length;
    emit(
      NotificationLoaded(
        notifications: List.unmodifiable(list),
        unreadCount: unread,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void reset() {
    emit(NotificationInitial());
  }

  Future<void> markAsRead(String id) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      try {
        await _repository.markAsRead(id);
        
        final updatedList = currentState.notifications.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              title: n.title,
              body: n.body,
              type: n.type,
              referenceId: n.referenceId,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();

        final unread = updatedList.where((n) => !n.isRead).length;
        emit(
          NotificationLoaded(
            notifications: List.unmodifiable(updatedList),
            unreadCount: unread,
            updatedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      try {
        await _repository.markAllAsRead();
        
        final updatedList = currentState.notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            body: n.body,
            type: n.type,
            referenceId: n.referenceId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();

        emit(
          NotificationLoaded(
            notifications: List.unmodifiable(updatedList),
            unreadCount: 0,
            updatedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    }
  }
}
