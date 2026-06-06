const TOKEN_KEY = 'dnf_public_admin_token';

function getStoredToken() {
  return localStorage.getItem(TOKEN_KEY) || '';
}

function setStoredToken(token) {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token);
  }
}

export function clearStoredToken() {
  localStorage.removeItem(TOKEN_KEY);
}

async function fetchJSON(path, options = {}) {
  const headers = new Headers(options.headers || {});
  const token = getStoredToken();
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }
  if (options.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }
  return fetch(path, { ...options, headers });
}

async function tryFetch(path, fallback, options) {
  try {
    const resp = await fetchJSON(path, options);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return await resp.json();
  } catch (_) {
    return fallback;
  }
}

export async function login(username, password) {
  const resp = await fetchJSON('/api/v1/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username, password })
  });
  const payload = await resp.json();
  if (!resp.ok) {
    throw new Error(payload.error || `HTTP ${resp.status}`);
  }
  setStoredToken(payload.token);
  return payload;
}

export async function fetchCurrentUser() {
  const token = getStoredToken();
  if (!token) {
    return { authenticated: false, user: null, reason: 'AUTH_REQUIRED' };
  }
  try {
    const resp = await fetchJSON('/api/v1/auth/me');
    if (resp.status === 401) {
      clearStoredToken();
      return { authenticated: false, user: null, reason: 'AUTH_REQUIRED' };
    }
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const data = await resp.json();
    return { authenticated: true, ...data };
  } catch (_) {
    return { authenticated: false, user: null, reason: 'AUTH_REQUIRED' };
  }
}

export async function fetchAccounts(query = '', limit = 20) {
  const params = new URLSearchParams();
  if (query) params.set('query', query);
  params.set('limit', String(limit));
  return tryFetch(`/api/v1/accounts?${params.toString()}`, { items: [], limit, offset: 0 });
}

export async function fetchCharacters(query = '', limit = 20) {
  const params = new URLSearchParams();
  if (query) params.set('query', query);
  params.set('limit', String(limit));
  return tryFetch(`/api/v1/characters?${params.toString()}`, { items: [], limit, offset: 0 });
}

export async function fetchPVFItems(query = '', category = '', page = 1, pageSize = 20) {
  const params = new URLSearchParams();
  if (query) params.set('q', query);
  if (category) params.set('category', category);
  params.set('page', String(page));
  params.set('page_size', String(pageSize));
  return tryFetch(`/api/v1/pvf/items?${params.toString()}`, { 
    items: [], 
    total: 0, 
    page: 1, 
    page_size: 20, 
    total_pages: 0 
  });
}

export async function fetchPVFCategories() {
  return tryFetch('/api/v1/pvf/categories', { categories: [] });
}

export async function fetchAccountDetail(id) {
  return tryFetch(`/api/v1/accounts/${encodeURIComponent(id)}`, {});
}

export async function fetchCharacterDetail(id) {
  return tryFetch(`/api/v1/characters/${encodeURIComponent(id)}`, {});
}

export async function fetchPVFStats() {
  return tryFetch('/api/v1/pvf/stats', {});
}

export async function planGrantItem(payload) {
  return tryFetch('/api/v1/pvf/grant-plan', { error: 'grant plan request failed' }, {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export async function sendMailAction(payload) {
  return tryFetch('/api/v1/gm/mail/send', { error: 'mail send disabled' }, {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export async function grantCurrencyAction(payload) {
  return tryFetch('/api/v1/gm/currency/grant', { error: 'currency grant disabled' }, {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export async function banAccountAction(payload) {
  return tryFetch('/api/v1/gm/account/ban', { error: 'account ban disabled' }, {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export async function loadDashboardData() {
  const [modules, audit, me, activities, calendar, nativeActivities, accounts, characters, pvf, pvfStats] = await Promise.all([
    tryFetch('/api/v1/meta/modules', { modules: [] }),
    tryFetch('/api/v1/meta/audit-actions', { actions: [] }),
    fetchCurrentUser(),
    tryFetch('/api/v1/activities', { items: [] }),
    tryFetch('/api/v1/activities/calendar', { days: [] }),
    tryFetch('/api/v1/activities/native', { items: [] }),
    fetchAccounts('', 50),
    fetchCharacters('', 50),
    fetchPVFItems('', '', 1, 20),
    fetchPVFStats()
  ]);
  return { modules, audit, me, activities, calendar, nativeActivities, accounts, characters, pvf, pvfStats };
}
