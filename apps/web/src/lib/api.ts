import axios from 'axios';
import { tokenStore } from './storage';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? 'http://localhost:5000',
});

api.interceptors.request.use((cfg) => {
  const t = tokenStore.read('access');
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

api.interceptors.response.use(
  (r) => r,
  async (err) => {
    const orig = err.config;
    if (err.response?.status === 401 && orig && !orig._retry) {
      orig._retry = true;
      const rt = tokenStore.read('refresh');
      if (rt) {
        try {
          const { data } = await axios.post(
            `${api.defaults.baseURL}/api/v1/auth/refresh`,
            { refreshToken: rt },
          );
          tokenStore.write(
            { access: data.accessToken, refresh: data.refreshToken },
            tokenStore.remembered(),
          );
          orig.headers.Authorization = `Bearer ${data.accessToken}`;
          return api(orig);
        } catch {
          tokenStore.clear();
          if (window.location.pathname !== '/login') window.location.assign('/login');
        }
      }
    }
    return Promise.reject(err);
  },
);
