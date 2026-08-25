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
  /* cache:'no-store' umgeht zusätzlich den normalen HTTP-Cache des Browsers
     (der sonst trotz Network-first-Strategie hier die Antwort gemäss
     GitHub Pages' eigenem Cache-Control: max-age=600 wiederverwenden
     würde). GitHub Pages' CDN selbst cached serverseitig bis zu 10 Minuten
     pro Datei - das kann diese App nicht umgehen, das betrifft aber nur
     den CDN-Edge, nicht mehr den Browser dieses Geräts. */
  event.respondWith(
    fetch(event.request, {cache:'no-store'}).then(function(networkResponse){
      var copy = networkResponse.clone();
      caches.open(CACHE_NAME).then(function(cache){ cache.put(event.request, copy); });
      return networkResponse;
    }).catch(function(){
      return caches.match(event.request);
    })
  );
});
