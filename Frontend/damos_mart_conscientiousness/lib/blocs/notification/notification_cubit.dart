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

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
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

  Future<void> loadNotifications() async {
    emit(NotificationLoading());
    try {
      final list = await _repository.getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      emit(NotificationLoaded(notifications: list, unreadCount: unread));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
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
        emit(NotificationLoaded(notifications: updatedList, unreadCount: unread));
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

        emit(NotificationLoaded(notifications: updatedList, unreadCount: 0));
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    }
  }
}
