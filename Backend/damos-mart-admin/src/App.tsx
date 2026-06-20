import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Components & Layouts
import AdminLayout from './components/layout/AdminLayout';

// Pages
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ProductsPage from './pages/ProductsPage';
import ProductFormPage from './pages/ProductFormPage';
import CategoriesPage from './pages/CategoriesPage';
import OrdersPage from './pages/OrdersPage';
import OrderDetailPage from './pages/OrderDetailPage';
import QueueManagementPage from './pages/QueueManagementPage';
import ChatPage from './pages/ChatPage';
import UsersPage from './pages/UsersPage';
import CooperativeInfoPage from './pages/CooperativeInfoPage';
import ComplaintsPage from './pages/ComplaintsPage';
import ReportsPage from './pages/ReportsPage';

// Initialize React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false, // Prevent redundant requests
      retry: 1,
    },
  },
});

export const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          {/* Guest authentication route */}
          <Route path="/login" element={<LoginPage />} />

          {/* Secure Admin Dashboard workspace */}
          <Route path="/" element={<AdminLayout />}>
            <Route index element={<DashboardPage />} />
            
            {/* Products catalog pages */}
            <Route path="products" element={<ProductsPage />} />
            <Route path="products/new" element={<ProductFormPage />} />
            <Route path="products/:id/edit" element={<ProductFormPage />} />
            
            {/* Category portal */}
            <Route path="categories" element={<CategoriesPage />} />
            
            {/* Orders logs */}
            <Route path="orders" element={<OrdersPage />} />
            <Route path="orders/:id" element={<OrderDetailPage />} />
            
            {/* Realtime boards */}
            <Route path="queues" element={<QueueManagementPage />} />
            <Route path="chat" element={<ChatPage />} />
            
            {/* Customers metadata */}
            <Route path="users" element={<UsersPage />} />
            
            {/* Cooperative profile */}
            <Route path="cooperative" element={<CooperativeInfoPage />} />

            {/* Complaints management */}
            <Route path="complaints" element={<ComplaintsPage />} />
            
            {/* Financial charts reports */}
            <Route path="reports" element={<ReportsPage />} />
          </Route>

          {/* Fallback redirect */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
};

export default App;
