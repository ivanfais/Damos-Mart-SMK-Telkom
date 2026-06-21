import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/repositories/chat_repository.dart';

// States
abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomLoaded extends ChatState {
  final ChatRoomModel room;
  final List<ChatMessageModel> messages;
  final bool isSending;

  const ChatRoomLoaded({
    required this.room,
    required this.messages,
    this.isSending = false,
  });

  ChatRoomLoaded copyWith({
    ChatRoomModel? room,
    List<ChatMessageModel>? messages,
    bool? isSending,
  }) {
    return ChatRoomLoaded(
      room: room ?? this.room,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [room, messages, isSending];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit({ChatRepository? repository})
      : _repository = repository ?? ChatRepository(),
        super(ChatInitial());

  List<ChatMessageModel> _sortMessages(List<ChatMessageModel> messages) {
    final sorted = List<ChatMessageModel>.from(messages);
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  Future<void> loadRoomAndMessages() async {
    emit(ChatLoading());
    try {
      final room = await _repository.getOrCreateRoom();
      final messages = await _repository.getRoomMessages(room.id);
      emit(ChatRoomLoaded(room: room, messages: _sortMessages(messages)));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String messageText) async {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;

    emit(currentState.copyWith(isSending: true));
    try {
      final newMessage = await _repository.sendMessage(currentState.room.id, messageText);
      final updatedMessages = List<ChatMessageModel>.from(currentState.messages);
      if (!updatedMessages.any((m) => m.id == newMessage.id)) {
        updatedMessages.add(newMessage);
      }
      emit(currentState.copyWith(
        messages: _sortMessages(updatedMessages),
        isSending: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isSending: false));
    }
  }

  void receiveMessage(ChatMessageModel newMessage) {
    final currentState = state;
    if (currentState is! ChatRoomLoaded) return;
    if (newMessage.roomId != currentState.room.id) return;

    final updatedMessages = List<ChatMessageModel>.from(currentState.messages);
    if (!updatedMessages.any((m) => m.id == newMessage.id)) {
      updatedMessages.add(newMessage);
      emit(currentState.copyWith(messages: _sortMessages(updatedMessages)));
    }
  }
}
