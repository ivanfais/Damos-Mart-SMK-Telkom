import React, { useEffect, useMemo, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Info,
  Clock,
  Save,
  RefreshCw,
  Store,
  Image as ImageIcon,
  BarChart3,
} from 'lucide-react';
import apiClient, { API_BASE_URL } from '../api/client';

const CHART_HOURS = [8, 9, 10, 11, 12, 13, 14, 15, 16];
const CHART_DAYS = [
  { dayOfWeek: 1, label: 'Senin' },
  { dayOfWeek: 2, label: 'Selasa' },
  { dayOfWeek: 3, label: 'Rabu' },
  { dayOfWeek: 4, label: 'Kamis' },
  { dayOfWeek: 5, label: 'Jumat' },
  { dayOfWeek: 6, label: 'Sabtu' },
];

type CrowdCell = {
  id?: string;
  dayOfWeek: number;
  hourSlot: number;
  avgCrowdLevel: number;
};

const crowdKey = (dayOfWeek: number, hourSlot: number) => `${dayOfWeek}-${hourSlot}`;

const buildCrowdGrid = (existing: any[]): CrowdCell[] => {
  const cells: CrowdCell[] = [];
  for (const day of CHART_DAYS) {
    for (const hour of CHART_HOURS) {
      const match = existing.find(
        (item) => item.dayOfWeek === day.dayOfWeek && item.hourSlot === hour
      );
      cells.push({
        id: match?.id,
        dayOfWeek: day.dayOfWeek,
        hourSlot: hour,
        avgCrowdLevel: match?.avgCrowdLevel ?? 2,
      });
    }
  }
  return cells;
};

const resolveImageUrl = (path?: string | null) => {
  if (!path) return null;
  if (path.startsWith('http')) return path;
  return `${API_BASE_URL.replace('/api/v1', '')}${path}`;
};

const CONDITION_OPTIONS = [
  { value: 'SEPI', label: 'Sepi', hint: 'Kondisi sepi / sedikit pengunjung', activeClass: 'border-emerald-500 bg-emerald-50 text-emerald-700' },
  { value: 'NORMAL', label: 'Normal', hint: 'Kondisi normal / cukup ramai', activeClass: 'border-brand-500 bg-brand-50 text-brand-700' },
  { value: 'RAMAI', label: 'Ramai', hint: 'Kondisi ramai / padat', activeClass: 'border-rose-500 bg-rose-50 text-rose-700' },
] as const;

type CooperativeConditionValue = (typeof CONDITION_OPTIONS)[number]['value'];

export const CooperativeInfoPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<'info' | 'hours' | 'crowd'>('info');

  const [hoursList, setHoursList] = useState<any[]>([]);

  const [aboutId, setAboutId] = useState('');
  const [aboutContent, setAboutContent] = useState('');
  const [aboutImageUrl, setAboutImageUrl] = useState<string | null>(null);
  const [aboutImageFile, setAboutImageFile] = useState<File | null>(null);
  const [aboutImagePreview, setAboutImagePreview] = useState<string | null>(null);

  const [locationId, setLocationId] = useState('');
  const [locationContent, setLocationContent] = useState('');
  const [locationImageUrl, setLocationImageUrl] = useState<string | null>(null);
  const [locationImageFile, setLocationImageFile] = useState<File | null>(null);
  const [locationImagePreview, setLocationImagePreview] = useState<string | null>(null);

  const [crowdGrid, setCrowdGrid] = useState<CrowdCell[]>([]);

  const { data: infoList = [], isLoading: infoLoading } = useQuery<any[]>({
    queryKey: ['adminCooperativeInfo'],
    queryFn: async () => {
      const res = await apiClient.get('/cooperative/info');
      return res.data.data;
    },
  });

  const { data: dbHours = [], isLoading: hoursLoading } = useQuery<any[]>({
    queryKey: ['adminCooperativeHours'],
    queryFn: async () => {
      const res = await apiClient.get('/cooperative/hours');
      return res.data.data;
    },
  });

  const { data: dbCrowd = [], isLoading: crowdLoading } = useQuery<any[]>({
    queryKey: ['adminCooperativeCrowd'],
    queryFn: async () => {
      const res = await apiClient.get('/cooperative/crowd');
      return res.data.data;
    },
  });

  const { data: currentStatus, isLoading: statusLoading } = useQuery<{ condition: CooperativeConditionValue }>({
    queryKey: ['adminCooperativeStatus'],
    queryFn: async () => {
      const res = await apiClient.get('/cooperative/status');
      return res.data.data;
    },
  });

  const [selectedCondition, setSelectedCondition] = useState<CooperativeConditionValue>('NORMAL');

  useEffect(() => {
    if (currentStatus?.condition) {
      setSelectedCondition(currentStatus.condition);
    }
  }, [currentStatus?.condition]);

  useEffect(() => {
    if (infoList.length > 0) {
      const about = infoList.find((item) => item.infoType === 'about');
      if (about) {
        setAboutId(about.id);
        setAboutContent(about.content);
        setAboutImageUrl(about.imageUrl ?? null);
      }

      const location = infoList.find((item) => item.infoType === 'location');
      if (location) {
        setLocationId(location.id);
        setLocationContent(location.content);
        setLocationImageUrl(location.imageUrl ?? null);
      }
    }
  }, [infoList]);

  useEffect(() => {
    if (dbHours.length > 0) {
      setHoursList(dbHours);
    }
  }, [dbHours]);

  useEffect(() => {
    if (dbCrowd.length >= 0) {
      setCrowdGrid(buildCrowdGrid(dbCrowd));
    }
  }, [dbCrowd]);

  const crowdMap = useMemo(() => {
    const map = new Map<string, CrowdCell>();
    crowdGrid.forEach((cell) => map.set(crowdKey(cell.dayOfWeek, cell.hourSlot), cell));
    return map;
  }, [crowdGrid]);

  const saveInfoRecord = async (
    id: string | undefined,
    payload: { title: string; content: string; infoType: string; imageFile: File | null }
  ) => {
    const formData = new FormData();
    formData.append('title', payload.title);
    formData.append('content', payload.content);
    formData.append('infoType', payload.infoType);
    if (payload.imageFile) {
      formData.append('image', payload.imageFile);
    }

    if (id) {
      await apiClient.put(`/admin/cooperative/info/${id}`, formData, {
        headers: { 'Content-Type': undefined },
      });
      return id;
    }

    const res = await apiClient.post('/admin/cooperative/info', formData, {
      headers: { 'Content-Type': undefined },
    });
    return res.data.data.id as string;
  };

  const saveInfoMutation = useMutation({
    mutationFn: async () => {
      const newAboutId = await saveInfoRecord(aboutId || undefined, {
        title: 'Tentang Damos Mart',
        content: aboutContent,
        infoType: 'about',
        imageFile: aboutImageFile,
      });

      const newLocationId = await saveInfoRecord(locationId || undefined, {
        title: 'Lokasi Koperasi',
        content: locationContent,
        infoType: 'location',
        imageFile: locationImageFile,
      });

      return { newAboutId, newLocationId };
    },
    onSuccess: ({ newAboutId, newLocationId }) => {
      setAboutId(newAboutId);
      setLocationId(newLocationId);
      setAboutImageFile(null);
      setLocationImageFile(null);
      setAboutImagePreview(null);
      setLocationImagePreview(null);
      queryClient.invalidateQueries({ queryKey: ['adminCooperativeInfo'] });
      alert('Informasi koperasi berhasil disimpan.');
    },
  });

  const saveHoursMutation = useMutation({
    mutationFn: async () => {
      await apiClient.put('/admin/cooperative/hours', {
        hours: hoursList.map((hour) => ({
          id: hour.id,
          dayOfWeek: hour.dayOfWeek,
          openTime: hour.isClosed ? null : hour.openTime,
          closeTime: hour.isClosed ? null : hour.closeTime,
          isClosed: hour.isClosed,
        })),
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminCooperativeHours'] });
      alert('Jam operasional koperasi berhasil disimpan.');
    },
  });

  const saveCrowdMutation = useMutation({
    mutationFn: async () => {
      await apiClient.put('/admin/cooperative/crowd', {
        slots: crowdGrid.map((cell) => ({
          dayOfWeek: cell.dayOfWeek,
          hourSlot: cell.hourSlot,
          avgCrowdLevel: cell.avgCrowdLevel,
        })),
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminCooperativeCrowd'] });
      alert('Data kepadatan koperasi berhasil disimpan.');
    },
  });

  const saveStatusMutation = useMutation({
    mutationFn: async (condition: CooperativeConditionValue) => {
      await apiClient.put('/admin/cooperative/status', { condition });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adminCooperativeStatus'] });
      alert('Kondisi koperasi saat ini berhasil diperbarui.');
    },
  });

  const handleImagePick = (
    file: File | undefined,
    setFile: React.Dispatch<React.SetStateAction<File | null>>,
    setPreview: React.Dispatch<React.SetStateAction<string | null>>
  ) => {
    if (!file) return;
    setFile(file);
    setPreview(URL.createObjectURL(file));
  };

  const handleCrowdChange = (dayOfWeek: number, hourSlot: number, value: number) => {
    setCrowdGrid((prev) =>
      prev.map((cell) =>
        cell.dayOfWeek === dayOfWeek && cell.hourSlot === hourSlot
          ? { ...cell, avgCrowdLevel: value }
          : cell
      )
    );
  };

  const handleHourToggle = (index: number) => {
    setHoursList((prev) =>
      prev.map((item, idx) =>
        idx === index ? { ...item, isClosed: !item.isClosed } : item
      )
    );
  };

  const handleTimeChange = (index: number, field: 'openTime' | 'closeTime', val: string) => {
    setHoursList((prev) =>
      prev.map((item, idx) =>
        idx === index ? { ...item, [field]: val } : item
      )
    );
  };

  const getDayName = (day: number) => {
    const names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return names[day - 1] || 'Hari';
  };

  const renderImageUpload = ({
    label,
    preview,
    currentUrl,
    onChange,
  }: {
    label: string;
    preview: string | null;
    currentUrl: string | null;
    onChange: (file?: File) => void;
  }) => {
    const displayUrl = preview || resolveImageUrl(currentUrl);

    return (
      <div className="space-y-2">
        <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">{label}</label>
        <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50/60 p-4">
          <div className="flex flex-col md:flex-row gap-4 items-start md:items-center">
            <div className="w-full md:w-40 h-28 rounded-xl overflow-hidden bg-white border border-slate-200 flex items-center justify-center">
              {displayUrl ? (
                <img src={displayUrl} alt={label} className="w-full h-full object-cover" />
              ) : (
                <ImageIcon className="w-8 h-8 text-slate-300" />
              )}
            </div>
            <div className="flex-1 space-y-2">
              <p className="text-xs text-slate-500 leading-relaxed">
                Unggah gambar yang akan ditampilkan di aplikasi siswa pada halaman Informasi Koperasi.
              </p>
              <label className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white border border-slate-200 text-xs font-bold text-slate-700 cursor-pointer hover:border-brand-500 transition-colors">
                <ImageIcon className="w-4 h-4" />
                Pilih Gambar
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => onChange(e.target.files?.[0])}
                />
              </label>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const isLoading = infoLoading || hoursLoading || crowdLoading || statusLoading;

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Memuat profil koperasi...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black text-slate-900 leading-tight">Pengaturan Info & Jam Koperasi</h1>
        <p className="text-sm text-slate-400 mt-1">
          Konfigurasi tentang koperasi, gambar lokasi, jam operasional, dan kepadatan harian.
        </p>
      </div>

      <div className="glass-panel p-6 rounded-2xl shadow-xl max-w-5xl space-y-4">
        <div>
          <h2 className="font-extrabold text-slate-900 text-base">Kondisi Koperasi Saat Ini</h2>
          <p className="text-xs text-slate-500 mt-1 leading-relaxed">
            Atur kondisi real-time koperasi yang akan ditampilkan ke siswa di aplikasi (Sepi, Normal, atau Ramai).
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {CONDITION_OPTIONS.map((option) => {
            const isActive = selectedCondition === option.value;
            return (
              <button
                key={option.value}
                type="button"
                onClick={() => setSelectedCondition(option.value)}
                className={`rounded-xl border-2 px-4 py-4 text-left transition-all ${
                  isActive
                    ? option.activeClass
                    : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'
                }`}
              >
                <p className="font-extrabold text-sm">{option.label}</p>
                <p className="text-[11px] mt-1 opacity-80">{option.hint}</p>
              </button>
            );
          })}
        </div>

        <button
          type="button"
          disabled={saveStatusMutation.isPending}
          onClick={() => saveStatusMutation.mutate(selectedCondition)}
          className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-md shadow-brand-500/10 disabled:opacity-50 transition-all active:scale-[0.98]"
        >
          {saveStatusMutation.isPending ? (
            <RefreshCw className="w-4 h-4 animate-spin" />
          ) : (
            <>
              <Save className="w-4 h-4" />
              <span>Simpan Kondisi Saat Ini</span>
            </>
          )}
        </button>
      </div>

      <div className="flex border-b border-slate-200 overflow-x-auto">
        <button
          onClick={() => setActiveTab('info')}
          className={`flex items-center gap-2.5 px-6 py-3.5 text-xs font-bold transition-all border-b-2 whitespace-nowrap ${
            activeTab === 'info'
              ? 'border-brand-500 text-slate-900'
              : 'border-transparent text-slate-500 hover:text-slate-600'
          }`}
        >
          <Info className="w-4.5 h-4.5" />
          <span>Informasi Profil Koperasi</span>
        </button>
        <button
          onClick={() => setActiveTab('hours')}
          className={`flex items-center gap-2.5 px-6 py-3.5 text-xs font-bold transition-all border-b-2 whitespace-nowrap ${
            activeTab === 'hours'
              ? 'border-brand-500 text-slate-900'
              : 'border-transparent text-slate-500 hover:text-slate-600'
          }`}
        >
          <Clock className="w-4.5 h-4.5" />
          <span>Jam Operasional Hari Kerja</span>
        </button>
        <button
          onClick={() => setActiveTab('crowd')}
          className={`flex items-center gap-2.5 px-6 py-3.5 text-xs font-bold transition-all border-b-2 whitespace-nowrap ${
            activeTab === 'crowd'
              ? 'border-brand-500 text-slate-900'
              : 'border-transparent text-slate-500 hover:text-slate-600'
          }`}
        >
          <BarChart3 className="w-4.5 h-4.5" />
          <span>Kepadatan Koperasi</span>
        </button>
      </div>

      {activeTab === 'info' ? (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            saveInfoMutation.mutate();
          }}
          className="glass-panel p-6 rounded-2xl shadow-xl space-y-6 max-w-3xl"
        >
          <div className="flex items-center gap-2 mb-2">
            <Store className="w-5 h-5 text-brand-400" />
            <h3 className="font-extrabold text-slate-900 text-base">Tentang Koperasi & Lokasi</h3>
          </div>

          <div className="space-y-2">
            <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">Tentang Damos Mart</label>
            <textarea
              required
              rows={4}
              value={aboutContent}
              onChange={(e) => setAboutContent(e.target.value)}
              placeholder="Deskripsi profil koperasi..."
              className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 focus:outline-none focus:border-brand-500 resize-none leading-relaxed"
            />
          </div>

          {renderImageUpload({
            label: 'Gambar Koperasi',
            preview: aboutImagePreview,
            currentUrl: aboutImageUrl,
            onChange: (file) => handleImagePick(file, setAboutImageFile, setAboutImagePreview),
          })}

          <div className="space-y-2">
            <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">Lokasi / Alamat Kasir</label>
            <textarea
              required
              rows={3}
              value={locationContent}
              onChange={(e) => setLocationContent(e.target.value)}
              placeholder="Alamat penyerahan barang / kasir..."
              className="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 focus:outline-none focus:border-brand-500 resize-none leading-relaxed"
            />
          </div>

          {renderImageUpload({
            label: 'Gambar Peta / Lokasi',
            preview: locationImagePreview,
            currentUrl: locationImageUrl,
            onChange: (file) => handleImagePick(file, setLocationImageFile, setLocationImagePreview),
          })}

          <button
            type="submit"
            disabled={saveInfoMutation.isPending}
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-md shadow-brand-500/10 disabled:opacity-50 transition-all active:scale-[0.98]"
          >
            {saveInfoMutation.isPending ? (
              <RefreshCw className="w-4 h-4 animate-spin" />
            ) : (
              <>
                <Save className="w-4 h-4" />
                <span>Simpan Informasi</span>
              </>
            )}
          </button>
        </form>
      ) : activeTab === 'hours' ? (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            saveHoursMutation.mutate();
          }}
          className="glass-panel p-6 rounded-2xl shadow-xl space-y-6 max-w-3xl"
        >
          <div className="flex items-center gap-2 mb-2">
            <Clock className="w-5 h-5 text-brand-400" />
            <h3 className="font-extrabold text-slate-900 text-base">Atur Jam Buka Koperasi</h3>
          </div>

          <div className="space-y-4">
            {hoursList.map((hour, index) => (
              <div
                key={hour.id || index}
                className="grid grid-cols-1 md:grid-cols-4 gap-4 items-center p-3 rounded-xl bg-slate-50/40 border border-slate-200"
              >
                <span className="font-extrabold text-slate-900 text-sm">{getDayName(hour.dayOfWeek)}</span>
                <div>
                  <label className="block text-[9px] font-bold text-slate-500 uppercase mb-1">Jam Buka</label>
                  <input
                    type="text"
                    disabled={hour.isClosed}
                    value={hour.openTime || ''}
                    onChange={(e) => handleTimeChange(index, 'openTime', e.target.value)}
                    placeholder="07:00"
                    className="w-full px-3 py-1.5 bg-white border border-slate-200 disabled:opacity-30 rounded-lg text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                  />
                </div>
                <div>
                  <label className="block text-[9px] font-bold text-slate-500 uppercase mb-1">Jam Tutup</label>
                  <input
                    type="text"
                    disabled={hour.isClosed}
                    value={hour.closeTime || ''}
                    onChange={(e) => handleTimeChange(index, 'closeTime', e.target.value)}
                    placeholder="16:00"
                    className="w-full px-3 py-1.5 bg-white border border-slate-200 disabled:opacity-30 rounded-lg text-xs font-semibold text-slate-900 focus:outline-none focus:border-brand-500"
                  />
                </div>
                <div className="flex justify-end pr-2">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={hour.isClosed}
                      onChange={() => handleHourToggle(index)}
                      className="w-4.5 h-4.5 rounded bg-white border-slate-200 text-brand-600 focus:ring-brand-500"
                    />
                    <span className="text-xs font-bold text-slate-400">Tutup Harian</span>
                  </label>
                </div>
              </div>
            ))}
          </div>

          <button
            type="submit"
            disabled={saveHoursMutation.isPending}
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-md shadow-brand-500/10 disabled:opacity-50 transition-all active:scale-[0.98]"
          >
            {saveHoursMutation.isPending ? (
              <RefreshCw className="w-4 h-4 animate-spin" />
            ) : (
              <>
                <Save className="w-4 h-4" />
                <span>Simpan Jam Operasional</span>
              </>
            )}
          </button>
        </form>
      ) : (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            saveCrowdMutation.mutate();
          }}
          className="glass-panel p-6 rounded-2xl shadow-xl space-y-6 max-w-5xl"
        >
          <div className="flex items-center gap-2 mb-2">
            <BarChart3 className="w-5 h-5 text-brand-400" />
            <h3 className="font-extrabold text-slate-900 text-base">Atur Rata-Rata Kepadatan</h3>
          </div>

          <p className="text-xs text-slate-500 leading-relaxed">
            Atur tingkat kepadatan koperasi per jam (08.00 - 16.00) untuk setiap hari. Data ini akan
            ditampilkan sebagai diagram batang di aplikasi siswa sesuai hari aktif.
          </p>

          <div className="overflow-x-auto rounded-xl border border-slate-200">
            <table className="min-w-full text-xs">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-3 py-3 text-left font-bold text-slate-500 uppercase">Hari</th>
                  {CHART_HOURS.map((hour) => (
                    <th key={hour} className="px-2 py-3 text-center font-bold text-slate-500">
                      {String(hour).padStart(2, '0')}.00
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {CHART_DAYS.map((day) => (
                  <tr key={day.dayOfWeek} className="border-t border-slate-100">
                    <td className="px-3 py-3 font-bold text-slate-800 whitespace-nowrap">{day.label}</td>
                    {CHART_HOURS.map((hour) => {
                      const cell = crowdMap.get(crowdKey(day.dayOfWeek, hour));
                      const level = cell?.avgCrowdLevel ?? 2;
                      return (
                        <td key={hour} className="px-2 py-2 text-center">
                          <select
                            value={level}
                            onChange={(e) =>
                              handleCrowdChange(day.dayOfWeek, hour, Number(e.target.value))
                            }
                            className="w-16 px-1 py-1.5 rounded-lg border border-slate-200 bg-white text-slate-800 font-semibold focus:outline-none focus:border-brand-500"
                          >
                            {[1, 2, 3, 4, 5].map((value) => (
                              <option key={value} value={value}>
                                {value}
                              </option>
                            ))}
                          </select>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex flex-wrap gap-3 text-[11px] text-slate-500">
            <span className="px-2 py-1 rounded bg-slate-100">1 = Sangat Sepi</span>
            <span className="px-2 py-1 rounded bg-slate-100">2 = Sepi</span>
            <span className="px-2 py-1 rounded bg-slate-100">3 = Sedang</span>
            <span className="px-2 py-1 rounded bg-slate-100">4 = Ramai</span>
            <span className="px-2 py-1 rounded bg-slate-100">5 = Sangat Ramai</span>
          </div>

          <button
            type="submit"
            disabled={saveCrowdMutation.isPending}
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-md shadow-brand-500/10 disabled:opacity-50 transition-all active:scale-[0.98]"
          >
            {saveCrowdMutation.isPending ? (
              <RefreshCw className="w-4 h-4 animate-spin" />
            ) : (
              <>
                <Save className="w-4 h-4" />
                <span>Simpan Kepadatan</span>
              </>
            )}
          </button>
        </form>
      )}
    </div>
  );
};

export default CooperativeInfoPage;
