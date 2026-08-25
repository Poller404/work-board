var CACHE_NAME = 'work-board-v2';
var ASSETS = ['./', './index.html', './manifest.json'];

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
   nur offline greift der zuletzt zwischengespeicherte Stand. Verhindert,
   dass Nutzer:innen bei häufigen Deploys dauerhaft einen Stand hinterher-
   hängen (was die vorherige Cache-first-Strategie verursachen konnte). */
self.addEventListener('fetch', function(event){
  if(event.request.method !== 'GET') return;
  event.respondWith(
    fetch(event.request).then(function(networkResponse){
      var copy = networkResponse.clone();
      caches.open(CACHE_NAME).then(function(cache){ cache.put(event.request, copy); });
      return networkResponse;
    }).catch(function(){
      return caches.match(event.request);
    })
  );
});
