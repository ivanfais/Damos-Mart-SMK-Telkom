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

  Future<void> loadRoomAndMessages() async {
    emit(ChatLoading());
    try {
      final room = await _repository.getOrCreateRoom();
      final messages = await _repository.getRoomMessages(room.id);
      emit(ChatRoomLoaded(room: room, messages: messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String messageText) async {
    final currentState = state;
    if (currentState is ChatRoomLoaded) {
      emit(currentState.copyWith(isSending: true));
      try {
        final newMessage = await _repository.sendMessage(currentState.room.id, messageText);
        
        // Add to messages if not already present
        final updatedMessages = List<ChatMessageModel>.from(currentState.messages);
        if (!updatedMessages.any((m) => m.id == newMessage.id)) {
          updatedMessages.insert(0, newMessage); // insert at top (newest first)
        }
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }

  void receiveMessage(ChatMessageModel newMessage) {
    final currentState = state;
    if (currentState is ChatRoomLoaded) {
      // Prevent duplicate messages in the list
      final updatedMessages = List<ChatMessageModel>.from(currentState.messages);
      if (!updatedMessages.any((m) => m.id == newMessage.id)) {
        updatedMessages.insert(0, newMessage);
        emit(currentState.copyWith(messages: updatedMessages));
      }
    }
  }
}
