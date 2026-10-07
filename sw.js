var CACHE_NAME = 'work-board-v3';
var ASSETS = ['./', './index.html', './manifest.json'];

/* Nur Dateien der App selbst sowie die fest versionierten Bibliotheken und Schriften
   (CDN, Google Fonts) werden zwischengespeichert. API-Antworten (Supabase, GitHub,
   Anthropic, ntfy) werden bewusst NIE gecacht, damit keine Nutzerdaten im Cache liegen. */
var CACHEABLE_HOSTS = ['cdn.jsdelivr.net', 'fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', function(event){
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache){ return cache.addAll(ASSETS); })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(event){
  event.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.filter(function(k){ return k !== CACHE_NAME; }).map(function(k){ return caches.delete(k); }));
    })
  );
  self.clients.claim();
});

/* Network-first statt Cache-first: liefert bei aktiver Internetverbindung
   immer den aktuell deployten Stand und aktualisiert den Cache nebenbei;
   nur offline greift der zuletzt zwischengespeicherte Stand. */
self.addEventListener('fetch', function(event){
  if(event.request.method !== 'GET') return;
  var url;
  try{ url = new URL(event.request.url); }catch(e){ return; }
  var sameOrigin = url.origin === self.location.origin;
  if(!sameOrigin && CACHEABLE_HOSTS.indexOf(url.hostname) < 0) return;
  /* cache:'no-store' umgeht den normalen HTTP-Cache des Browsers (GitHub Pages sendet max-age=600). */
  event.respondWith(
    fetch(event.request, {cache:'no-store'}).then(function(networkResponse){
      if(networkResponse && networkResponse.ok){
        var copy = networkResponse.clone();
        caches.open(CACHE_NAME).then(function(cache){ cache.put(event.request, copy); });
      }
      return networkResponse;
    }).catch(function(){
      return caches.match(event.request);
    })
  );
});
