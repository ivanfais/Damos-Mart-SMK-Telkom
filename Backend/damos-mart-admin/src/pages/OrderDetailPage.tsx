import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  ArrowLeft,
  User,
  ShoppingBag,
  CreditCard,
  Clock,
  CheckCircle2,
  RefreshCw,
  AlertCircle,
} from 'lucide-react';
import apiClient from '../api/client';

export const OrderDetailPage: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // 1. Fetch order details (shares endpoint admin)
  const { data: order, isLoading } = useQuery({
    queryKey: ['adminOrderDetail', id],
    queryFn: async () => {
      const res = await apiClient.get(`/admin/orders/${id}`);
      return res.data.data;
    },
  });

  // 2. Status update mutation
  const updateStatusMutation = useMutation({
    mutationFn: async (newStatus: string) => {
      await apiClient.put(`/admin/orders/${id}/status`, { status: newStatus });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminOrderDetail', id] });
      queryClient.invalidateQueries({ queryKey: ['adminOrdersList'] });
    },
  });

  const handleStatusChange = (newStatus: string) => {
    updateStatusMutation.mutate(newStatus);
  };

  const formatIDR = (value: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(value);
  };

  const getStatusColor = (st: string) => {
    switch (st) {
      case 'PENDING':
        return 'bg-amber-500/10 text-amber-400 border border-amber-500/20';
      case 'PAID':
        return 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20';
      case 'PREPARING':
      case 'IN_PRODUCTION':
        return 'bg-blue-500/10 text-blue-400 border border-blue-500/20';
      case 'READY':
        return 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20';
      case 'COMPLETED':
        return 'bg-slate-500/10 text-slate-400 border border-slate-500/20';
      default:
        return 'bg-rose-500/10 text-rose-400 border border-rose-500/20';
    }
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Memuat rincian pesanan...</p>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4 text-slate-400">
        <AlertCircle className="w-12 h-12 text-rose-500" />
        <p className="font-semibold text-sm">Pesanan tidak ditemukan.</p>
        <button onClick={() => navigate('/orders')} className="px-4 py-2 rounded-xl bg-slate-100 text-xs text-slate-900">
          Kembali
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate('/orders')}
          className="flex items-center gap-2 text-sm font-bold text-slate-400 hover:text-slate-900 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Kembali ke Pesanan</span>
        </button>
        <div className="flex items-center gap-2.5">
          <span className="text-xs font-semibold text-slate-500 uppercase">Order Ref:</span>
          <span className="font-mono text-xs font-bold text-slate-600">{order.orderNumber}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        
        {/* Left Side: Order items and checkout summary */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Items List */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <div className="flex items-center gap-2.5">
              <ShoppingBag className="w-5 h-5 text-brand-400" />
              <h3 className="font-extrabold text-slate-900 text-base">Rincian Belanja Barang</h3>
            </div>

            <div className="divide-y divide-slate-200/60">
              {order.orderItems?.map((item: any) => (
                <div key={item.id} className="py-4 flex items-center justify-between gap-4">
                  <div className="space-y-1">
                    <h4 className="font-extrabold text-slate-900 text-sm">{item.productName}</h4>
                    {item.variantName && (
                      <span className="px-2 py-0.5 rounded-md bg-slate-100 border border-slate-300 text-slate-400 text-[10px] font-bold uppercase">
                        Varian: {item.variantName}
                      </span>
                    )}
                  </div>
                  
                  <div className="flex items-center gap-6 text-sm font-semibold text-slate-400">
                    <span>{item.quantity} x {formatIDR(Number(item.productPrice))}</span>
                    <span className="text-slate-900 font-bold">{formatIDR(Number(item.subtotal))}</span>
                  </div>
                </div>
              ))}
            </div>

            {/* Financial summary calculations */}
            <div className="pt-6 border-t border-slate-200 flex flex-col gap-3 font-semibold text-sm">
              <div className="flex justify-between text-slate-400">
                <span>Subtotal Belanja</span>
                <span>{formatIDR(Number(order.subtotal))}</span>
              </div>
              <div className="flex justify-between text-slate-900 font-bold text-base pt-2 border-t border-slate-200/60">
                <span>Total Tagihan</span>
                <span className="text-brand-400 font-black">{formatIDR(Number(order.total))}</span>
              </div>
            </div>
          </div>

          {/* Payment audit details */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <div className="flex items-center gap-2.5">
              <CreditCard className="w-5 h-5 text-brand-400" />
              <h3 className="font-extrabold text-slate-900 text-base">Informasi Pembayaran</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm font-semibold text-slate-400">
              <div className="space-y-1.5">
                <span className="block text-xs font-bold text-slate-500 uppercase tracking-wider">Metode Pembayaran</span>
                <span className="text-slate-900 text-sm font-bold">
                  {order.paymentMethod === 'CASH_AT_COUNTER' ? 'KASIR (CASH)' : 'QRIS (DIGITAL)'}
                </span>
              </div>

              <div className="space-y-1.5">
                <span className="block text-xs font-bold text-slate-500 uppercase tracking-wider">Status Bayar</span>
                <span
                  className={`inline-flex px-3 py-1 rounded-full text-xs font-bold ${
                    order.paymentStatus === 'PAID'
                      ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                      : 'bg-rose-500/10 text-rose-400 border border-rose-500/20 animate-pulse'
                  }`}
                >
                  {order.paymentStatus === 'PAID' ? 'LUNAS (TERBAYAR)' : 'BELUM BAYAR'}
                </span>
              </div>

              {order.paidAt && (
                <div className="space-y-1.5 col-span-2">
                  <span className="block text-xs font-bold text-slate-500 uppercase tracking-wider">Waktu Terbayar</span>
                  <span className="text-slate-900 text-xs font-mono">
                    {new Date(order.paidAt).toLocaleDateString('id-ID', {
                      weekday: 'long',
                      day: '2-digit',
                      month: 'long',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                      second: '2-digit',
                    })}
                  </span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Side: customer profile details and update actions */}
        <div className="space-y-6">
          
          {/* Customer info panel */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <div className="flex items-center gap-2.5">
              <User className="w-5 h-5 text-brand-400" />
              <h3 className="font-extrabold text-slate-900 text-base">Identitas Pembeli</h3>
            </div>

            <div className="space-y-4 text-xs font-semibold text-slate-400">
              <div className="space-y-1">
                <span className="block text-slate-500 uppercase tracking-wider">Nama Lengkap</span>
                <span className="text-slate-900 text-sm font-extrabold">{order.user.fullName}</span>
              </div>
              
              <div className="space-y-1">
                <span className="block text-slate-500 uppercase tracking-wider">Email Akun</span>
                <span className="text-slate-900 text-sm font-extrabold">{order.user.email}</span>
              </div>

              <div className="space-y-1">
                <span className="block text-slate-500 uppercase tracking-wider">Nomor Telepon</span>
                <span className="text-slate-900 text-sm font-extrabold">{order.user.phone || 'N/A'}</span>
              </div>
            </div>
          </div>

          {/* Queue ticket detail if paid */}
          {order.queue && (
            <div className="glass-panel p-6 rounded-2xl shadow-xl border-l-4 border-l-brand-500 space-y-6">
              <div className="flex items-center gap-2.5">
                <Clock className="w-5 h-5 text-brand-400" />
                <h3 className="font-extrabold text-slate-900 text-base">Tiket Antrean</h3>
              </div>

              <div className="space-y-4 text-center">
                <div className="p-4 rounded-xl bg-slate-50/60 border border-slate-200">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest block mb-1">Nomor Antrean</span>
                  <div className="text-4xl font-black text-brand-400 tracking-tight">{order.queue.queueNumber}</div>
                  <span className="text-[9px] text-slate-400 font-bold block mt-2 uppercase">Status: {order.queue.status}</span>
                </div>
              </div>
            </div>
          )}

          {/* Status modifier control panel */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <div className="flex items-center gap-2.5">
              <CheckCircle2 className="w-5 h-5 text-brand-400" />
              <h3 className="font-extrabold text-slate-900 text-base">Ubah Status Pesanan</h3>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Status Saat Ini</label>
                <div className={`px-4 py-2.5 rounded-xl text-center text-xs font-bold ${getStatusColor(order.status)}`}>
                  {order.status}
                </div>
              </div>

              <div className="space-y-2 pt-2 border-t border-slate-200/80">
                <span className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Ubah Status Manual</span>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => handleStatusChange('PREPARING')}
                    disabled={updateStatusMutation.isPending}
                    className="py-2.5 rounded-xl bg-white hover:bg-blue-950/20 border border-slate-200 hover:border-blue-900/40 text-slate-400 hover:text-blue-400 font-bold text-xs transition-colors"
                  >
                    Proses
                  </button>
                  <button
                    onClick={() => handleStatusChange('READY')}
                    disabled={updateStatusMutation.isPending}
                    className="py-2.5 rounded-xl bg-white hover:bg-emerald-950/20 border border-slate-200 hover:border-emerald-900/40 text-slate-400 hover:text-emerald-400 font-bold text-xs transition-colors"
                  >
                    Siap Ambil
                  </button>
                  <button
                    onClick={() => handleStatusChange('COMPLETED')}
                    disabled={updateStatusMutation.isPending}
                    className="py-2.5 rounded-xl bg-white hover:bg-slate-100 border border-slate-200 hover:border-slate-300 text-slate-400 hover:text-slate-900 font-bold text-xs transition-colors"
                  >
                    Selesai
                  </button>
                  <button
                    onClick={() => handleStatusChange('CANCELLED')}
                    disabled={updateStatusMutation.isPending}
                    className="py-2.5 rounded-xl bg-white hover:bg-rose-950/20 border border-slate-200 hover:border-rose-900/40 text-slate-400 hover:text-rose-400 font-bold text-xs transition-colors"
                  >
                    Batalkan
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};

export default OrderDetailPage;
