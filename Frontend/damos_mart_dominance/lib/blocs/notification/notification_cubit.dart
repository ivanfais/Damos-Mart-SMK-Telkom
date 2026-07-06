import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/utils/notification_navigation.dart';

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

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(NotificationInitial());

  Future<void> loadNotifications({bool showLoading = true}) async {
    final previous = state;
    if (previous is! NotificationLoaded && showLoading) {
      emit(NotificationLoading());
    }
    try {
      final list = await _repository.getNotifications();
      _emitLoaded(list);
    } catch (e) {
      if (previous is! NotificationLoaded) {
        emit(NotificationError(e.toString()));
      }
    }
  }

  Future<void> refreshSilently() async {
    if (state is NotificationLoading) return;
    try {
      final list = await _repository.getNotifications();
      _emitLoaded(list);
    } catch (_) {}
  }

  void reset() {
    emit(NotificationInitial());
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

  List<NotificationModel> get unreadNotifications {
    final current = state;
    if (current is! NotificationLoaded) return const [];
    return current.notifications.where((n) => !n.isRead).toList();
  }

  bool get hasHistoryUnread {
    final current = state;
    if (current is! NotificationLoaded) return false;
    return NotificationNavigation.hasHistoryUnread(current.notifications);
  }

  NotificationModel? latestUnread(
    bool Function(NotificationModel notification) where,
  ) {
    final current = state;
    if (current is! NotificationLoaded) return null;
    return NotificationNavigation.latestUnread(current.notifications, where);
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

        _emitLoaded(updatedList);
      } catch (_) {
        // Mark-as-read is non-critical; keep the list visible.
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

        _emitLoaded(updatedList);
      } catch (_) {
        // Mark-all-read is non-critical; keep the list visible.
      }
    }
  }
}
