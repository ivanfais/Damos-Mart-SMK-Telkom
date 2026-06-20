import React, { useEffect, useState } from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';
import useAuthStore from '../../stores/authStore';
import useSocketStore from '../../stores/socketStore';

export const AdminLayout: React.FC = () => {
  const { user, accessToken } = useAuthStore();
  const { connectSockets, disconnectSockets } = useSocketStore();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  // Protect Admin dashboard routes: redirect if not logged in or role is not ADMIN
  if (!accessToken || !user || user.role !== 'ADMIN') {
    return <Navigate to="/login" replace />;
  }

  // Handle live WebSocket connections
  useEffect(() => {
    connectSockets();
    return () => {
      disconnectSockets();
    };
  }, [connectSockets, disconnectSockets]);

  // Determine page title based on path
  const getPageTitle = () => {
    const path = location.pathname;
    if (path === '/') return 'Dashboard Ringkasan';
    if (path.startsWith('/products')) return 'Manajemen Produk';
    if (path.startsWith('/categories')) return 'Manajemen Kategori';
    if (path.startsWith('/orders')) return 'Daftar Pesanan Koperasi';
    if (path.startsWith('/queues')) return 'Antrean Real-time';
    if (path.startsWith('/chat')) return 'Chat Bantuan Siswa';
    if (path.startsWith('/users')) return 'Manajemen Akun Siswa';
    if (path.startsWith('/cooperative')) return 'Profil & Jam Operasional';
    if (path.startsWith('/reports')) return 'Laporan Finansial & Produk';
    return 'Damos Mart Admin';
  };

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar Navigation */}
      <Sidebar isOpen={sidebarOpen} setIsOpen={setSidebarOpen} />

      {/* Main Panel Content Area */}
      <div className="flex-1 flex flex-col md:pl-72 min-w-0">
        <Header sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} title={getPageTitle()} />
        
        <main className="p-6 md:p-8 flex-1 overflow-x-hidden">
          {/* Transition wrapper */}
          <div className="max-w-7xl mx-auto animate-[fadeIn_0.3s_ease-out]">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
