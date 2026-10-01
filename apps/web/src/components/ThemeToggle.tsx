import { useEffect, useState } from 'react';
import { setTheme } from '../lib/storage';

export function ThemeToggle() {
  const [dark, setDark] = useState(() => {
    try {
      const saved = localStorage.getItem('theme');
      return saved ? saved === 'dark' : document.documentElement.classList.contains('dark');
    } catch {
      return false;
    }
  });

  useEffect(() => setTheme(dark), [dark]);

  return (
    <button
      onClick={() => setDark((d) => !d)}
      aria-label={dark ? 'Switch to light theme' : 'Switch to dark theme'}
      title={dark ? 'Light mode' : 'Dark mode'}
      className="rounded-lg border border-slate-300 p-2 text-sm hover:bg-slate-100 dark:border-slate-700 dark:hover:bg-slate-800"
    >
      {dark ? '☀️' : '🌙'}
    </button>
  );
}
