import React, { useEffect, useRef, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Send, MessageSquare, RefreshCw, Sparkles, CheckCheck } from 'lucide-react';
import apiClient from '../api/client';
import useSocketStore from '../stores/socketStore';
import useAuthStore from '../stores/authStore';

export const ChatPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { chatSocket } = useSocketStore();
  const { user: currentUser } = useAuthStore();
  const messageEndRef = useRef<HTMLDivElement | null>(null);

  // Selected chat room ID
  const [activeRoomId, setActiveRoomId] = useState<string | null>(null);
  
  // Message input message text
  const [inputText, setInputText] = useState('');

  // Typing state
  const [typingUser, setTypingUser] = useState<string | null>(null);

  // 1. Query all student chat rooms
  const { data: rooms = [], isLoading: roomsLoading, refetch: refetchRooms } = useQuery<any[]>({
    queryKey: ['adminChatRooms'],
    queryFn: async () => {
      const res = await apiClient.get('/admin/chat/rooms');
      return res.data.data;
    },
    refetchInterval: 20000, // Background updates
  });

  // 2. Query messages of active room
  const { data: messageData, isLoading: messagesLoading } = useQuery({
    queryKey: ['adminRoomMessages', activeRoomId],
    queryFn: async () => {
      const res = await apiClient.get(`/admin/chat/rooms/${activeRoomId}/messages`);
      return res.data.data;
    },
    enabled: !!activeRoomId,
  });

  const messages = messageData || [];

  // Scroll to bottom helper
  const scrollToBottom = () => {
    messageEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // 3. Socket event bindings
  useEffect(() => {
    if (chatSocket) {
      if (activeRoomId) {
        // Join the socket room
        chatSocket.emit('chat:join', { roomId: activeRoomId });
      }

      // Live incoming messages listener
      const handleIncomingMessage = (msg: any) => {
        if (msg.roomId === activeRoomId) {
          queryClient.setQueryData(['adminRoomMessages', activeRoomId], (old: any) => {
            if (!old) return [msg];
            // Check if already in array
            if (old.some((m: any) => m.id === msg.id)) return old;
            return [...old, msg];
          });
        }
        queryClient.invalidateQueries({ queryKey: ['adminChatRooms'] });
      };

      const handleTypingEvent = (data: { roomId: string; userId: string; isTyping: boolean }) => {
        if (data.roomId === activeRoomId && data.userId !== currentUser?.id) {
          setTypingUser(data.isTyping ? 'Siswa' : null);
        }
      };

      chatSocket.on('chat:message', handleIncomingMessage);
      chatSocket.on('chat:typing', handleTypingEvent);

      return () => {
        chatSocket.off('chat:message', handleIncomingMessage);
        chatSocket.off('chat:typing', handleTypingEvent);
      };
    }
  }, [chatSocket, activeRoomId, queryClient, currentUser]);

  // 4. Send Message Mutation
  const sendMutation = useMutation({
    mutationFn: async () => {
      if (!inputText.trim() || !activeRoomId) return;
      const text = inputText;
      setInputText('');
      
      const res = await apiClient.post(`/admin/chat/rooms/${activeRoomId}/messages`, {
        message: text,
      });

      return res.data.data;
    },
    onSuccess: (newMsg) => {
      if (newMsg) {
        queryClient.setQueryData(['adminRoomMessages', activeRoomId], (old: any) => {
          if (!old) return [newMsg];
          if (old.some((m: any) => m.id === newMsg.id)) return old;
          return [...old, newMsg];
        });
      }
      queryClient.invalidateQueries({ queryKey: ['adminChatRooms'] });
    },
  });

  const handleSendSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    sendMutation.mutate();
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputText(e.target.value);
    
    // Trigger typing event via socket
    if (chatSocket && activeRoomId) {
      chatSocket.emit('chat:typing', {
        roomId: activeRoomId,
        userId: currentUser?.id,
        isTyping: e.target.value.length > 0,
      });
    }
  };

  const activeRoom = rooms.find((r) => r.id === activeRoomId);

  return (
    <div className="glass-panel rounded-2xl overflow-hidden shadow-xl h-[calc(100vh-12rem)] flex">
      
      {/* Sidebar: Chat list */}
      <div className="w-80 border-r border-slate-200 bg-white/40 flex flex-col">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <h3 className="font-extrabold text-slate-900 text-sm">Pesan Masuk</h3>
          <button
            onClick={() => refetchRooms()}
            className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto divide-y divide-slate-200">
          {rooms.map((room) => (
            <button
              key={room.id}
              onClick={() => setActiveRoomId(room.id)}
              className={`w-full p-4 flex items-start gap-3.5 text-left transition-all ${
                activeRoomId === room.id
                  ? 'bg-brand-600/10 border-l-4 border-brand-500'
                  : 'hover:bg-slate-100/40 border-l-4 border-l-transparent'
              }`}
            >
              <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-900 shadow-inner flex-shrink-0">
                {room.studentName.charAt(0)}
              </div>
              <div className="flex-1 min-w-0 space-y-1">
                <div className="flex items-center justify-between">
                  <h4 className="font-extrabold text-slate-900 text-xs truncate">{room.studentName}</h4>
                  {room.lastMessageAt && (
                    <span className="text-[9px] text-slate-500 font-mono">
                      {new Date(room.lastMessageAt).toLocaleTimeString('id-ID', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
                  )}
                </div>
                <p className="text-xs text-slate-400 truncate leading-tight">{room.lastMessage || 'Hubungi admin...'}</p>
              </div>

              {/* Unread badge */}
              {room.unreadCount > 0 && (
                <span className="h-5 min-w-5 px-1.5 rounded-full bg-brand-500 text-[10px] font-black text-white flex items-center justify-center shadow-md shadow-brand-500/10">
                  {room.unreadCount}
                </span>
              )}
            </button>
          ))}
          {rooms.length === 0 && !roomsLoading && (
            <div className="p-8 text-center text-slate-600 text-xs font-semibold">Belum ada chat masuk.</div>
          )}
        </div>
      </div>

      {/* Main Viewport: Chat history */}
      <div className="flex-1 flex flex-col bg-slate-50/20">
        {activeRoomId && activeRoom ? (
          <>
            {/* Topbar info */}
            <div className="h-16 px-6 border-b border-slate-200/80 bg-white/20 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-8.5 h-8.5 rounded-lg bg-brand-600/20 text-brand-400 flex items-center justify-center font-bold text-xs">
                  {activeRoom.studentName.charAt(0)}
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900 text-xs">{activeRoom.studentName}</h4>
                  <span className="text-[10px] text-slate-500 font-bold block">
                    {typingUser ? (
                      <span className="text-brand-400 animate-pulse">sedang mengetik...</span>
                    ) : (
                      'Siswa SMK Telkom'
                    )}
                  </span>
                </div>
              </div>
            </div>

            {/* Message window */}
            <div className="flex-1 p-6 overflow-y-auto space-y-4">
              {messagesLoading ? (
                <div className="flex items-center justify-center h-full">
                  <RefreshCw className="w-6 h-6 text-brand-500 animate-spin" />
                </div>
              ) : (
                messages.map((msg: any) => {
                  const isAdmin = msg.sender.role === 'ADMIN';
                  return (
                    <div
                      key={msg.id}
                      className={`flex ${isAdmin ? 'justify-end' : 'justify-start'} animate-[fadeIn_0.15s_ease-out]`}
                    >
                      <div
                        className={`max-w-md p-3.5 rounded-2xl text-xs font-semibold leading-relaxed ${
                          isAdmin
                            ? 'bg-brand-600 text-white rounded-tr-none shadow-md shadow-brand-600/15'
                            : 'bg-white text-slate-700 rounded-tl-none border border-slate-200'
                        }`}
                      >
                        <p>{msg.message}</p>
                        <div className="flex items-center justify-end gap-1.5 mt-2 text-[9px] text-slate-400 font-mono">
                          <span>
                            {new Date(msg.createdAt).toLocaleTimeString('id-ID', {
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </span>
                          {isAdmin && (
                            <CheckCheck className={`w-3.5 h-3.5 ${msg.isRead ? 'text-blue-400' : 'text-slate-500'}`} />
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={messageEndRef} />
            </div>

            {/* Typing Indicator */}
            {typingUser && (
              <div className="px-6 py-2 text-[10px] text-slate-500 italic animate-pulse">
                Siswa sedang mengetik pesan...
              </div>
            )}

            {/* Input footer */}
            <form onSubmit={handleSendSubmit} className="p-4 border-t border-slate-200 bg-white/30 flex gap-3">
              <input
                type="text"
                value={inputText}
                onChange={handleInputChange}
                placeholder="Tulis balasan bantuan siswa..."
                className="flex-1 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 placeholder-slate-400 focus:outline-none focus:border-brand-500 transition-colors"
              />
              <button
                type="submit"
                disabled={!inputText.trim() || sendMutation.isPending}
                className="p-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold shadow-lg shadow-brand-500/15 transition-all disabled:opacity-40 disabled:pointer-events-none active:scale-[0.98] flex items-center justify-center"
              >
                <Send className="w-4.5 h-4.5" />
              </button>
            </form>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center p-8 text-center text-slate-500 gap-4">
            <div className="p-4 rounded-full bg-white border border-slate-200 text-slate-600">
              <MessageSquare className="w-10 h-10" />
            </div>
            <div>
              <h4 className="font-extrabold text-slate-900 text-sm">Pusat Hubungan Siswa</h4>
              <p className="text-xs text-slate-400 mt-1 max-w-xs leading-normal">
                Pilih salah satu chat room siswa dari bilah samping untuk memulai percakapan bantuan.
              </p>
            </div>
          </div>
        )}
      </div>

    </div>
  );
};

export default ChatPage;
