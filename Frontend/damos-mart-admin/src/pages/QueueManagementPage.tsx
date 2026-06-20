import React, { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Volume2,
  Check,
  ChevronRight,
  UserX,
  QrCode,
  RefreshCw,
  Search,
  Sparkles,
  VolumeX,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import apiClient from '../api/client';
import useSocketStore from '../stores/socketStore';

export const QueueManagementPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { queueSocket } = useSocketStore();

  // Audio mute toggling
  const [isMuted, setIsMuted] = useState(false);

  // QR scan popup modal state
  const [qrModalOpen, setQrModalOpen] = useState(false);
  const [scannedQrCode, setScannedQrCode] = useState('');

  // 1. Query today's queues
  const { data: queues = [], isLoading, refetch } = useQuery<any[]>({
    queryKey: ['adminQueuesToday'],
    queryFn: async () => {
      const res = await apiClient.get('/admin/queues');
      return res.data.data;
    },
  });

  // 2. Real-time updates subscription via Socket.IO
  useEffect(() => {
    if (queueSocket) {
      const handleQueueUpdate = () => {
        // Play notification sound if not muted
        if (!isMuted) {
          const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-84.wav');
          audio.play().catch((err) => console.log('Sound autoplay prevented', err));
        }

        // Invalidate queries to trigger re-fetch and slide columns
        queryClient.invalidateQueries({ queryKey: ['adminQueuesToday'] });
      };

      queueSocket.on('queue:updated', handleQueueUpdate);
      queueSocket.on('queue:called', handleQueueUpdate);
      queueSocket.on('queue:ready', handleQueueUpdate);

      return () => {
        queueSocket.off('queue:updated', handleQueueUpdate);
        queueSocket.off('queue:called', handleQueueUpdate);
        queueSocket.off('queue:ready', handleQueueUpdate);
      };
    }
  }, [queueSocket, queryClient, isMuted]);

  // 3. Queue Action mutations
  const callMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.put(`/admin/queues/${id}/call`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminQueuesToday'] });
    },
  });

  const readyMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.put(`/admin/queues/${id}/ready`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminQueuesToday'] });
      confetti({
        particleCount: 50,
        spread: 60,
        origin: { y: 0.8 },
        colors: ['#fb7185', '#f43f5e', '#be123c'],
      });
    },
  });

  const completeMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.put(`/admin/queues/${id}/complete`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminQueuesToday'] });
      // Big confetti burst
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#10b981', '#34d399', '#059669'],
      });
    },
  });

  const skipMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.put(`/admin/queues/${id}/skip`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminQueuesToday'] });
    },
  });

  const scanQrMutation = useMutation({
    mutationFn: async (qr: string) => {
      await apiClient.post('/admin/queues/scan', { qrData: qr });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminQueuesToday'] });
      setQrModalOpen(false);
      setScannedQrCode('');
      confetti({
        particleCount: 150,
        spread: 80,
        origin: { y: 0.6 },
      });
    },
    onError: (err: any) => {
      alert(err.response?.data?.error?.message || 'Kode QR tidak valid.');
    },
  });

  // Filter queues into columns
  const filterByStatus = (status: string) => {
    return queues.filter((q) => q.status === status);
  };

  const handleScanSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!scannedQrCode) return;
    scanQrMutation.mutate(scannedQrCode);
  };

  const getCardTime = (dateStr: string) => {
    const d = new Date(dateStr);
    return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Menginisialisasi Board Antrean...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Board Header Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Board Pengelolaan Antrean</h1>
          <p className="text-sm text-slate-400 mt-1">
            Panggil siswa, siapkan pesanan, dan konfirmasi pengambilan via WebSocket.
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          {/* Sound Toggle */}
          <button
            onClick={() => setIsMuted(!isMuted)}
            className={`p-3 rounded-xl border transition-colors flex items-center justify-center ${
              isMuted
                ? 'bg-white border-slate-200 text-slate-500 hover:text-slate-400'
                : 'bg-brand-500/10 border-brand-500/20 text-brand-400 hover:bg-brand-500/20'
            }`}
            title={isMuted ? 'Aktifkan Suara Bell' : 'Bisukan Suara Bell'}
          >
            {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
          </button>

          {/* QR Scan Confirm */}
          <button
            onClick={() => setQrModalOpen(true)}
            className="flex items-center gap-2 px-5 py-3 rounded-xl bg-white border border-slate-200 hover:bg-slate-100 text-slate-900 font-bold transition-all text-sm active:scale-[0.98]"
          >
            <QrCode className="w-5 h-5 text-brand-400" />
            <span>Scan QR Pengambilan</span>
          </button>
        </div>
      </div>

      {/* Columns Board view */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 items-start">
        
        {/* COL 1: MENUNGGU (WAITING) */}
        <div className="glass-panel rounded-2xl overflow-hidden shadow-xl border-t-2 border-t-amber-500">
          <div className="p-4 bg-white/60 flex items-center justify-between border-b border-slate-200/80">
            <h3 className="font-extrabold text-slate-900 text-sm">Menunggu</h3>
            <span className="px-2 py-0.5 rounded-lg bg-amber-500/10 text-amber-400 border border-amber-500/20 font-mono text-xs font-black">
              {filterByStatus('WAITING').length}
            </span>
          </div>

          <div className="p-4 space-y-4 max-h-[70vh] overflow-y-auto min-h-[150px]">
            {filterByStatus('WAITING').map((q) => (
              <div key={q.id} className="p-4 rounded-xl bg-slate-50/60 border border-slate-200 space-y-4 hover:border-amber-500/45 transition-colors">
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <span className="text-2xl font-black text-amber-400 tracking-tight">{q.queueNumber}</span>
                    <h4 className="font-extrabold text-slate-900 text-xs truncate max-w-[150px]">{q.user.fullName}</h4>
                  </div>
                  <span className="text-[10px] text-slate-500 font-mono">{getCardTime(q.createdAt)}</span>
                </div>

                <div className="flex items-center justify-between text-[10px] font-bold text-slate-500 pt-3 border-t border-slate-200/40">
                  <span>{q.order.orderItems?.reduce((sum: number, it: any) => sum + it.quantity, 0) || 0} items</span>
                  <span className="text-slate-400 font-mono">{q.order.orderNumber}</span>
                </div>

                <button
                  onClick={() => callMutation.mutate(q.id)}
                  disabled={callMutation.isPending}
                  className="w-full py-2.5 rounded-lg bg-amber-500 hover:bg-amber-600 border border-amber-500 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-all"
                >
                  <span>Proses</span>
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            ))}
            {filterByStatus('WAITING').length === 0 && (
              <div className="text-center py-8 text-slate-600 text-xs font-semibold">Tidak ada antrean.</div>
            )}
          </div>
        </div>

        {/* COL 2: DISIAPKAN (PREPARING) */}
        <div className="glass-panel rounded-2xl overflow-hidden shadow-xl border-t-2 border-t-blue-500">
          <div className="p-4 bg-white/60 flex items-center justify-between border-b border-slate-200/80">
            <h3 className="font-extrabold text-slate-900 text-sm">Disiapkan</h3>
            <span className="px-2 py-0.5 rounded-lg bg-blue-500/10 text-blue-400 border border-blue-500/20 font-mono text-xs font-black">
              {filterByStatus('PREPARING').length}
            </span>
          </div>

          <div className="p-4 space-y-4 max-h-[70vh] overflow-y-auto min-h-[150px]">
            {filterByStatus('PREPARING').map((q) => (
              <div key={q.id} className="p-4 rounded-xl bg-slate-50/60 border border-slate-200 space-y-4 hover:border-blue-500/45 transition-colors">
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <span className="text-2xl font-black text-blue-400 tracking-tight">{q.queueNumber}</span>
                    <h4 className="font-extrabold text-slate-900 text-xs truncate max-w-[150px]">{q.user.fullName}</h4>
                  </div>
                  <span className="text-[10px] text-slate-500 font-mono">{getCardTime(q.createdAt)}</span>
                </div>

                <div className="flex items-center justify-between text-[10px] font-bold text-slate-500 pt-3 border-t border-slate-200/40">
                  <span>{q.order.orderItems?.reduce((sum: number, it: any) => sum + it.quantity, 0) || 0} items</span>
                  <span className="text-slate-400 font-mono">{q.order.orderNumber}</span>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => skipMutation.mutate(q.id)}
                    className="py-2.5 rounded-lg bg-white hover:bg-rose-950/20 border border-slate-200 hover:border-rose-900/40 text-slate-500 hover:text-rose-400 font-bold text-[10px] transition-colors"
                  >
                    Lewati
                  </button>
                  <button
                    onClick={() => readyMutation.mutate(q.id)}
                    disabled={readyMutation.isPending}
                    className="py-2.5 rounded-lg bg-blue-500 hover:bg-blue-600 border border-blue-500 text-white font-bold text-[10px] flex items-center justify-center gap-1 transition-all"
                  >
                    <Sparkles className="w-3.5 h-3.5" />
                    <span>Siap</span>
                  </button>
                </div>
              </div>
            ))}
            {filterByStatus('PREPARING').length === 0 && (
              <div className="text-center py-8 text-slate-600 text-xs font-semibold">Tidak ada antrean.</div>
            )}
          </div>
        </div>

        {/* COL 3: SIAP DIAMBIL (READY) */}
        <div className="glass-panel rounded-2xl overflow-hidden shadow-xl border-t-2 border-t-emerald-500">
          <div className="p-4 bg-white/60 flex items-center justify-between border-b border-slate-200/80">
            <h3 className="font-extrabold text-slate-900 text-sm">Siap Diambil</h3>
            <span className="px-2 py-0.5 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-mono text-xs font-black">
              {filterByStatus('READY').length}
            </span>
          </div>

          <div className="p-4 space-y-4 max-h-[70vh] overflow-y-auto min-h-[150px]">
            {filterByStatus('READY').map((q) => (
              <div key={q.id} className="p-4 rounded-xl bg-slate-50/60 border border-slate-200 space-y-4 hover:border-emerald-500/45 transition-colors">
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <span className="text-2xl font-black text-emerald-400 tracking-tight">{q.queueNumber}</span>
                    <h4 className="font-extrabold text-slate-900 text-xs truncate max-w-[150px]">{q.user.fullName}</h4>
                  </div>
                  <span className="text-[10px] text-slate-500 font-mono">{getCardTime(q.createdAt)}</span>
                </div>

                <div className="flex items-center justify-between text-[10px] font-bold text-slate-500 pt-3 border-t border-slate-200/40">
                  <span>{q.order.orderItems?.reduce((sum: number, it: any) => sum + it.quantity, 0) || 0} items</span>
                  <span className="text-slate-400 font-mono">{q.order.orderNumber}</span>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => skipMutation.mutate(q.id)}
                    className="py-2.5 rounded-lg bg-white hover:bg-slate-100 border border-slate-200 hover:border-slate-300 text-slate-500 hover:text-slate-900 font-bold text-[10px] transition-colors"
                  >
                    Lewati
                  </button>
                  <button
                    onClick={() => completeMutation.mutate(q.id)}
                    disabled={completeMutation.isPending}
                    className="py-2.5 rounded-lg bg-brand-600 hover:bg-brand-500 text-white font-bold text-[10px] flex items-center justify-center gap-1 transition-all"
                  >
                    <Check className="w-3.5 h-3.5" />
                    <span>Selesai</span>
                  </button>
                </div>
              </div>
            ))}
            {filterByStatus('READY').length === 0 && (
              <div className="text-center py-8 text-slate-600 text-xs font-semibold">Tidak ada antrean.</div>
            )}
          </div>
        </div>

        {/* COL 4: SELESAI (COMPLETED) */}
        <div className="glass-panel rounded-2xl overflow-hidden shadow-xl border-t-2 border-t-slate-700">
          <div className="p-4 bg-white/60 flex items-center justify-between border-b border-slate-200/80">
            <h3 className="font-extrabold text-slate-900 text-sm">Selesai</h3>
            <span className="px-2 py-0.5 rounded-lg bg-slate-100 border border-slate-300 text-slate-400 font-mono text-xs font-black">
              {filterByStatus('COMPLETED').length}
            </span>
          </div>

          <div className="p-4 space-y-4 max-h-[70vh] overflow-y-auto min-h-[150px]">
            {filterByStatus('COMPLETED').map((q) => (
              <div key={q.id} className="p-4 rounded-xl bg-slate-50/20 border border-slate-200 opacity-60 space-y-3">
                <div className="flex items-start justify-between">
                  <div className="space-y-0.5">
                    <span className="text-xl font-bold text-slate-500 font-mono">{q.queueNumber}</span>
                    <h4 className="font-bold text-slate-400 text-xs truncate max-w-[150px]">{q.user.fullName}</h4>
                  </div>
                  <span className="text-[10px] text-slate-600 font-mono">{getCardTime(q.createdAt)}</span>
                </div>
                <div className="text-[9px] text-slate-600 font-mono text-right">{q.order.orderNumber}</div>
              </div>
            ))}
            {filterByStatus('COMPLETED').length === 0 && (
              <div className="text-center py-8 text-slate-600 text-xs font-semibold">Belum ada antrean selesai.</div>
            )}
          </div>
        </div>

      </div>

      {/* QR Code Scanner Mockup Popup Modal */}
      {qrModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-black/75 backdrop-blur-sm animate-[fadeIn_0.25s_ease-out]">
          <div className="w-full max-w-sm glass-panel p-6 rounded-2xl shadow-2xl relative">
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="p-4 bg-brand-500/10 border border-brand-500/25 rounded-full text-brand-400">
                <QrCode className="w-8 h-8" />
              </div>
              <div>
                <h3 className="font-extrabold text-slate-900 text-lg">Konfirmasi Pengambilan QR</h3>
                <p className="text-xs text-slate-400 mt-1">Masukkan atau tempel payload data QR siswa untuk konfirmasi ambil.</p>
              </div>

              <form onSubmit={handleScanSubmit} className="w-full space-y-4 pt-2">
                <input
                  type="text"
                  required
                  value={scannedQrCode}
                  onChange={(e) => setScannedQrCode(e.target.value)}
                  placeholder="cth: 3be17032-1563-4416-83df..."
                  className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 text-center focus:outline-none focus:border-brand-500"
                  autoFocus
                />
                
                <div className="flex gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      setQrModalOpen(false);
                      setScannedQrCode('');
                    }}
                    className="flex-1 py-2.5 rounded-xl border border-slate-200 text-slate-500 hover:text-slate-900 font-semibold text-xs transition-colors"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={scanQrMutation.isPending}
                    className="flex-1 py-2.5 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs transition-colors"
                  >
                    {scanQrMutation.isPending ? 'Verifikasi...' : 'Konfirmasi'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default QueueManagementPage;
