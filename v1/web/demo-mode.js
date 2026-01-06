/* Source demo-mode helper (placed under v1/web so Flutter picks it up during build)
 * See v1/build/web/demo-mode.js for the built output (this file will be copied by `flutter build web`).
 */
// Re-export the same helper as the built copy
// (If you modify this, rebuild the web assets with `flutter build web`)

/* KEEP IN SYNC with v1/build/web/demo-mode.js */
(function () {
  const DEMO_PATH = '/__demo_api/_db';
  const HOST_CANDIDATES = [
    () => `${location.protocol}//${location.host}${DEMO_PATH}`,
    () => `http://127.0.0.1:8000${DEMO_PATH}`,
    () => `http://localhost:8000${DEMO_PATH}`,
    () => `${location.protocol}//${location.hostname}:8000${DEMO_PATH}`
  ];

  async function tryFetch(url) {
    try {
      const res = await fetch(url, { cache: 'no-store' });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (err) {
      console.debug('demo-mode: fetch failed for', url, err.message);
      return null;
    }
  }

  async function fetchDemoDb() {
    for (const candidate of HOST_CANDIDATES) {
      const url = candidate();
      const data = await tryFetch(url);
      if (data && (Array.isArray(data.employees) && data.employees.length > 0 || (Array.isArray(data.routes) && data.routes.length > 0))) {
        window.__demo_db = data;
        console.info('demo-mode: found demo DB at', url);
        return data;
      }
    }
    console.warn('demo-mode: no demo DB found from candidate hosts');
    return null;
  }

  async function clearDemoCache() {
    try {
      const keys = ['initial_db', 'demo_db', 'v1.demo.initial_db'];
      keys.forEach(k => localStorage.removeItem(k));
      if ('caches' in window) {
        const cacheNames = await caches.keys();
        await Promise.all(cacheNames.map(n => caches.delete(n)));
      }
      location.href = '/__demo_api/clear_demo_cache';
    } catch (err) {
      console.error('demo-mode: clearDemoCache failed', err);
    }
  }

  window.demoMode = window.demoMode || {};
  window.demoMode.fetchDemoDb = fetchDemoDb;
  window.demoMode.clearDemoCache = clearDemoCache;

  fetchDemoDb().then(data => {
    if (data) {
      console.debug('demo-mode: diagnostic', { employees: (data.employees || []).length, routes: (data.routes || []).length });
    }
  });
})();
