import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Edit2, Trash2, Image as ImageIcon, Save, RefreshCw, X, FolderKanban } from 'lucide-react';
import apiClient from '../api/client';

export const CategoriesPage: React.FC = () => {
  const queryClient = useQueryClient();

  // Selected Category for Editing state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [sortOrder, setSortOrder] = useState(0);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  // Form opening/visibility state
  const [formOpen, setFormOpen] = useState(false);

  // 1. Fetch categories
  const { data: categories, isLoading } = useQuery({
    queryKey: ['adminCategoriesList'],
    queryFn: async () => {
      const res = await apiClient.get('/categories');
      return res.data.data;
    },
  });

  // 2. Add/Edit Mutation
  const saveMutation = useMutation({
    mutationFn: async () => {
      const formData = new FormData();
      formData.append('name', name);
      formData.append('sortOrder', String(sortOrder));
      if (imageFile) {
        formData.append('icon', imageFile);
      }

      // Let the browser set the multipart Content-Type (with boundary) automatically.
      if (editingId) {
        await apiClient.put(`/admin/categories/${editingId}`, formData, {
          headers: { 'Content-Type': undefined },
        });
      } else {
        await apiClient.post('/admin/categories', formData, {
          headers: { 'Content-Type': undefined },
        });
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminCategoriesList'] });
      resetForm();
    },
  });

  // 3. Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      await apiClient.delete(`/admin/categories/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminCategoriesList'] });
    },
    onError: (err: any) => {
      alert(err.response?.data?.error?.message || 'Gagal menghapus kategori.');
    },
  });

  const resetForm = () => {
    setEditingId(null);
    setName('');
    setSortOrder(0);
    setImageFile(null);
    setImagePreview(null);
    setFormOpen(false);
  };

  const handleEdit = (cat: any) => {
    setEditingId(cat.id);
    setName(cat.name);
    setSortOrder(cat.sortOrder);
    setImagePreview(cat.iconUrl ? `http://localhost:3000${cat.iconUrl}` : null);
    setFormOpen(true);
  };

  const handleDelete = (id: string, catName: string) => {
    if (confirm(`Apakah Anda yakin ingin menghapus kategori "${catName}"?`)) {
      deleteMutation.mutate(id);
    }
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;
    saveMutation.mutate();
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Memuat data kategori...</p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Manajemen Kategori Produk</h1>
          <p className="text-sm text-slate-400 mt-1">Atur kategori makanan, minuman, dan atribut sekolah di koperasi.</p>
        </div>
        {!formOpen && (
          <button
            onClick={() => setFormOpen(true)}
            className="flex items-center gap-2 px-5 py-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold shadow-lg shadow-brand-500/20 hover:shadow-brand-500/35 transition-all text-sm active:scale-[0.98]"
          >
            <Plus className="w-5 h-5" />
            <span>Tambah Kategori</span>
          </button>
        )}
      </div>

      {/* Main Grid: list categories and form */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        
        {/* Categories Grid (Takes 2 cols if form open, else 3) */}
        <div className={`glass-panel p-6 rounded-2xl shadow-xl space-y-6 ${formOpen ? 'lg:col-span-2' : 'lg:col-span-3'}`}>
          <div className="flex items-center gap-2.5 mb-2">
            <FolderKanban className="w-5 h-5 text-brand-400" />
            <h3 className="font-extrabold text-slate-900 text-base">Daftar Kategori Aktif</h3>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {categories?.map((cat: any) => (
              <div
                key={cat.id}
                className="p-4 rounded-xl bg-slate-50/40 border border-slate-200 flex items-center justify-between group hover:border-brand-500/35 transition-colors"
              >
                <div className="flex items-center gap-3.5">
                  <div className="w-12 h-12 bg-white border border-slate-200 rounded-xl flex items-center justify-center overflow-hidden">
                    {cat.iconUrl ? (
                      <img
                        src={`http://localhost:3000${cat.iconUrl}`}
                        alt={cat.name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          (e.target as any).src = 'data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2280%22>📦</text></svg>';
                        }}
                      />
                    ) : (
                      <FolderKanban className="w-6 h-6 text-slate-500" />
                    )}
                  </div>
                  <div>
                    <h4 className="font-extrabold text-slate-900 text-sm">{cat.name}</h4>
                    <span className="text-[10px] text-slate-500 font-bold uppercase">Urutan: {cat.sortOrder}</span>
                  </div>
                </div>

                {/* Hover Actions */}
                <div className="flex items-center gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={() => handleEdit(cat)}
                    className="p-2 rounded-lg bg-white border border-slate-200 hover:border-slate-300 text-slate-400 hover:text-slate-900 transition-colors"
                    title="Ubah Kategori"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => handleDelete(cat.id, cat.name)}
                    className="p-2 rounded-lg bg-white border border-slate-200 hover:border-rose-900/40 text-slate-400 hover:text-rose-400 transition-colors"
                    title="Hapus Kategori"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))}
            {(!categories || categories.length === 0) && (
              <div className="col-span-full py-8 text-center text-slate-500 font-semibold">
                Belum ada kategori yang ditambahkan.
              </div>
            )}
          </div>
        </div>

        {/* Inline Creator / Editor Form (Conditionally visible) */}
        {formOpen && (
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6 animate-[fadeIn_0.3s_ease-out]">
            <div className="flex items-center justify-between">
              <h3 className="font-extrabold text-slate-900 text-base">
                {editingId ? 'Ubah Kategori' : 'Kategori Baru'}
              </h3>
              <button
                onClick={resetForm}
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5">
              {/* Name */}
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Nama Kategori</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="cth: Makanan Ringan"
                  className="w-full px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                />
              </div>

              {/* Sort Order */}
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Urutan Tampil (Sort Order)</label>
                <input
                  type="number"
                  required
                  value={sortOrder}
                  onChange={(e) => setSortOrder(Number(e.target.value))}
                  className="w-full px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-900 focus:outline-none focus:border-brand-500"
                />
              </div>

              {/* Icon Image */}
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Ikon / Gambar Kategori</label>
                <div className="mt-2 flex items-center gap-4">
                  <div className="w-16 h-16 bg-slate-50 border border-slate-200 rounded-xl overflow-hidden flex items-center justify-center text-slate-500">
                    {imagePreview ? (
                      <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
                    ) : (
                      <ImageIcon className="w-6 h-6" />
                    )}
                  </div>
                  <label className="px-4 py-2.5 bg-slate-100 border border-slate-300 hover:bg-slate-200 text-xs font-bold text-slate-900 rounded-xl cursor-pointer">
                    Pilih Berkas
                    <input type="file" accept="image/*" onChange={handleImageChange} className="hidden" />
                  </label>
                </div>
              </div>

              {/* Buttons */}
              <div className="flex gap-3 pt-4 border-t border-slate-200/80">
                <button
                  type="button"
                  onClick={resetForm}
                  className="flex-1 py-2.5 rounded-xl border border-slate-200 hover:bg-slate-100 font-semibold text-slate-400 hover:text-slate-900 transition-colors text-xs"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={saveMutation.isPending}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-brand-600 hover:bg-brand-500 font-bold text-white shadow-md shadow-brand-500/10 disabled:opacity-50 transition-colors text-xs"
                >
                  {saveMutation.isPending ? (
                    <RefreshCw className="w-4 h-4 animate-spin" />
                  ) : (
                    <>
                      <Save className="w-4 h-4" />
                      <span>Simpan</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        )}

      </div>
    </div>
  );
};

export default CategoriesPage;
