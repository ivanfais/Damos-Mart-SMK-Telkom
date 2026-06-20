import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  ShoppingBag,
  FolderKanban,
  ShoppingCart,
  ListOrdered,
  MessageSquare,
  Users,
  Info,
  BarChart3,
  MessageSquareWarning,
  LogOut,
} from 'lucide-react';
import useAuthStore from '../../stores/authStore';
import useSocketStore from '../../stores/socketStore';
import Logo from '../common/Logo';

interface SidebarProps {
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen, setIsOpen }) => {
  const { user, logout } = useAuthStore();
  const { disconnectSockets } = useSocketStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    disconnectSockets();
    logout();
    navigate('/login');
  };

  const navItems = [
    { name: 'Dashboard', path: '/', icon: LayoutDashboard },
    { name: 'Produk', path: '/products', icon: ShoppingBag },
    { name: 'Kategori', path: '/categories', icon: FolderKanban },
    { name: 'Pesanan', path: '/orders', icon: ShoppingCart },
    { name: 'Antrean', path: '/queues', icon: ListOrdered, badge: true },
    { name: 'Chat Siswa', path: '/chat', icon: MessageSquare },
    { name: 'Daftar User', path: '/users', icon: Users },
    { name: 'Komplain', path: '/complaints', icon: MessageSquareWarning },
    { name: 'Info Koperasi', path: '/cooperative', icon: Info },
    { name: 'Laporan Penjualan', path: '/reports', icon: BarChart3 },
  ];

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 md:hidden backdrop-blur-sm transition-opacity duration-300"
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-72 transform bg-white border-r border-slate-200 flex flex-col justify-between transition-transform duration-300 ease-in-out md:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div>
          {/* Logo Brand Header */}
          <div className="h-20 flex items-center gap-3 px-6 border-b border-slate-200">
            <Logo className="w-14 h-14" iconClassName="w-8 h-8" />
            <div>
              <h1 className="font-bold text-lg leading-tight tracking-tight text-slate-900">Damos Mart</h1>
              <span className="text-xs text-slate-500">SMK Telkom Jakarta</span>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="p-4 space-y-1 flex-1 overflow-y-auto max-h-[calc(100vh-18rem)]">
            {navItems.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                onClick={() => setIsOpen(false)}
                className={({ isActive }) =>
                  `flex items-center gap-3.5 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 group ${
                    isActive
                      ? 'bg-brand-600 text-white shadow-lg shadow-brand-600/20'
                      : 'text-slate-500 hover:text-slate-900 hover:bg-slate-100'
                  }`
                }
              >
                {({ isActive }) => {
                  const Icon = item.icon;
                  return (
                    <>
                      <Icon
                        className={`w-5 h-5 transition-transform duration-200 group-hover:scale-110 ${
                          isActive ? 'text-slate-900' : 'text-slate-400 group-hover:text-brand-600'
                        }`}
                      />
                      <span className="flex-1">{item.name}</span>
                      {item.badge && (
                        <span className="flex h-2.5 w-2.5 relative">
                          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-brand-400 opacity-75"></span>
                          <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-brand-500"></span>
                        </span>
                      )}
                    </>
                  );
                }}
              </NavLink>
            ))}
          </nav>
        </div>

        {/* Footer Admin Info Panel */}
        <div className="p-4 border-t border-slate-200 bg-slate-50">
          <div className="flex items-center gap-3.5 mb-4 p-2 rounded-xl bg-white border border-slate-200">
            <div className="w-10 h-10 rounded-lg bg-gradient-to-tr from-brand-600 to-brand-400 flex items-center justify-center font-bold text-slate-900 shadow-md shadow-brand-500/10">
              {user?.fullName?.charAt(0) || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-slate-900 truncate">{user?.fullName || 'Administrator'}</p>
              <p className="text-xs text-slate-500 truncate">{user?.email || 'admin@damosmart.com'}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded-xl text-sm font-semibold bg-white hover:bg-rose-50 text-slate-500 hover:text-rose-600 border border-slate-200 hover:border-rose-200 transition-all duration-200"
          >
            <LogOut className="w-4 h-4" />
            <span>Keluar</span>
          </button>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;
