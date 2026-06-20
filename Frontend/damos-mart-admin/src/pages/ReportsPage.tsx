import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { BarChart3, TrendingUp, Calendar, ShoppingBag, PiggyBank, RefreshCw, Layers } from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';
import apiClient from '../api/client';

const COLORS = ['#f43f5e', '#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899'];

export const ReportsPage: React.FC = () => {
  const [period, setPeriod] = useState<'daily' | 'weekly' | 'monthly'>('daily');

  // Fetch report data
  const { data: report, isLoading, refetch } = useQuery({
    queryKey: ['adminSalesReport', period],
    queryFn: async () => {
      const res = await apiClient.get(`/admin/reports/sales?period=${period}`);
      return res.data.data;
    },
  });

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
        <p className="text-slate-400 font-semibold text-sm">Menghitung laporan finansial...</p>
      </div>
    );
  }

  const summary = report?.summary || { totalRevenue: 0, totalOrders: 0, averageSalesPerDay: 0 };
  const salesChart = report?.salesChart || [];
  const topProducts = report?.topProducts || [];
  const salesByCategory = report?.salesByCategory || [];

  // Parse chart data for Recharts
  const chartData = salesChart.map((item: any) => ({
    name: period === 'daily'
      ? new Date(item.dateStr).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' })
      : item.dateStr,
    Pendapatan: item.revenue,
    Volume: item.volume,
  }));

  // Parse category data for PieChart
  const pieData = salesByCategory.map((item: any) => ({
    name: item.categoryName,
    value: Number(item.revenue),
  }));

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Analisis Finansial & Laporan</h1>
          <p className="text-sm text-slate-400 mt-1">
            Lihat data omset penjualan harian/bulanan, perbandingan kategori terpopuler, dan produk terlaris.
          </p>
        </div>

        {/* Period Selector tabs */}
        <div className="flex p-1 bg-white border border-slate-200 rounded-xl max-w-fit">
          {(['daily', 'weekly', 'monthly'] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`px-4 py-2 rounded-lg text-xs font-bold uppercase transition-all ${
                period === p
                  ? 'bg-brand-600 text-white shadow-md shadow-brand-500/10'
                  : 'text-slate-400 hover:text-slate-700'
              }`}
            >
              {p === 'daily' ? 'Harian' : p === 'weekly' ? 'Mingguan' : 'Bulanan'}
            </button>
          ))}
        </div>
      </div>

      {/* Stats Widgets */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        {/* Total revenue */}
        <div className="glass-panel p-6 rounded-2xl flex items-center justify-between shadow-lg relative overflow-hidden group">
          <div className="space-y-2 relative z-10">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Total Omset Penjualan</span>
            <p className="text-2xl font-black text-emerald-400">{formatIDR(summary.totalRevenue)}</p>
          </div>
          <div className="p-3.5 bg-emerald-500/10 rounded-xl text-emerald-400 shadow-inner flex items-center justify-center relative z-10">
            <PiggyBank className="w-6 h-6" />
          </div>
        </div>

        {/* Total orders */}
        <div className="glass-panel p-6 rounded-2xl flex items-center justify-between shadow-lg relative overflow-hidden group">
          <div className="space-y-2 relative z-10">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Total Transaksi Lunas</span>
            <p className="text-2xl font-black text-slate-900">{summary.totalOrders} Pesanan</p>
          </div>
          <div className="p-3.5 bg-blue-500/10 rounded-xl text-blue-400 shadow-inner flex items-center justify-center relative z-10">
            <ShoppingBag className="w-6 h-6" />
          </div>
        </div>

        {/* Average Sales */}
        <div className="glass-panel p-6 rounded-2xl flex items-center justify-between shadow-lg relative overflow-hidden group">
          <div className="space-y-2 relative z-10">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Rata-rata Harian</span>
            <p className="text-2xl font-black text-brand-400">{formatIDR(summary.averageSalesPerDay)}</p>
          </div>
          <div className="p-3.5 bg-brand-500/10 rounded-xl text-brand-400 shadow-inner flex items-center justify-center relative z-10">
            <TrendingUp className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Charts section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Trend Area chart */}
        <div className="glass-panel p-6 rounded-2xl lg:col-span-2 shadow-xl flex flex-col justify-between">
          <div className="flex items-center gap-2 mb-6">
            <TrendingUp className="w-5 h-5 text-brand-400" />
            <h3 className="font-extrabold text-slate-900 text-base">Grafik Nilai Penjualan</h3>
          </div>

          <div className="h-80 w-full min-h-[300px]">
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorReportRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.2}/>
                      <stop offset="95%" stopColor="#f43f5e" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                  <XAxis dataKey="name" stroke="#94a3b8" fontSize={11} tickLine={false} />
                  <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '12px' }}
                    labelStyle={{ color: '#fff', fontWeight: 'bold' }}
                  />
                  <Area type="monotone" dataKey="Pendapatan" stroke="#f43f5e" strokeWidth={3} fillOpacity={1} fill="url(#colorReportRev)" />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-slate-500 font-semibold text-xs">Belum ada transaksi.</div>
            )}
          </div>
        </div>

        {/* Category Pie chart */}
        <div className="glass-panel p-6 rounded-2xl shadow-xl flex flex-col justify-between">
          <div className="flex items-center gap-2 mb-6">
            <Layers className="w-5 h-5 text-brand-400" />
            <h3 className="font-extrabold text-slate-900 text-base">Penjualan per Kategori</h3>
          </div>

          <div className="h-80 w-full flex items-center justify-center relative">
            {pieData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="40%"
                    innerRadius={60}
                    outerRadius={90}
                    paddingAngle={3}
                    dataKey="value"
                  >
                    {pieData.map((entry: any, index: number) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '12px' }}
                    itemStyle={{ color: '#fff' }}
                  />
                  <Legend verticalAlign="bottom" align="center" iconType="circle" />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-slate-500 font-semibold text-xs">Belum ada data.</div>
            )}
          </div>
        </div>
      </div>

      {/* Top 10 Best Sellers */}
      <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
        <div className="flex items-center gap-2">
          <BarChart3 className="w-5 h-5 text-brand-400" />
          <h3 className="font-extrabold text-slate-900 text-base">Produk Terlaris Koperasi (Top 10)</h3>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 text-xs font-bold text-slate-400 uppercase tracking-wider">
                <th className="py-4 px-4">Nama Produk</th>
                <th className="py-4 px-4">Kategori</th>
                <th className="py-4 px-4">Jumlah Terjual</th>
                <th className="py-4 px-4 text-right">Total Pendapatan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200/40 text-sm font-semibold text-slate-600">
              {topProducts.map((prod: any, idx: number) => (
                <tr key={prod.id} className="hover:bg-white/30 transition-colors">
                  <td className="py-4 px-4 flex items-center gap-3">
                    <span className="font-bold text-slate-500 font-mono">#{idx + 1}</span>
                    <span className="font-extrabold text-slate-900">{prod.name}</span>
                  </td>
                  <td className="py-4 px-4 text-slate-400">{prod.categoryName}</td>
                  <td className="py-4 px-4 font-mono font-bold text-slate-700">{prod.quantitySold} pcs</td>
                  <td className="py-4 px-4 font-bold text-emerald-400 text-right">{formatIDR(Number(prod.totalRevenue))}</td>
                </tr>
              ))}
              {topProducts.length === 0 && (
                <tr>
                  <td colSpan={4} className="py-12 text-center text-slate-500 font-semibold">
                    Tidak ada transaksi tercatat dalam periode ini.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default ReportsPage;
