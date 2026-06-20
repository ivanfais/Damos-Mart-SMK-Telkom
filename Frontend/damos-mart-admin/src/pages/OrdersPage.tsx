import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Search, Filter, Eye, RefreshCw, Calendar } from 'lucide-react';
import apiClient from '../api/client';

export const OrdersPage: React.FC = () => {
  // Filters State
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [page, setPage] = useState(1);

  // Fetch paginated admin orders
  const { data: ordersData, isLoading, refetch } = useQuery({
    queryKey: ['adminOrdersList', search, status, dateFrom, dateTo, page],
    queryFn: async () => {
      const res = await apiClient.get('/admin/orders', {
        params: {
          search: search || undefined,
          status: status || undefined,
          dateFrom: dateFrom || undefined,
          dateTo: dateTo || undefined,
          page,
          limit: 10,
        },
      });
      return res.data;
    },
  });

  const orders = ordersData?.data || [];
  const pagination = ordersData?.pagination || { page: 1, limit: 10, totalItems: 0, totalPages: 1 };

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
        <p className="text-slate-400 font-semibold text-sm">Memuat data pesanan...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Manajemen Pesanan</h1>
          <p className="text-sm text-slate-400 mt-1">Pantau pembayaran, ubah status pesanan manual, dan cetak riwayat transaksi.</p>
        </div>
        <button
          onClick={() => refetch()}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-slate-100 text-slate-600 border border-slate-200 transition-colors text-xs font-bold"
        >
          <RefreshCw className="w-4 h-4" />
          <span>Segarkan</span>
        </button>
      </div>

      {/* Filters Toolbar */}
      <div className="p-4 rounded-2xl bg-white border border-slate-200 space-y-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Search order number / customer name */}
          <div className="relative">
            <Search className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <input
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Nomor order / Nama siswa..."
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors placeholder-slate-400"
            />
          </div>

          {/* Status Filter */}
          <div className="relative">
            <Filter className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors appearance-none"
            >
              <option value="">Semua Status</option>
              <option value="PENDING">PENDING (Belum Bayar)</option>
              <option value="PAID">PAID (Terbayar)</option>
              <option value="PREPARING">PREPARING (Dipersiapkan)</option>
              <option value="IN_PRODUCTION">IN PRODUCTION (Pre-order)</option>
              <option value="READY">READY (Siap Diambil)</option>
              <option value="COMPLETED">COMPLETED (Selesai)</option>
              <option value="CANCELLED">CANCELLED (Dibatalkan)</option>
            </select>
          </div>

          {/* Date range filters */}
          <div className="relative">
            <Calendar className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => {
                setDateFrom(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors"
            />
          </div>

          <div className="relative">
            <Calendar className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <input
              type="date"
              value={dateTo}
              onChange={(e) => {
                setDateTo(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors"
            />
          </div>

        </div>
      </div>

      {/* Orders List Table */}
      <div className="glass-panel rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 text-xs font-bold text-slate-400 uppercase tracking-wider">
                <th className="py-4 px-4">Nomor Order</th>
                <th className="py-4 px-4">Nama Siswa</th>
                <th className="py-4 px-4">Tanggal Order</th>
                <th className="py-4 px-4">Total Item</th>
                <th className="py-4 px-4">Total Harga</th>
                <th className="py-4 px-4">Status Pesanan</th>
                <th className="py-4 px-4 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200/40 text-sm font-semibold text-slate-600">
              {orders.map((order: any) => (
                <tr key={order.id} className="hover:bg-white/30 transition-colors">
                  <td className="py-4 px-4 font-mono text-slate-900">{order.orderNumber}</td>
                  <td className="py-4 px-4">{order.user.fullName}</td>
                  <td className="py-4 px-4 text-slate-400 text-xs">
                    {new Date(order.createdAt).toLocaleDateString('id-ID', {
                      day: '2-digit',
                      month: '2-digit',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </td>
                  <td className="py-4 px-4 font-mono">
                    {order.orderItems?.reduce((sum: number, it: any) => sum + it.quantity, 0) || 0} pcs
                  </td>
                  <td className="py-4 px-4 text-slate-900 font-bold">{formatIDR(Number(order.total))}</td>
                  <td className="py-4 px-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold ${getStatusColor(order.status)}`}>
                      {order.status}
                    </span>
                  </td>
                  <td className="py-4 px-4 text-right">
                    <Link
                      to={`/orders/${order.id}`}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 border border-slate-300 hover:border-slate-300 text-xs font-bold text-slate-600 hover:text-slate-900 transition-all"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      <span>Detail</span>
                    </Link>
                  </td>
                </tr>
              ))}
              {orders.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-500 font-semibold">
                    Tidak ada pesanan ditemukan.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        {pagination.totalPages > 1 && (
          <div className="flex items-center justify-between p-4 border-t border-slate-200 bg-white/40">
            <button
              disabled={page === 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              className="px-4 py-2 bg-slate-100 hover:bg-slate-200 border border-slate-300 text-xs font-bold text-slate-900 rounded-lg disabled:opacity-50 disabled:pointer-events-none transition-colors"
            >
              Sebelumnya
            </button>
            <span className="text-xs font-bold text-slate-400">
              Halaman {page} dari {pagination.totalPages}
            </span>
            <button
              disabled={page === pagination.totalPages}
              onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
              className="px-4 py-2 bg-slate-100 hover:bg-slate-200 border border-slate-300 text-xs font-bold text-slate-900 rounded-lg disabled:opacity-50 disabled:pointer-events-none transition-colors"
            >
              Selanjutnya
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default OrdersPage;
