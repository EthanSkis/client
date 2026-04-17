import { supabase, LOGIN_URL } from './supabase.js';

const REDIRECT_KEY = 'portal_redirect';

export async function requireSession() {
  const { data, error } = await supabase.auth.getSession();
  if (error || !data || !data.session) {
    try {
      const here = location.pathname + location.search;
      if (here && here !== '/' && here !== '/index.html') {
        localStorage.setItem(REDIRECT_KEY, here);
      }
    } catch (_) {}
    location.replace(LOGIN_URL);
    return null;
  }
  return data.session;
}

export function consumeStoredRedirect() {
  try {
    const stored = localStorage.getItem(REDIRECT_KEY);
    if (!stored) return null;
    localStorage.removeItem(REDIRECT_KEY);
    // Only allow same-origin relative paths
    if (!stored.startsWith('/')) return null;
    const here = location.pathname + location.search;
    if (stored === here) return null;
    return stored;
  } catch (_) {
    return null;
  }
}

export async function signOut() {
  try { await supabase.auth.signOut(); } catch (_) {}
  try { localStorage.removeItem(REDIRECT_KEY); } catch (_) {}
  location.replace(LOGIN_URL);
}

export function displayName(user) {
  if (!user) return '';
  const m = user.user_metadata || {};
  return m.full_name || m.name || (user.email ? user.email.split('@')[0] : '') || '';
}

export function orgName(user) {
  if (!user) return 'Your Workspace';
  const m = user.user_metadata || {};
  if (m.org_name || m.organization) return m.org_name || m.organization;
  const name = displayName(user);
  if (name) return name;
  if (user.email) {
    const domain = user.email.split('@')[1];
    if (domain) {
      const first = domain.split('.')[0] || '';
      return first ? first.charAt(0).toUpperCase() + first.slice(1) : 'Your Workspace';
    }
  }
  return 'Your Workspace';
}

export function initials(user) {
  const name = orgName(user);
  const parts = String(name).split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return (name.slice(0, 2) || '?').toUpperCase();
}
