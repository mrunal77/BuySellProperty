import { StrictMode, ReactNode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth, LISTER_TYPES } from './lib/auth';
import { initTheme } from './lib/storage';
import { Navbar } from './components/Navbar';
import { Footer } from './components/Footer';
import { LandingPage } from './routes/Landing';
import { SearchPage } from './routes/Search';
import { DetailPage } from './routes/Detail';
import { LoginPage } from './routes/Login';
import { RegisterPage } from './routes/Register';
import { DashboardPage } from './routes/Dashboard';
import { AdminPage } from './routes/Admin';
import './index.css';

initTheme();

const qc = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 30_000 } },
});

function RequireAuth({ children }: { children: ReactNode }) {
  const { session } = useAuth();
  const loc = useLocation();
  if (!session) return <Navigate to="/login" replace state={{ from: loc.pathname }} />;
  return <>{children}</>;
}

function RequireLister({ children }: { children: ReactNode }) {
  const { session } = useAuth();
  if (!session) return <Navigate to="/login" replace />;
  const ok = LISTER_TYPES.includes(session.userType) || session.roles.some((r) => LISTER_TYPES.includes(r));
  if (!ok) return <Navigate to="/" replace />;
  return <>{children}</>;
}

function RequireAdmin({ children }: { children: ReactNode }) {
  const { session } = useAuth();
  if (!session) return <Navigate to="/login" replace />;
  if (!session.roles.includes('Admin') && session.userType !== 'Admin') return <Navigate to="/" replace />;
  return <>{children}</>;
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <BrowserRouter>
          <div className="flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1">
              <Routes>
                <Route path="/" element={<LandingPage />} />
                <Route path="/search" element={<SearchPage />} />
                <Route path="/p/:id" element={<DetailPage />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/register" element={<RegisterPage />} />
                <Route path="/dashboard" element={<RequireLister><DashboardPage /></RequireLister>} />
                <Route path="/admin/*" element={<RequireAuth><RequireAdmin><AdminPage /></RequireAdmin></RequireAuth>} />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </main>
            <Footer />
          </div>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
);
