import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link, useNavigate } from 'react-router-dom';
import {
  Search,
  Filter,
  Plus,
  Edit2,
  Trash2,
  Image as ImageIcon,
  Layers,
  Sparkles,
  RefreshCw,
} from 'lucide-react';
import apiClient from '../api/client';
import { assetUrl } from '../config/env';

export const ProductsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  // Search and filter state parameters
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [page, setPage] = useState(1);

  // 1. Fetch categories for filters dropdown
  const { data: categories } = useQuery({
    queryKey: ['adminCategoriesList'],
    queryFn: async () => {
      const res = await apiClient.get('/categories');
      return res.data.data;
    },
  });

  // 2. Fetch paginated products matching search filters
  const { data: productsData, isLoading, refetch } = useQuery({
    queryKey: ['adminProductsList', search, selectedCategory, page],
    queryFn: async () => {
      const res = await apiClient.get('/admin/products', {
        params: {
          search: search || undefined,
          category: selectedCategory || undefined,
          page,
          limit: 10,
        },
      });
      return res.data;
    },
  });

  // 3. Delete product mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/admin/products/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminProductsList'] });
    },
  });

  const handleDelete = (id: string, name: string) => {
    if (confirm(`Apakah Anda yakin ingin menghapus produk "${name}"?`)) {
      deleteMutation.mutate(id);
    }
  };

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
        <p className="text-slate-400 font-semibold text-sm">Memuat data produk...</p>
      </div>
    );
  }

  const products = productsData?.data || [];
  const pagination = productsData?.pagination || { page: 1, limit: 10, totalItems: 0, totalPages: 1 };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Manajemen Katalog Produk</h1>
          <p className="text-sm text-slate-400 mt-1">Kelola data produk, stok barang, varian ukuran/harga, dan pre-order.</p>
        </div>
        <Link
          to="/products/new"
          className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold shadow-lg shadow-brand-500/25 active:scale-[0.98] transition-all text-sm"
        >
          <Plus className="w-5 h-5" />
          <span>Tambah Produk</span>
        </Link>
      </div>

      {/* Filters & Search Toolbar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 p-4 rounded-2xl bg-white border border-slate-200">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
          <input
            type="text"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            placeholder="Cari nama produk..."
            className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 placeholder-slate-400 focus:outline-none focus:border-brand-500 transition-colors"
          />
        </div>

        {/* Categories Select Filter */}
        <div className="relative">
          <Filter className="absolute left-4 top-3 w-5 h-5 text-slate-500" />
          <select
            value={selectedCategory}
            onChange={(e) => {
              setSelectedCategory(e.target.value);
              setPage(1);
            }}
            className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors appearance-none"
          >
            <option value="">Semua Kategori</option>
            {categories?.map((cat: any) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>
        
        {/* Helper info */}
        <div className="flex items-center justify-end text-xs font-semibold text-slate-500 pr-2">
          <span>Menampilkan {products.length} dari {pagination.totalItems} Produk</span>
        </div>
      </div>

      {/* Products Table */}
      <div className="glass-panel rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 text-xs font-bold text-slate-400 uppercase tracking-wider">
                <th className="py-4 px-4 w-20">Gambar</th>
                <th className="py-4 px-4">Nama Produk</th>
                <th className="py-4 px-4">Kategori</th>
                <th className="py-4 px-4">Harga Dasar</th>
                <th className="py-4 px-4">Stok</th>
                <th className="py-4 px-4">Jenis</th>
                <th className="py-4 px-4">Status</th>
                <th className="py-4 px-4 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200/40 text-sm font-semibold text-slate-600">
              {products.map((product: any) => (
                <tr key={product.id} className="hover:bg-white/30 transition-colors">
                  {/* Image */}
                  <td className="py-4 px-4">
                    {product.imageUrl ? (
                      <img
                        src={assetUrl(product.imageUrl)}
                        alt={product.name}
                        className="w-12 h-12 object-cover rounded-xl border border-slate-200"
                        onError={(e) => {
                          (e.target as any).src = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&auto=format&fit=crop&q=60';
                        }}
                      />
                    ) : (
                      <div className="w-12 h-12 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-center text-slate-600">
                        <ImageIcon className="w-5 h-5" />
                      </div>
                    )}
                  </td>

                  {/* Name and description details */}
                  <td className="py-4 px-4">
                    <div className="flex flex-col">
                      <span className="font-extrabold text-slate-900 text-sm">{product.name}</span>
                      {product.variants?.length > 0 && (
                        <div className="flex items-center gap-1.5 mt-1 text-brand-400 font-bold text-[10px] uppercase">
                          <Layers className="w-3.5 h-3.5" />
                          <span>{product.variants.length} Varian</span>
                        </div>
                      )}
                    </div>
                  </td>

                  {/* Category */}
                  <td className="py-4 px-4 text-slate-400">{product.category.name}</td>

                  {/* Price */}
                  <td className="py-4 px-4 text-slate-900 font-bold">{formatIDR(Number(product.price))}</td>

                  {/* Stock */}
                  <td className="py-4 px-4">
                    {product.isPreorder ? (
                      <span className="text-xs font-bold text-pink-400">Pre-Order</span>
                    ) : (
                      <span
                        className={`font-mono font-bold ${
                          product.stock < 10 ? 'text-rose-400' : 'text-slate-700'
                        }`}
                      >
                        {product.stock} pcs
                      </span>
                    )}
                  </td>

                  {/* Preorder */}
                  <td className="py-4 px-4">
                    {product.isPreorder ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-pink-500/10 text-pink-400 border border-pink-500/20 text-xs font-bold">
                        <Sparkles className="w-3.5 h-3.5" />
                        <span>Pre-Order</span>
                      </span>
                    ) : (
                      <span className="text-slate-500 text-xs">Instan</span>
                    )}
                  </td>

                  {/* Status Toggle */}
                  <td className="py-4 px-4">
                    <span
                      className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-bold ${
                        product.isActive
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                      }`}
                    >
                      {product.isActive ? 'Aktif' : 'Nonaktif'}
                    </span>
                  </td>

                  {/* Actions */}
                  <td className="py-4 px-4 text-right space-x-2">
                    <button
                      onClick={() => navigate(`/products/${product.id}/edit`)}
                      className="inline-flex p-2 rounded-xl bg-slate-100 hover:bg-slate-200 border border-slate-300 hover:border-slate-300 text-slate-600 hover:text-slate-900 transition-all"
                      title="Edit Produk"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(product.id, product.name)}
                      className="inline-flex p-2 rounded-xl bg-slate-100 hover:bg-rose-950/20 border border-slate-300 hover:border-rose-900/40 text-slate-400 hover:text-rose-400 transition-all"
                      title="Hapus Produk"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
              {products.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-500 font-semibold">
                    Tidak ada produk ditemukan matching filter pencarian.
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

export default ProductsPage;
