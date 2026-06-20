import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Search,
  Filter,
  RefreshCw,
  Eye,
  Trash2,
  X,
  Send,
  Inbox,
  Clock,
  CheckCircle2,
  XCircle,
  AlertTriangle,
} from 'lucide-react';
import apiClient from '../api/client';

// ---- Label & style maps ----
const STATUS_META: Record<string, { label: string; badge: string }> = {
  OPEN: { label: 'Baru', badge: 'bg-amber-500/10 text-amber-400 border border-amber-500/20' },
  IN_PROGRESS: { label: 'Diproses', badge: 'bg-blue-500/10 text-blue-400 border border-blue-500/20' },
  RESOLVED: { label: 'Selesai', badge: 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' },
  REJECTED: { label: 'Ditolak', badge: 'bg-rose-500/10 text-rose-400 border border-rose-500/20' },
};

const CATEGORY_META: Record<string, string> = {
  PRODUCT: 'Produk',
  SERVICE: 'Pelayanan',
  ORDER: 'Pesanan',
  QUEUE: 'Antrean',
  OTHER: 'Lainnya',
};

const PRIORITY_META: Record<string, { label: string; badge: string }> = {
  LOW: { label: 'Rendah', badge: 'bg-slate-500/10 text-slate-400 border border-slate-500/20' },
  MEDIUM: { label: 'Sedang', badge: 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20' },
  HIGH: { label: 'Tinggi', badge: 'bg-rose-500/10 text-rose-400 border border-rose-500/20' },
};

const formatDate = (value: string) =>
  new Date(value).toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });

export const ComplaintsPage: React.FC = () => {
  const queryClient = useQueryClient();

  // Filters
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [priority, setPriority] = useState('');
  const [page, setPage] = useState(1);

  // Detail modal
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [responseText, setResponseText] = useState('');

  // Stats
  const { data: statsData } = useQuery({
    queryKey: ['adminComplaintStats'],
    queryFn: async () => {
      const res = await apiClient.get('/admin/complaints/stats/summary');
      return res.data.data;
    },
  });
  const stats = statsData || { total: 0, open: 0, inProgress: 0, resolved: 0, rejected: 0 };

  // List
  const { data: listData, isLoading, refetch } = useQuery({
    queryKey: ['adminComplaintsList', search, status, category, priority, page],
    queryFn: async () => {
      const res = await apiClient.get('/admin/complaints', {
        params: {
          search: search || undefined,
          status: status || undefined,
          category: category || undefined,
          priority: priority || undefined,
          page,
          limit: 10,
        },
      });
      return res.data;
    },
  });
  const complaints = listData?.data || [];
  const pagination = listData?.pagination || { page: 1, limit: 10, totalItems: 0, totalPages: 1 };

  // Selected detail
  const { data: detailData } = useQuery({
    queryKey: ['adminComplaintDetail', selectedId],
    enabled: !!selectedId,
    queryFn: async () => {
      const res = await apiClient.get(`/admin/complaints/${selectedId}`);
      return res.data.data;
    },
  });

  const invalidateAll = () => {
    queryClient.invalidateQueries({ queryKey: ['adminComplaintsList'] });
    queryClient.invalidateQueries({ queryKey: ['adminComplaintStats'] });
    queryClient.invalidateQueries({ queryKey: ['adminComplaintDetail', selectedId] });
  };

  // Mutations
  const statusMutation = useMutation({
    mutationFn: async (payload: { status?: string; priority?: string }) => {
      await apiClient.put(`/admin/complaints/${selectedId}/status`, payload);
    },
    onSuccess: invalidateAll,
  });

  const respondMutation = useMutation({
    mutationFn: async (payload: { adminResponse: string; status?: string }) => {
      await apiClient.put(`/admin/complaints/${selectedId}/respond`, payload);
    },
    onSuccess: () => {
      setResponseText('');
      invalidateAll();
    },
    onError: (err: any) => alert(err.response?.data?.error?.message || 'Gagal mengirim balasan.'),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/admin/complaints/${id}`);
    },
    onSuccess: () => {
      setSelectedId(null);
      invalidateAll();
    },
    onError: (err: any) => alert(err.response?.data?.error?.message || 'Gagal menghapus komplain.'),
  });

  const closeModal = () => {
    setSelectedId(null);
    setResponseText('');
  };

  const handleDelete = (id: string, subject: string) => {
    if (confirm(`Hapus komplain "${subject}"?`)) {
      deleteMutation.mutate(id);
    }
  };

  const statCards = [
    { label: 'Total Komplain', value: stats.total, icon: Inbox, color: 'text-slate-600' },
    { label: 'Baru', value: stats.open, icon: AlertTriangle, color: 'text-amber-400' },
    { label: 'Diproses', value: stats.inProgress, icon: Clock, color: 'text-blue-400' },
    { label: 'Selesai', value: stats.resolved, icon: CheckCircle2, color: 'text-emerald-400' },
    { label: 'Ditolak', value: stats.rejected, icon: XCircle, color: 'text-rose-400' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Manajemen Komplain</h1>
          <p className="text-sm text-slate-400 mt-1">
            Tinjau keluhan siswa, ubah status & prioritas, lalu kirim balasan resmi.
          </p>
        </div>
        <button
          onClick={() => refetch()}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-slate-100 text-slate-600 border border-slate-200 transition-colors text-xs font-bold"
        >
          <RefreshCw className="w-4 h-4" />
          <span>Segarkan</span>
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <div key={card.label} className="glass-panel p-4 rounded-2xl border border-slate-200">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">{card.label}</span>
                <Icon className={`w-5 h-5 ${card.color}`} />
              </div>
              <p className="text-2xl font-black text-slate-900 mt-2">{card.value}</p>
            </div>
          );
        })}
      </div>

      {/* Filters */}
      <div className="p-4 rounded-2xl bg-white border border-slate-200">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="relative">
            <Search className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <input
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Cari subjek / nama siswa..."
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors placeholder-slate-400"
            />
          </div>

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
              <option value="OPEN">Baru</option>
              <option value="IN_PROGRESS">Diproses</option>
              <option value="RESOLVED">Selesai</option>
              <option value="REJECTED">Ditolak</option>
            </select>
          </div>

          <div className="relative">
            <Filter className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <select
              value={category}
              onChange={(e) => {
                setCategory(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors appearance-none"
            >
              <option value="">Semua Kategori</option>
              <option value="PRODUCT">Produk</option>
              <option value="SERVICE">Pelayanan</option>
              <option value="ORDER">Pesanan</option>
              <option value="QUEUE">Antrean</option>
              <option value="OTHER">Lainnya</option>
            </select>
          </div>

          <div className="relative">
            <Filter className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
            <select
              value={priority}
              onChange={(e) => {
                setPriority(e.target.value);
                setPage(1);
              }}
              className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors appearance-none"
            >
              <option value="">Semua Prioritas</option>
              <option value="LOW">Rendah</option>
              <option value="MEDIUM">Sedang</option>
              <option value="HIGH">Tinggi</option>
            </select>
          </div>
        </div>
      </div>

      {/* List */}
      <div className="glass-panel rounded-2xl overflow-hidden shadow-xl">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20 gap-4">
            <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
            <p className="text-slate-400 font-semibold text-sm">Memuat data komplain...</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 text-xs font-bold text-slate-400 uppercase tracking-wider">
                  <th className="py-4 px-4">Subjek</th>
                  <th className="py-4 px-4">Pelapor</th>
                  <th className="py-4 px-4">Kategori</th>
                  <th className="py-4 px-4">Prioritas</th>
                  <th className="py-4 px-4">Status</th>
                  <th className="py-4 px-4">Tanggal</th>
                  <th className="py-4 px-4 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200/40 text-sm font-semibold text-slate-600">
                {complaints.map((c: any) => (
                  <tr key={c.id} className="hover:bg-white/30 transition-colors">
                    <td className="py-4 px-4 text-slate-900 max-w-xs truncate">{c.subject}</td>
                    <td className="py-4 px-4">{c.user?.fullName || 'Tanpa Akun'}</td>
                    <td className="py-4 px-4 text-slate-400">{CATEGORY_META[c.category] || c.category}</td>
                    <td className="py-4 px-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold ${PRIORITY_META[c.priority]?.badge}`}>
                        {PRIORITY_META[c.priority]?.label || c.priority}
                      </span>
                    </td>
                    <td className="py-4 px-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold ${STATUS_META[c.status]?.badge}`}>
                        {STATUS_META[c.status]?.label || c.status}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-slate-400 text-xs">{formatDate(c.createdAt)}</td>
                    <td className="py-4 px-4 text-right">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          onClick={() => {
                            setSelectedId(c.id);
                            setResponseText('');
                          }}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 border border-slate-300 hover:border-slate-300 text-xs font-bold text-slate-600 hover:text-slate-900 transition-all"
                        >
                          <Eye className="w-3.5 h-3.5" />
                          <span>Detail</span>
                        </button>
                        <button
                          onClick={() => handleDelete(c.id, c.subject)}
                          className="p-2 rounded-lg bg-white border border-slate-200 hover:border-rose-900/40 text-slate-400 hover:text-rose-400 transition-colors"
                          title="Hapus"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {complaints.length === 0 && (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-slate-500 font-semibold">
                      Tidak ada komplain ditemukan.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

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

      {/* Detail Modal */}
      {selectedId && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4"
          onClick={closeModal}
        >
          <div
            className="glass-panel w-full max-w-2xl rounded-2xl shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {!detailData ? (
              <div className="flex items-center justify-center py-20">
                <RefreshCw className="w-8 h-8 text-brand-500 animate-spin" />
              </div>
            ) : (
              <div className="p-6 space-y-6">
                {/* Modal header */}
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <h3 className="text-lg font-black text-slate-900">{detailData.subject}</h3>
                    <p className="text-xs text-slate-500 mt-1">Dibuat {formatDate(detailData.createdAt)}</p>
                  </div>
                  <button
                    onClick={closeModal}
                    className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                {/* Reporter & meta */}
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div className="p-3 rounded-xl bg-slate-50/40 border border-slate-200">
                    <p className="text-xs font-bold text-slate-500 uppercase">Pelapor</p>
                    <p className="text-slate-900 font-semibold mt-1">{detailData.user?.fullName || 'Tanpa Akun'}</p>
                    <p className="text-xs text-slate-400">{detailData.user?.email || '-'}</p>
                    {detailData.user?.phone && <p className="text-xs text-slate-400">{detailData.user.phone}</p>}
                  </div>
                  <div className="p-3 rounded-xl bg-slate-50/40 border border-slate-200">
                    <p className="text-xs font-bold text-slate-500 uppercase">Kategori</p>
                    <p className="text-slate-900 font-semibold mt-1">
                      {CATEGORY_META[detailData.category] || detailData.category}
                    </p>
                    {detailData.order && (
                      <p className="text-xs text-slate-400 mt-1">Order: {detailData.order.orderNumber}</p>
                    )}
                  </div>
                </div>

                {/* Description */}
                <div className="p-4 rounded-xl bg-slate-50/40 border border-slate-200">
                  <p className="text-xs font-bold text-slate-500 uppercase mb-2">Isi Komplain</p>
                  <p className="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">
                    {detailData.description}
                  </p>
                </div>

                {/* Status & priority controls */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Status</label>
                    <select
                      value={detailData.status}
                      onChange={(e) => statusMutation.mutate({ status: e.target.value })}
                      disabled={statusMutation.isPending}
                      className="w-full px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                    >
                      <option value="OPEN">Baru</option>
                      <option value="IN_PROGRESS">Diproses</option>
                      <option value="RESOLVED">Selesai</option>
                      <option value="REJECTED">Ditolak</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                      Prioritas
                    </label>
                    <select
                      value={detailData.priority}
                      onChange={(e) => statusMutation.mutate({ priority: e.target.value })}
                      disabled={statusMutation.isPending}
                      className="w-full px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                    >
                      <option value="LOW">Rendah</option>
                      <option value="MEDIUM">Sedang</option>
                      <option value="HIGH">Tinggi</option>
                    </select>
                  </div>
                </div>

                {/* Existing response */}
                {detailData.adminResponse && (
                  <div className="p-4 rounded-xl bg-brand-500/5 border border-brand-500/20">
                    <p className="text-xs font-bold text-brand-400 uppercase mb-2">Balasan Terkirim</p>
                    <p className="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">
                      {detailData.adminResponse}
                    </p>
                    {detailData.respondedAt && (
                      <p className="text-xs text-slate-500 mt-2">Dibalas {formatDate(detailData.respondedAt)}</p>
                    )}
                  </div>
                )}

                {/* Respond box */}
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                    {detailData.adminResponse ? 'Perbarui Balasan' : 'Tulis Balasan'}
                  </label>
                  <textarea
                    value={responseText}
                    onChange={(e) => setResponseText(e.target.value)}
                    rows={3}
                    placeholder="Tulis tanggapan resmi untuk siswa..."
                    className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:border-brand-500 resize-none placeholder-slate-400"
                  />
                  <div className="flex justify-end gap-3 mt-3">
                    <button
                      onClick={() => respondMutation.mutate({ adminResponse: responseText })}
                      disabled={!responseText.trim() || respondMutation.isPending}
                      className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-sm disabled:opacity-50 transition-colors"
                    >
                      {respondMutation.isPending ? (
                        <RefreshCw className="w-4 h-4 animate-spin" />
                      ) : (
                        <Send className="w-4 h-4" />
                      )}
                      <span>Kirim Balasan</span>
                    </button>
                    <button
                      onClick={() =>
                        respondMutation.mutate({ adminResponse: responseText || detailData.adminResponse || '-', status: 'RESOLVED' })
                      }
                      disabled={respondMutation.isPending}
                      className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600/90 hover:bg-emerald-500 text-white font-bold text-sm disabled:opacity-50 transition-colors"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>Balas & Selesaikan</span>
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default ComplaintsPage;
