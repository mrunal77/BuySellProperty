// Token + profile storage. "Remember me" => localStorage (persistent),
// otherwise sessionStorage (cleared when the tab closes).

const KEYS = ['access', 'refresh', 'email', 'userType', 'roles'] as const;

function activeStore(): Storage {
  // If any persistent copy exists, it wins; else session.
  try {
    if (localStorage.getItem('access')) return localStorage;
  } catch { /* storage unavailable */ }
  return sessionStorage;
}

export const tokenStore = {
  read(key: string): string | null {
    try {
      return localStorage.getItem(key) ?? sessionStorage.getItem(key);
    } catch {
      return null;
    }
  },
  write(data: Record<string, string>, remember: boolean) {
    const primary = remember ? localStorage : sessionStorage;
    const other = remember ? sessionStorage : localStorage;
    try {
      for (const k of KEYS) {
        const v = data[k];
        if (v !== undefined) primary.setItem(k, v);
        other.removeItem(k);
      }
      primary.setItem('remember', remember ? '1' : '0');
      other.removeItem('remember');
    } catch { /* ignore quota errors */ }
  },
  clear() {
    try {
      for (const k of [...KEYS, 'remember']) {
        localStorage.removeItem(k);
        sessionStorage.removeItem(k);
      }
    } catch { /* ignore */ }
  },
  remembered(): boolean {
    try {
      return (localStorage.getItem('remember') ?? sessionStorage.getItem('remember')) === '1';
    } catch {
      return true;
    }
  },
};

export function initTheme() {
  try {
    const saved = localStorage.getItem('theme');
    const dark = saved ? saved === 'dark' : window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.classList.toggle('dark', dark);
    return dark;
  } catch {
    return false;
  }
}

export function setTheme(dark: boolean) {
  document.documentElement.classList.toggle('dark', dark);
  try {
    localStorage.setItem('theme', dark ? 'dark' : 'light');
  } catch { /* ignore */ }
}
