import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Save, Plus, Trash2, Image as ImageIcon, Sparkles, AlertCircle, RefreshCw } from 'lucide-react';
import apiClient from '../api/client';
import { assetUrl } from '../config/env';

export const ProductFormPage: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isEditMode = !!id;

  // Form Fields State
  const [name, setName] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState(0);
  const [stock, setStock] = useState(0);
  const [isPreorder, setIsPreorder] = useState(false);
  const [preorderEstimation, setPreorderEstimation] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [isActive, setIsActive] = useState(true);

  // Variants management (Admin list)
  const [variants, setVariants] = useState<Array<{ id?: string; variantName: string; additionalPrice: number; stock: number }>>([]);
  const [newVarName, setNewVarName] = useState('');
  const [newVarPrice, setNewVarPrice] = useState(0);
  const [newVarStock, setNewVarStock] = useState(0);

  // Fetch categories list
  const { data: categories } = useQuery({
    queryKey: ['adminCategoriesList'],
    queryFn: async () => {
      const res = await apiClient.get('/categories');
      return res.data.data;
    },
  });

  // Fetch product if editing
  const { data: productData, isLoading } = useQuery({
    queryKey: ['adminProductDetails', id],
    queryFn: async () => {
      const res = await apiClient.get(`/products/${id}`);
      return res.data.data;
    },
    enabled: isEditMode,
  });

  // Populate data when editing
  useEffect(() => {
    if (isEditMode && productData) {
      setName(productData.name);
      setCategoryId(productData.categoryId);
      setDescription(productData.description || '');
      setPrice(Number(productData.price));
      setStock(productData.stock);
      setIsPreorder(productData.isPreorder);
      setPreorderEstimation(productData.preorderEstimation || '');
      setIsActive(productData.isActive);
      setVariants(productData.variants || []);
      if (productData.imageUrl) {
        setImagePreview(assetUrl(productData.imageUrl));
      }
    }
  }, [isEditMode, productData]);

  // Image Selection Handler
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  // Submit Mutation
  const saveMutation = useMutation({
    mutationFn: async () => {
      const formData = new FormData();
      formData.append('name', name);
      formData.append('categoryId', categoryId);
      formData.append('description', description);
      formData.append('price', String(price));
      formData.append('stock', String(isPreorder ? 0 : stock));
      formData.append('isPreorder', String(isPreorder));
      formData.append('preorderEstimation', preorderEstimation);
      formData.append('isActive', String(isActive));
      
      if (imageFile) {
        formData.append('image', imageFile);
      }

      let product;
      // Note: do NOT set Content-Type manually for FormData. Let the browser set
      // it to "multipart/form-data; boundary=..." automatically, otherwise the
      // server cannot parse the upload ("Multipart: Boundary not found").
      if (isEditMode) {
        const res = await apiClient.put(`/admin/products/${id}`, formData, {
          headers: { 'Content-Type': undefined },
        });
        product = res.data.data;
      } else {
        const res = await apiClient.post('/admin/products', formData, {
          headers: { 'Content-Type': undefined },
        });
        product = res.data.data;
      }

      // Save variants if not in edit mode (we do separate variant API calls for edit mode variants update, or if edit mode we already handled them)
      if (!isEditMode && variants.length > 0) {
        for (const variant of variants) {
          await apiClient.post(`/admin/products/${product.id}/variants`, variant);
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminProductsList'] });
      navigate('/products');
    },
  });

  const handleAddVariantLocal = () => {
    if (!newVarName) return;
    
    // In edit mode: call direct add variant API
    if (isEditMode) {
      apiClient
        .post(`/admin/products/${id}/variants`, {
          variantName: newVarName,
          additionalPrice: newVarPrice,
          stock: isPreorder ? 0 : newVarStock,
        })
        .then(() => {
          queryClient.invalidateQueries({ queryKey: ['adminProductDetails', id] });
          setNewVarName('');
          setNewVarPrice(0);
          setNewVarStock(0);
        });
    } else {
      // In create mode: add to local state array
      setVariants((prev) => [
        ...prev,
        {
          variantName: newVarName,
          additionalPrice: newVarPrice,
          stock: isPreorder ? 0 : newVarStock,
        },
      ]);
      setNewVarName('');
      setNewVarPrice(0);
      setNewVarStock(0);
    }
  };

  const handleDeleteVariantLocal = (variantId?: string, index?: number) => {
    if (isEditMode && variantId) {
      if (confirm('Apakah Anda yakin ingin menghapus varian produk ini?')) {
        apiClient.delete(`/admin/products/${id}/variants/${variantId}`).then(() => {
          queryClient.invalidateQueries({ queryKey: ['adminProductDetails', id] });
          queryClient.invalidateQueries({ queryKey: ['adminProductsList'] });
        });
      }
    } else if (index !== undefined) {
      setVariants((prev) => prev.filter((_, idx) => idx !== index));
    }
  };

  // Edit a variant field locally (applies to both create & edit mode).
  const handleVariantFieldChange = (
    index: number,
    field: 'variantName' | 'additionalPrice' | 'stock',
    value: string | number
  ) => {
    setVariants((prev) => prev.map((v, idx) => (idx === index ? { ...v, [field]: value } : v)));
  };

  // Persist a single variant change to the backend (edit mode only).
  const handleSaveVariant = (index: number) => {
    const v = variants[index];
    if (!v.id) return;
    apiClient
      .put(`/admin/products/${id}/variants/${v.id}`, {
        variantName: v.variantName,
        additionalPrice: Number(v.additionalPrice) || 0,
        stock: isPreorder ? 0 : Number(v.stock) || 0,
      })
      .then(() => {
        queryClient.invalidateQueries({ queryKey: ['adminProductDetails', id] });
        queryClient.invalidateQueries({ queryKey: ['adminProductsList'] });
      })
      .catch((err) => alert(err.response?.data?.error?.message || 'Gagal menyimpan varian.'));
  };

  // When a product has variants, the main stock is derived from their sum.
  const hasVariants = variants.length > 0;
  const variantStockTotal = variants.reduce((sum, v) => sum + (Number(v.stock) || 0), 0);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!categoryId) {
      alert('Pilih Kategori Produk terlebih dahulu');
      return;
    }
    saveMutation.mutate();
  };

  if (isEditMode && isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Memuat data form produk...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Back button */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate('/products')}
          className="flex items-center gap-2 text-sm font-bold text-slate-400 hover:text-slate-900 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Kembali ke Katalog</span>
        </button>
        <span className="text-xs font-bold text-slate-500 uppercase tracking-widest">
          {isEditMode ? 'Ubah Informasi' : 'Buat Item Baru'}
        </span>
      </div>

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left column: product fields */}
        <div className="lg:col-span-2 space-y-6">
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <h2 className="font-extrabold text-slate-900 text-base">Detail Informasi Barang</h2>

            {/* Name */}
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Nama Barang</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="cth: Seragam Pramuka, Roti Sandwich"
                className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors"
              />
            </div>

            {/* Category and Preorder row */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Kategori</label>
                <select
                  required
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors"
                >
                  <option value="">Pilih Kategori</option>
                  {categories?.map((cat: any) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Preorder configuration toggle */}
              <div className="flex flex-col justify-end">
                <label className="flex items-center gap-3 cursor-pointer p-3 rounded-xl bg-white border border-slate-200 select-none">
                  <input
                    type="checkbox"
                    checked={isPreorder}
                    onChange={(e) => {
                      const checked = e.target.checked;
                      setIsPreorder(checked);
                      if (checked) {
                        setStock(0);
                        setNewVarStock(0);
                        setVariants((prev) => prev.map((v) => ({ ...v, stock: 0 })));
                      }
                    }}
                    className="w-4.5 h-4.5 rounded bg-slate-50 border-slate-200 text-brand-600 focus:ring-brand-500"
                  />
                  <div className="flex flex-col">
                    <span className="text-sm font-extrabold text-slate-900">Aktifkan Pre-Order</span>
                    <span className="text-[10px] text-slate-500 font-bold">Produk membutuhkan waktu pembuatan</span>
                  </div>
                </label>
              </div>
            </div>

            {/* Conditional Pre-order estimation input */}
            {isPreorder && (
              <div className="p-4 rounded-xl bg-pink-500/5 border border-pink-500/10 flex items-start gap-4 animate-[fadeIn_0.2s_ease-out]">
                <Sparkles className="w-5 h-5 text-pink-400 flex-shrink-0 mt-0.5" />
                <div className="flex-1 space-y-1.5">
                  <label className="block text-xs font-bold text-pink-400 uppercase tracking-wider">Estimasi Waktu Pembuatan</label>
                  <input
                    type="text"
                    required
                    value={preorderEstimation}
                    onChange={(e) => setPreorderEstimation(e.target.value)}
                    placeholder="cth: 7 hari kerja, 2 minggu"
                    className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors placeholder-slate-400"
                  />
                </div>
              </div>
            )}

            {/* Description */}
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Deskripsi Produk</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Tuliskan keterangan lengkap stok produk koperasi..."
                rows={4}
                className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors resize-none"
              />
            </div>

            {/* Price and Stock */}
            <div className={`grid grid-cols-1 ${isPreorder ? '' : 'md:grid-cols-2'} gap-6`}>
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Harga Dasar (Rp)</label>
                <input
                  type="number"
                  required
                  min={0}
                  value={price}
                  onChange={(e) => setPrice(Number(e.target.value))}
                  className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors"
                />
              </div>

              {!isPreorder && (
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Stok Utama</label>
                {hasVariants ? (
                  <div className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-bold text-slate-600 flex items-center justify-between">
                    <span>{variantStockTotal} pcs</span>
                    <span className="text-[10px] font-bold text-brand-400 uppercase">Otomatis dari varian</span>
                  </div>
                ) : (
                  <input
                    type="number"
                    required
                    min={0}
                    value={stock}
                    onChange={(e) => setStock(Number(e.target.value))}
                    className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-900 focus:outline-none focus:border-brand-500 transition-colors"
                  />
                )}
              </div>
              )}
            </div>
          </div>

          {/* Product Variants Setup panel */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <div>
              <h2 className="font-extrabold text-slate-900 text-base">Varian Produk (Ukuran/Warna/Tipe)</h2>
              <p className="text-xs text-slate-400 mt-1">
                {isPreorder
                  ? 'Pre-order tidak memakai stok. Siswa memesan dulu, produk diproduksi setelahnya.'
                  : 'Tambahkan opsi varian barang (seperti ukuran seragam) dengan stok tersendiri.'}
              </p>
            </div>

            {/* Variants table lists (editable) */}
            {variants.length > 0 && (
              <div className="overflow-hidden rounded-xl border border-slate-200 bg-slate-50/20">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-slate-200 bg-slate-50/40 text-slate-500 font-bold uppercase">
                      <th className="p-3">Nama Varian</th>
                      <th className="p-3">Harga Tambahan</th>
                      {!isPreorder && <th className="p-3">Stok Varian</th>}
                      <th className="p-3 text-right w-20">Aksi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200/40 font-semibold text-slate-600">
                    {variants.map((v, index) => (
                      <tr key={v.id || index}>
                        <td className="p-2">
                          <input
                            type="text"
                            value={v.variantName}
                            onChange={(e) => handleVariantFieldChange(index, 'variantName', e.target.value)}
                            className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                          />
                        </td>
                        <td className="p-2">
                          <input
                            type="number"
                            min={0}
                            value={v.additionalPrice}
                            onChange={(e) => handleVariantFieldChange(index, 'additionalPrice', Number(e.target.value))}
                            className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-900 focus:outline-none focus:border-brand-500"
                          />
                        </td>
                        {!isPreorder && (
                        <td className="p-2">
                          <input
                            type="number"
                            min={0}
                            value={v.stock}
                            onChange={(e) => handleVariantFieldChange(index, 'stock', Number(e.target.value))}
                            className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-900 focus:outline-none focus:border-brand-500"
                          />
                        </td>
                        )}
                        <td className="p-2 text-right">
                          <div className="flex items-center justify-end gap-1">
                            {isEditMode && v.id && (
                              <button
                                type="button"
                                onClick={() => handleSaveVariant(index)}
                                title="Simpan varian"
                                className="p-1.5 rounded-lg text-slate-400 hover:text-brand-400 hover:bg-brand-500/10 transition-colors"
                              >
                                <Save className="w-4 h-4" />
                              </button>
                            )}
                            <button
                              type="button"
                              onClick={() => handleDeleteVariantLocal(v.id, index)}
                              title="Hapus varian"
                              className="p-1.5 rounded-lg text-slate-500 hover:text-rose-400 hover:bg-rose-500/5 transition-colors"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {isEditMode && (
                  <p className="px-3 py-2 text-[10px] text-slate-500 border-t border-slate-200/60 bg-slate-50/40">
                    Ubah nilai lalu klik ikon simpan pada baris untuk memperbarui varian.
                  </p>
                )}
              </div>
            )}

            {/* Add Variant Formlet */}
            <div className={`grid grid-cols-1 ${isPreorder ? 'md:grid-cols-2' : 'md:grid-cols-3'} gap-4 p-4 rounded-xl bg-slate-50 border border-slate-200`}>
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Nama Varian</label>
                <input
                  type="text"
                  placeholder="cth: S, M, L, XL"
                  value={newVarName}
                  onChange={(e) => setNewVarName(e.target.value)}
                  className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                />
              </div>
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Harga Tambahan (+)</label>
                <input
                  type="number"
                  min={0}
                  value={newVarPrice}
                  onChange={(e) => setNewVarPrice(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-900 focus:outline-none focus:border-brand-500"
                />
              </div>
              <div className={`flex items-end gap-3 ${isPreorder ? '' : ''}`}>
                {!isPreorder && (
                <div className="flex-1">
                  <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Stok Varian</label>
                  <input
                    type="number"
                    min={0}
                    value={newVarStock}
                    onChange={(e) => setNewVarStock(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-900 focus:outline-none focus:border-brand-500"
                  />
                </div>
                )}
                <button
                  type="button"
                  onClick={handleAddVariantLocal}
                  className="px-3.5 py-2 rounded-lg bg-brand-600 hover:bg-brand-500 border border-brand-600 text-white font-bold text-xs flex items-center gap-1.5 transition-all"
                >
                  <Plus className="w-4 h-4" />
                  <span>Tambah</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Right column: image upload and status */}
        <div className="space-y-6">
          {/* Image Upload Panel */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6 text-center">
            <h2 className="font-extrabold text-slate-900 text-base text-left">Foto Produk</h2>

            <div className="relative group rounded-2xl overflow-hidden border border-slate-200 bg-slate-50 aspect-square flex flex-col items-center justify-center gap-4">
              {imagePreview ? (
                <>
                  <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                    <label className="px-4 py-2 bg-white border border-slate-300 hover:bg-slate-100 text-xs font-bold text-slate-900 rounded-xl cursor-pointer">
                      Ganti Foto
                      <input type="file" accept="image/*" onChange={handleImageChange} className="hidden" />
                    </label>
                  </div>
                </>
              ) : (
                <label className="flex flex-col items-center gap-3 cursor-pointer p-8 w-full h-full justify-center">
                  <div className="p-3.5 bg-white rounded-full border border-slate-200 text-slate-500">
                    <ImageIcon className="w-6 h-6" />
                  </div>
                  <div>
                    <span className="text-xs font-bold text-brand-400">Pilih berkas foto</span>
                    <p className="text-[10px] text-slate-500 mt-1">JPEG, PNG, WEBP max 5MB</p>
                  </div>
                  <input type="file" accept="image/*" onChange={handleImageChange} className="hidden" />
                </label>
              )}
            </div>
          </div>

          {/* Visibility and Save panel */}
          <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
            <h2 className="font-extrabold text-slate-900 text-base">Visibilitas & Publikasi</h2>

            <div className="space-y-4">
              <label className="flex items-center gap-3 cursor-pointer p-3 rounded-xl bg-white border border-slate-200 select-none">
                <input
                  type="checkbox"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                  className="w-4.5 h-4.5 rounded bg-slate-50 border-slate-200 text-brand-600 focus:ring-brand-500"
                />
                <div className="flex flex-col">
                  <span className="text-sm font-extrabold text-slate-900">Aktif (Tampilkan)</span>
                  <span className="text-[10px] text-slate-500 font-bold">Produk langsung terlihat di app mobile siswa</span>
                </div>
              </label>
            </div>

            {/* Error notifications */}
            {saveMutation.isError && (
              <div className="p-3 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs font-semibold flex items-center gap-2">
                <AlertCircle className="w-4 h-4 flex-shrink-0" />
                <span>Gagal menyimpan data produk.</span>
              </div>
            )}

            {/* Save trigger button */}
            <button
              type="submit"
              disabled={saveMutation.isPending}
              className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold shadow-lg shadow-brand-500/20 active:scale-[0.98] transition-all disabled:opacity-50 text-sm"
            >
              {saveMutation.isPending ? (
                <RefreshCw className="w-5 h-5 animate-spin" />
              ) : (
                <>
                  <Save className="w-5 h-5" />
                  <span>Simpan Produk</span>
                </>
              )}
            </button>
          </div>
        </div>

      </form>
    </div>
  );
};

export default ProductFormPage;
