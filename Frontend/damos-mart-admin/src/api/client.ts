import axios from 'axios';
import { API_BASE_URL } from '../config/env';

export { API_BASE_URL } from '../config/env';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor to dynamically inject access token from local storage
apiClient.interceptors.request.use(
  (config) => {
    const authStoreString = localStorage.getItem('damos_mart_auth');
    if (authStoreString) {
      try {
        const state = JSON.parse(authStoreString);
        const token = state.state?.accessToken;
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
      } catch (err) {
        console.error('Failed to parse auth token', err);
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor to catch global errors and handle token expiration (401)
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    // In case of Unauthorized 401 (token expired/invalid), auto log out and redirect
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      localStorage.removeItem('damos_mart_auth');
      
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    
    return Promise.reject(error);
  }
);

export default apiClient;
