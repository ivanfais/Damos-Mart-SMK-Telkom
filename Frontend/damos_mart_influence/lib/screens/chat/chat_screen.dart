import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_cubit.dart';
import '../../core/socket/socket_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/chat_message_model.dart';
import '../../widgets/common/error_state.dart';
import '../../config/app_constants.dart';
import '../../widgets/common/damos_page_app_bar.dart';

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color readReceipt = Color(0xFF1A3C8F);
  static const Color bgChat = Color(0xFFF2F2F2);
  static const Color inputBg = Color(0xFFF2F2F2);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAdminTyping = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    }

    context.read<ChatCubit>().loadRoomAndMessages();

    SocketService.instance.onChatMessage((data) {
      if (mounted && data != null) {
        final message = ChatMessageModel.fromJson(data);
        context.read<ChatCubit>().receiveMessage(message);
        _scrollToBottom();
      }
    });

    SocketService.instance.onChatTyping((data) {
      if (mounted && data != null && data['userId'] != _currentUserId) {
        setState(() {
          _isAdminTyping = data['isTyping'] as bool? ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    final chatState = context.read<ChatCubit>().state;
    if (chatState is ChatRoomLoaded) {
      SocketService.instance.leaveChat(chatState.room.id);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatCubit>().sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  Widget _buildScrollHeader() {
    return DamosPageHeader(
      title: 'Admin Damos Mart',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      titleWidget: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              AppConstants.imageLogo,
              width: 36,
              height: 26,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 26,
                color: Colors.white24,
                child: const Icon(Icons.storefront, size: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Damos Mart',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _isAdminTyping ? 'sedang mengetik...' : 'Online',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final bubbleColor = isMe ? _Ds.primary : Colors.white;
    final textColor = isMe ? Colors.white : _Ds.textPrimary;
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatter.formatTimeOnly(message.createdAt),
                style: const TextStyle(fontSize: 11, color: _Ds.hint),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all,
                  size: 14,
                  color: _Ds.readReceipt,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isSending) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(8, 8, 8, 16 + bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, color: _Ds.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _Ds.inputBg,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14, color: _Ds.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(fontSize: 14, color: _Ds.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSending ? _Ds.primary.withValues(alpha: 0.5) : _Ds.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ds.bgChat,
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatRoomLoaded) {
            SocketService.instance.joinChat(state.room.id);
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _Ds.primary),
            );
          }

          if (state is ChatError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ChatCubit>().loadRoomAndMessages(),
            );
          }

          if (state is ChatRoomLoaded) {
            final messages = state.messages;

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(child: _buildScrollHeader()),
                      if (messages.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Mulai percakapan dengan admin koperasi.',
                              style: TextStyle(fontSize: 14, color: _Ds.textSecondary),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final message = messages[index];
                                final isMe = message.senderId == _currentUserId;
                                return _buildMessageBubble(message, isMe);
                              },
                              childCount: messages.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildInputBar(state.isSending),
              ],
            );
          }

          return const Center(child: Text('Memulai obrolan...'));
        },
      ),
    );
  }
}
