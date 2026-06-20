import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldAlert, KeyRound, Mail, ArrowRight } from 'lucide-react';
import axios from 'axios';
import { useAuthStore } from '../stores/authStore';
import { API_BASE_URL } from '../api/client';
import Logo from '../components/common/Logo';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  
  const login = useAuthStore((state) => state.login);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const response = await axios.post(`${API_BASE_URL}/auth/login`, {
        email,
        password,
      });

      const { success, data, error: apiErr } = response.data;

      if (!success) {
        throw new Error(apiErr?.message || 'Gagal masuk. Silakan periksa kembali akun Anda.');
      }

      const { user, accessToken, refreshToken } = data;

      if (user.role !== 'ADMIN') {
        throw new Error('Akses ditolak. Hanya administrator yang dapat menggunakan dashboard ini.');
      }

      // Save user session in Zustand
      login(user, accessToken, refreshToken);
      navigate('/');
    } catch (err: any) {
      setError(err.response?.data?.error?.message || err.message || 'Koneksi ke server gagal.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-6 relative overflow-hidden">
      {/* Soft brand gradients background layout */}
      <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-brand-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 translate-x-1/2 translate-y-1/2 w-96 h-96 bg-brand-300/20 rounded-full blur-3xl pointer-events-none" />

      {/* Login Card */}
      <div className="w-full max-w-md glass-panel p-8 md:p-10 rounded-3xl shadow-2xl relative z-10">
        
        {/* Brand Header */}
        <div className="flex flex-col items-center mb-8 text-center">
          <Logo className="w-28 h-28 mb-4" iconClassName="w-14 h-14" />
          <h1 className="text-2xl md:text-3xl font-extrabold text-slate-900 tracking-tight">Damos Mart Admin</h1>
          <p className="text-sm text-slate-500 mt-1.5">Koperasi Digital SMK Telkom Jakarta</p>
        </div>

        {/* Error Alert Box */}
        {error && (
          <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 flex items-start gap-3 text-sm animate-[shake_0.4s_ease-in-out]">
            <ShieldAlert className="w-5 h-5 flex-shrink-0 mt-0.5" />
            <span className="font-semibold leading-relaxed">{error}</span>
          </div>
        )}

        {/* Form Fields */}
        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Email Administrator</label>
            <div className="relative">
              <Mail className="absolute left-4 top-3.5 w-5 h-5 text-slate-400" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@damosmart.com"
                className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 placeholder-slate-400 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 transition-all"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Kata Sandi</label>
            <div className="relative">
              <KeyRound className="absolute left-4 top-3.5 w-5 h-5 text-slate-400" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-12 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-semibold text-slate-900 placeholder-slate-400 focus:outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500 transition-all"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full flex items-center justify-center gap-2.5 bg-brand-600 hover:bg-brand-500 text-white font-bold py-3.5 px-4 rounded-xl shadow-lg shadow-brand-500/20 hover:shadow-brand-500/35 active:scale-[0.98] transition-all disabled:opacity-50 disabled:pointer-events-none mt-8 group"
          >
            {loading ? (
              <span className="w-5.5 h-5.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <>
                <span>Masuk Sekarang</span>
                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default LoginPage;
