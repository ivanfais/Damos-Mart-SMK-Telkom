import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  TrendingUp,
  ShoppingCart,
  Banknote,
  Users,
  AlertTriangle,
  ArrowUpRight,
  Eye,
  RefreshCw,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import apiClient from '../api/client';

export const DashboardPage: React.FC = () => {
  // 1. Query dashboard aggregate stats
  const { data: dashboardData, isLoading: statsLoading, refetch: refetchStats } = useQuery({
    queryKey: ['adminDashboard'],
    queryFn: async () => {
      const res = await apiClient.get('/admin/dashboard');
      return res.data.data;
    },
    refetchInterval: 15000, // Auto-refresh every 15 seconds
  });

  // 2. Query sales report for the trend chart
  const { data: reportsData, isLoading: reportsLoading } = useQuery({
    queryKey: ['adminDashboardChart'],
    queryFn: async () => {
      const res = await apiClient.get('/admin/reports/sales?period=daily');
      return res.data.data;
    },
  });

  const isLoading = statsLoading || reportsLoading;

  // Format currency helpers
  const formatIDR = (value: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(value);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
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

  const stats = [
    {
      title: 'Pesanan Hari Ini',
      value: dashboardData?.todayOrders ?? 0,
      icon: ShoppingCart,
      color: 'from-blue-600 to-indigo-600',
      shadow: 'shadow-blue-500/10',
    },
    {
      title: 'Revenue Hari Ini',
      value: formatIDR(dashboardData?.todayRevenue ?? 0),
      icon: Banknote,
      color: 'from-emerald-600 to-teal-600',
      shadow: 'shadow-emerald-500/10',
    },
    {
      title: 'Antrean Aktif',
      value: dashboardData?.activeQueues ?? 0,
      icon: Users,
      color: 'from-brand-600 to-rose-600',
      shadow: 'shadow-brand-500/10',
    },
    {
      title: 'Stok Kritis (<10)',
      value: dashboardData?.lowStockProducts ?? 0,
      icon: AlertTriangle,
      color: 'from-amber-600 to-orange-600',
      shadow: 'shadow-amber-500/10',
      alert: (dashboardData?.lowStockProducts ?? 0) > 0,
    },
  ];

  // Map database dates to chart readable format or use placeholder if empty
  const chartData = reportsData?.salesChart?.map((item: any) => ({
    date: new Date(item.dateStr).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' }),
    Pendapatan: item.revenue,
    Volume: item.volume,
  })) || [
    { date: 'Mon', Pendapatan: 120000, Volume: 5 },
    { date: 'Tue', Pendapatan: 185000, Volume: 8 },
    { date: 'Wed', Pendapatan: 240000, Volume: 12 },
    { date: 'Thu', Pendapatan: 195000, Volume: 9 },
    { date: 'Fri', Pendapatan: 310000, Volume: 15 },
    { date: 'Sat', Pendapatan: 150000, Volume: 6 },
    { date: 'Sun', Pendapatan: 0, Volume: 0 },
  ];

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
        <RefreshCw className="w-10 h-10 text-brand-500 animate-spin" />
        <p className="text-slate-400 font-semibold text-sm">Memuat data dashboard...</p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Welcome & Refresh Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-900 leading-tight">Selamat Datang di Damos Mart Panel</h1>
          <p className="text-slate-400 text-sm mt-1">Pantau pesanan, antrean real-time, dan penjualan harian.</p>
        </div>
        <button
          onClick={() => refetchStats()}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-slate-100 text-slate-600 hover:text-slate-900 border border-slate-200 transition-colors text-xs font-bold font-sans"
        >
          <RefreshCw className="w-4 h-4" />
          <span>Muat Ulang Data</span>
        </button>
      </div>

      {/* Stats Cards Section */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.title}
              className={`glass-panel p-6 rounded-2xl flex items-center justify-between shadow-lg ${stat.shadow} relative overflow-hidden group hover:-translate-y-1 transition-transform duration-300`}
            >
              {/* Decorative gradient overlay */}
              <div className="absolute inset-0 bg-gradient-to-r from-transparent to-slate-950/20 opacity-0 group-hover:opacity-100 transition-opacity" />

              <div className="relative z-10 space-y-2.5">
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">{stat.title}</span>
                <p className="text-2xl font-black text-slate-900">{stat.value}</p>
              </div>

              <div className={`relative z-10 p-3.5 bg-gradient-to-tr ${stat.color} rounded-xl text-white shadow-lg shadow-black/25 flex items-center justify-center`}>
                <Icon className={`w-6 h-6 ${stat.alert ? 'animate-bounce' : ''}`} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Chart & Live Status Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Sales Chart Panel */}
        <div className="glass-panel p-6 rounded-2xl lg:col-span-2 shadow-xl flex flex-col justify-between">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2.5">
              <TrendingUp className="w-5 h-5 text-brand-400" />
              <h3 className="font-extrabold text-slate-900 text-base">Tren Penjualan Harian (7 Hari Terakhir)</h3>
            </div>
            <span className="text-xs font-bold px-3 py-1 bg-brand-500/10 text-brand-400 rounded-full border border-brand-500/20">Omset</span>
          </div>

          <div className="h-80 w-full min-h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#f43f5e" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                <XAxis dataKey="date" stroke="#94a3b8" fontSize={11} tickLine={false} />
                <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '12px' }}
                  labelStyle={{ color: '#fff', fontWeight: 'bold' }}
                />
                <Area type="monotone" dataKey="Pendapatan" stroke="#f43f5e" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Real-time Queue Quick Status */}
        <div className="glass-panel p-6 rounded-2xl shadow-xl flex flex-col justify-between">
          <div>
            <h3 className="font-extrabold text-slate-900 text-base mb-2">Informasi Cepat Antrean</h3>
            <p className="text-xs text-slate-400">Status antrean berjalan di koperasi hari ini.</p>
          </div>

          <div className="my-6 p-6 rounded-2xl bg-slate-50/50 border border-slate-200 text-center flex flex-col items-center justify-center gap-3">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Sedang Dilayani</span>
            <div className="text-5xl font-black text-brand-400 tracking-tight select-none">
              {dashboardData?.activeQueues > 0 ? (
                `A-${String(dashboardData?.todayOrders - dashboardData?.activeQueues + 1).padStart(3, '0')}`
              ) : (
                'N/A'
              )}
            </div>
            <div className="flex items-center gap-2 text-xs font-bold text-slate-400">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-ping" />
              <span>Broadcast Socket Aktif</span>
            </div>
          </div>

          <Link
            to="/queues"
            className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-xs font-bold bg-brand-600 hover:bg-brand-500 text-white shadow-md shadow-brand-500/10 hover:shadow-brand-500/20 active:scale-[0.98] transition-all"
          >
            <span>Buka Board Antrean</span>
            <ArrowUpRight className="w-4 h-4" />
          </Link>
        </div>
      </div>

      {/* Recent Orders Section */}
      <div className="glass-panel p-6 rounded-2xl shadow-xl space-y-6">
        <div className="flex items-center justify-between">
          <h3 className="font-extrabold text-slate-900 text-base">Pesanan Terbaru</h3>
          <Link
            to="/orders"
            className="text-xs font-bold text-brand-400 hover:text-brand-300 flex items-center gap-1 transition-colors"
          >
            <span>Semua Pesanan</span>
            <ArrowUpRight className="w-4.5 h-4.5" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 text-xs font-bold text-slate-400 uppercase tracking-wider">
                <th className="py-4 px-4">Nomor Order</th>
                <th className="py-4 px-4">Nama Siswa</th>
                <th className="py-4 px-4">Metode Bayar</th>
                <th className="py-4 px-4">Total Harga</th>
                <th className="py-4 px-4">Status</th>
                <th className="py-4 px-4 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200/40 text-sm font-semibold text-slate-600">
              {dashboardData?.recentOrders?.map((order: any) => (
                <tr key={order.id} className="hover:bg-white/30 transition-colors">
                  <td className="py-4 px-4 font-mono text-slate-700">{order.orderNumber}</td>
                  <td className="py-4 px-4 text-slate-900">{order.user.fullName}</td>
                  <td className="py-4 px-4 text-xs">
                    <span className="px-2.5 py-1 bg-slate-100 border border-slate-300 text-slate-400 rounded-lg">
                      {order.paymentMethod === 'CASH_AT_COUNTER' ? 'KASIR' : 'QRIS'}
                    </span>
                  </td>
                  <td className="py-4 px-4 font-bold text-slate-900">{formatIDR(Number(order.total))}</td>
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
              {(!dashboardData?.recentOrders || dashboardData.recentOrders.length === 0) && (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-500 font-semibold">
                    Belum ada data pesanan saat ini.
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

export default DashboardPage;
