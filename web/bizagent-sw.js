// BizAgent PWA Service Worker - Extended Offline Support
// This file provides additional caching strategies beyond Flutter's default service worker

const CACHE_NAME = 'bizagent-offline-v1';
const RUNTIME_CACHE = 'bizagent-runtime-v1';

// Static assets to cache immediately
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
];

// API patterns to cache with different strategies
const CACHE_STRATEGIES = {
  // Network First - for dynamic data that should be fresh
  networkFirst: [
    '/api/',
    'firestore.googleapis.com',
    'firebase.googleapis.com',
  ],
  // Cache First - for static assets
  cacheFirst: [
    '/assets/',
    'fonts.googleapis.com',
    'fonts.gstatic.com',
  ],
  // Stale While Revalidate - for semi-dynamic content
  staleWhileRevalidate: [
    '/export/',
    '/reports/',
  ],
};

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing BizAgent offline support...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating new service worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== RUNTIME_CACHE)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - apply caching strategies
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Skip non-GET requests
  if (event.request.method !== 'GET') return;

  // Skip chrome-extension and other non-http requests
  if (!url.protocol.startsWith('http')) return;

  // Determine caching strategy
  const strategy = getCachingStrategy(url);

  if (strategy === 'networkFirst') {
    event.respondWith(networkFirst(event.request));
  } else if (strategy === 'cacheFirst') {
    event.respondWith(cacheFirst(event.request));
  } else if (strategy === 'staleWhileRevalidate') {
    event.respondWith(staleWhileRevalidate(event.request));
  }
  // Default: let Flutter's service worker handle it
});

// Determine which caching strategy to use
function getCachingStrategy(url) {
  const urlString = url.href;

  for (const pattern of CACHE_STRATEGIES.networkFirst) {
    if (urlString.includes(pattern)) return 'networkFirst';
  }
  for (const pattern of CACHE_STRATEGIES.cacheFirst) {
    if (urlString.includes(pattern)) return 'cacheFirst';
  }
  for (const pattern of CACHE_STRATEGIES.staleWhileRevalidate) {
    if (urlString.includes(pattern)) return 'staleWhileRevalidate';
  }
  return null;
}

// Network First strategy - try network, fall back to cache
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    if (cached) {
      console.log('[SW] Serving from cache (offline):', request.url);
      return cached;
    }
    return new Response('Offline - dáta nie sú dostupné', {
      status: 503,
      statusText: 'Service Unavailable',
      headers: { 'Content-Type': 'text/plain; charset=utf-8' }
    });
  }
}

// Cache First strategy - try cache, fall back to network
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    return new Response('Asset not available offline', {
      status: 503,
      statusText: 'Service Unavailable',
    });
  }
}

// Stale While Revalidate - return cache immediately, update in background
async function staleWhileRevalidate(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(request);

  // Start fetching in background
  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  }).catch(() => null);

  // Return cached version if available, otherwise wait for fetch
  if (cached) {
    console.log('[SW] Serving stale content, revalidating:', request.url);
    return cached;
  }

  const response = await fetchPromise;
  if (response) return response;

  return new Response('Content not available', {
    status: 503,
    statusText: 'Service Unavailable',
  });
}

// Handle offline indicator
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  if (event.data && event.data.type === 'GET_CACHE_STATUS') {
    caches.keys().then((names) => {
      event.ports[0].postMessage({
        type: 'CACHE_STATUS',
        caches: names,
      });
    });
  }
});

console.log('[SW] BizAgent PWA Service Worker loaded');
