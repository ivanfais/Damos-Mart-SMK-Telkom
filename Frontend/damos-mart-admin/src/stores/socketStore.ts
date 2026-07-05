import { create } from 'zustand';
import { io, Socket } from 'socket.io-client';
import { SOCKET_SERVER_URL } from '../config/env';

interface SocketState {
  queueSocket: Socket | null;
  chatSocket: Socket | null;
  generalSocket: Socket | null;
  connectSockets: () => void;
  disconnectSockets: () => void;
}

export const useSocketStore = create<SocketState>((set, get) => ({
  queueSocket: null,
  chatSocket: null,
  generalSocket: null,
  
  connectSockets: () => {
    const state = get();
    if (state.queueSocket || state.chatSocket || state.generalSocket) return;

    console.log('🔌 Connecting sockets...');

    const generalSocket = io(SOCKET_SERVER_URL);
    const queueSocket = io(`${SOCKET_SERVER_URL}/queues`);
    const chatSocket = io(`${SOCKET_SERVER_URL}/chat`);

    // Log connection successes
    generalSocket.on('connect', () => console.log('🔌 Connected to general namespace'));
    queueSocket.on('connect', () => {
      console.log('🔌 Connected to /queues namespace');
      queueSocket.emit('queue:admin-subscribe');
    });
    chatSocket.on('connect', () => console.log('🔌 Connected to /chat namespace'));

    set({
      generalSocket,
      queueSocket,
      chatSocket,
    });
  },

  disconnectSockets: () => {
    const state = get();
    console.log('🔌 Disconnecting sockets...');

    if (state.generalSocket) state.generalSocket.disconnect();
    if (state.queueSocket) state.queueSocket.disconnect();
    if (state.chatSocket) state.chatSocket.disconnect();

    set({
      generalSocket: null,
      queueSocket: null,
      chatSocket: null,
    });
  },
}));

export default useSocketStore;
