import React, { useEffect, useState } from 'react';
import { Menu, Wifi, WifiOff, Calendar } from 'lucide-react';
import useSocketStore from '../../stores/socketStore';

interface HeaderProps {
  sidebarOpen: boolean;
  setSidebarOpen: (open: boolean) => void;
  title: string;
}

export const Header: React.FC<HeaderProps> = ({ setSidebarOpen, title }) => {
  const { generalSocket } = useSocketStore();
  const [isConnected, setIsConnected] = useState(false);
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    if (generalSocket) {
      setIsConnected(generalSocket.connected);

      const onConnect = () => setIsConnected(true);
      const onDisconnect = () => setIsConnected(false);

      generalSocket.on('connect', onConnect);
      generalSocket.on('disconnect', onDisconnect);

      return () => {
        generalSocket.off('connect', onConnect);
        generalSocket.off('disconnect', onDisconnect);
      };
    }
  }, [generalSocket]);

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('id-ID', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  return (
    <header className="h-20 bg-white border-b border-slate-200 flex items-center justify-between px-6 sticky top-0 z-30">
      {/* Left: Mobile Toggle & Title */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => setSidebarOpen(true)}
          className="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg md:hidden transition-colors"
        >
          <Menu className="w-6 h-6" />
        </button>
        <h2 className="text-xl font-bold text-slate-900 tracking-tight">{title}</h2>
      </div>

      {/* Right: Date, Time & WS Indicator */}
      <div className="flex items-center gap-6">
        {/* Date Time Panel */}
        <div className="hidden lg:flex items-center gap-2.5 px-4 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs font-semibold text-slate-500">
          <Calendar className="w-4 h-4 text-brand-500" />
          <span>{formatDate(time)}</span>
          <span className="text-slate-600">|</span>
          <span className="font-mono text-slate-700">{formatTime(time)}</span>
        </div>

        {/* Real-time WebSocket connection status badge */}
        <div
          className={`flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all duration-300 ${
            isConnected
              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
              : 'bg-rose-500/10 text-rose-400 border border-rose-500/20 animate-pulse'
          }`}
        >
          {isConnected ? (
            <>
              <Wifi className="w-3.5 h-3.5" />
              <span>Real-time Aktif</span>
            </>
          ) : (
            <>
              <WifiOff className="w-3.5 h-3.5" />
              <span>Koneksi Putus</span>
            </>
          )}
        </div>
      </div>
    </header>
  );
};

export default Header;
