import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search, Eye, RefreshCw, X, ShieldCheck, ShoppingBag, PiggyBank, UserCheck } from 'lucide-react';
import apiClient from '../api/client';

export const UsersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  // Selected student for audit details modal
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);

  // 1. Query students list
  const { data: usersData, isLoading } = useQuery({
    queryKey: ['adminUsersList', search, page],
    queryFn: async () => {
      const res = await apiClient.get('/admin/users', {
        params: {
          search: search || undefined,
          page,
          limit: 10,
        },
      });
      return res.data;
    },
  });

  // 2. Query single student statistics
  const { data: detailsData, isLoading: detailsLoading } = useQuery({
    queryKey: ['adminUserDetails', selectedUserId],
    queryFn: async () => {
      const res = await apiClient.get(`/admin/users/${selectedUserId}`);
      return res.data.data;
    },
    enabled: !!selectedUserId,
  });

  // 3. Toggle user active mutation
  const toggleMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.put(`/admin/users/${id}/toggle-active`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminUsersList'] });
      if (selectedUserId) {
        queryClient.invalidateQueries({ queryKey: ['adminUserDetails', selectedUserId] });
      }
    },
  });

  const users = usersData?.data || [];
  const pagination = usersData?.pagination || { page: 1, limit: 10, totalItems: 0, totalPages: 1 };

  const formatIDR = (value: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(value);
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Memuat data user...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-black text-slate-900 leading-tight">Manajemen Akun Siswa</h1>
        <p className="text-sm text-slate-400 mt-1">Audit keaktifan akun siswa, tipe kepribadian DISC, dan total belanja.</p>
      </div>

      {/* Filter toolbar */}
      <div className="p-4 rounded-2xl bg-white border border-slate-200 flex items-center justify-between">
        <div className="relative w-80">
          <Search className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
          <input
            type="text"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            placeholder="Cari nama atau email siswa..."
            className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 placeholder-slate-400 focus:outline-none focus:border-brand-500 transition-colors"
          />
        </div>

        <span className="text-xs font-bold text-slate-500">
          Total: {pagination.totalItems} Siswa Terdaftar
        </span>
      </div>

      {/* Users table */}
      <div className="glass-panel rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 text-xs font-bold text-slate-400 uppercase tracking-wider">
                <th className="py-4 px-4">Nama Lengkap</th>
                <th className="py-4 px-4">Email</th>
                <th className="py-4 px-4">Nomor Telepon</th>
                <th className="py-4 px-4">Kepribadian DISC</th>
                <th className="py-4 px-4">Status Akun</th>
                <th className="py-4 px-4 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200/40 text-sm font-semibold text-slate-600">
              {users.map((user: any) => (
                <tr key={user.id} className="hover:bg-white/30 transition-colors">
                  <td className="py-4 px-4 font-bold text-slate-900">{user.fullName}</td>
                  <td className="py-4 px-4 text-slate-400 text-xs">{user.email}</td>
                  <td className="py-4 px-4">{user.phone || '-'}</td>
                  <td className="py-4 px-4">
                    {user.discType ? (
                      <span className="px-2 py-0.5 rounded-lg bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 text-[10px] font-black uppercase">
                        {user.discType}
                      </span>
                    ) : (
                      <span className="text-slate-600 text-xs">Belum Tes</span>
                    )}
                  </td>
                  <td className="py-4 px-4">
                    <button
                      onClick={() => toggleMutation.mutate(user.id)}
                      className={`px-3 py-1 rounded-full text-xs font-bold border ${
                        user.isActive
                          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
                          : 'bg-rose-500/10 text-rose-400 border-rose-500/20 hover:bg-rose-500/20'
                      } transition-colors`}
                    >
                      {user.isActive ? 'Aktif' : 'Nonaktif'}
                    </button>
                  </td>
                  <td className="py-4 px-4 text-right">
                    <button
                      onClick={() => setSelectedUserId(user.id)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 border border-slate-300 hover:border-slate-300 text-xs font-bold text-slate-600 hover:text-slate-900 transition-all"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      <span>Audit</span>
                    </button>
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-500 font-semibold">
                    Tidak ada data user terdaftar.
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

      {/* User Details Audit Modal */}
      {selectedUserId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-black/70 backdrop-blur-xs animate-[fadeIn_0.2s_ease-out]">
          <div className="w-full max-w-md glass-panel p-6 rounded-2xl shadow-2xl relative space-y-6">
            
            {/* Modal header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <ShieldCheck className="w-5 h-5 text-brand-400" />
                <h3 className="font-extrabold text-slate-900 text-base">Hasil Audit Akun Siswa</h3>
              </div>
              <button
                onClick={() => setSelectedUserId(null)}
                className="p-1 rounded-lg text-slate-500 hover:text-slate-900 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {detailsLoading ? (
              <div className="flex items-center justify-center py-10">
                <RefreshCw className="w-6 h-6 text-brand-500 animate-spin" />
              </div>
            ) : (
              detailsData && (
                <div className="space-y-6">
                  {/* Avatar and name */}
                  <div className="flex items-center gap-4 p-4 rounded-xl bg-slate-50/40 border border-slate-200">
                    <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-brand-600 to-brand-400 flex items-center justify-center text-white text-xl font-bold font-sans shadow-lg">
                      {detailsData.user.fullName.charAt(0)}
                    </div>
                    <div className="space-y-1">
                      <h4 className="font-black text-slate-900 text-base leading-tight">{detailsData.user.fullName}</h4>
                      <span className="text-[10px] text-slate-500 font-mono tracking-wide block">{detailsData.user.id}</span>
                    </div>
                  </div>

                  {/* General data lists */}
                  <div className="grid grid-cols-2 gap-4 text-xs font-semibold text-slate-400">
                    <div className="space-y-1">
                      <span className="block text-slate-500 uppercase">Status Email</span>
                      <span className="text-slate-900 font-bold block">{detailsData.user.email}</span>
                    </div>
                    <div className="space-y-1">
                      <span className="block text-slate-500 uppercase">DISC Assessment</span>
                      <span className="text-slate-900 font-bold block uppercase">{detailsData.user.discType || 'N/A'}</span>
                    </div>
                  </div>

                  {/* Stats aggregation widgets */}
                  <div className="grid grid-cols-2 gap-4 pt-4 border-t border-slate-200">
                    {/* Orders count */}
                    <div className="p-4 rounded-xl bg-white border border-slate-200 flex items-center justify-between shadow-inner">
                      <div className="space-y-1">
                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Frekuensi Order</span>
                        <span className="text-lg font-black text-slate-900 block">{detailsData.orderCount} kali</span>
                      </div>
                      <div className="p-2.5 bg-blue-500/10 rounded-lg text-blue-400 flex items-center justify-center">
                        <ShoppingBag className="w-5 h-5" />
                      </div>
                    </div>

                    {/* Total spent */}
                    <div className="p-4 rounded-xl bg-white border border-slate-200 flex items-center justify-between shadow-inner">
                      <div className="space-y-1">
                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Total Belanja</span>
                        <span className="text-base font-black text-emerald-400 block">{formatIDR(detailsData.totalSpent)}</span>
                      </div>
                      <div className="p-2.5 bg-emerald-500/10 rounded-lg text-emerald-400 flex items-center justify-center">
                        <PiggyBank className="w-5 h-5" />
                      </div>
                    </div>
                  </div>

                  {/* Action row */}
                  <div className="pt-4 border-t border-slate-200">
                    <button
                      onClick={() => toggleMutation.mutate(detailsData.user.id)}
                      className={`w-full flex items-center justify-center gap-2 py-3 rounded-xl font-bold text-xs border ${
                        detailsData.user.isActive
                          ? 'bg-rose-500/10 text-rose-400 border-rose-500/20 hover:bg-rose-500/20'
                          : 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
                      } transition-colors`}
                    >
                      <UserCheck className="w-4 h-4" />
                      <span>{detailsData.user.isActive ? 'Nonaktifkan Akun Siswa' : 'Aktifkan Akun Siswa'}</span>
                    </button>
                  </div>
                </div>
              )
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersPage;
