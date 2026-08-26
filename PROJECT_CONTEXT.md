# Projekt-Kontext: Work Board (Kanban & Zeiterfassung)

> Diese Datei ist der Übergabe-Kontext für eine neue Claude-Instanz (Kontextfenster der
> vorherigen Session wurde voll). Bitte zuerst diesen Abschnitt lesen, dann den Rest als
> Hintergrundwissen.

## ✅ ROOT CAUSE GEFUNDEN UND BEHOBEN (Stand 2026-08-26, Commit `f726caa`)

Der Nutzer hat nach den vier Cache/Sync-Fixes vom 2026-08-25 einen Screenshot geschickt: der
Willkommens-Dialog erschien weiterhin bei jedem Laden, obwohl Cloud-Sync laut Dialog-Text selbst
("☁️ Cloud-Sync ist bereits eingerichtet") korrekt erkannt wurde. Ursache war ein reines
Timing-Problem in `init()` ([index.html](index.html), Funktion `init`, siehe unten): `showOnboardingIfNeeded()`
wurde synchron direkt nach dem ersten Render aufgerufen, **bevor** der asynchrone initiale
Cloud-Pull (`cloudPullNow()`, ganz am Ende von `init()`) überhaupt eine Chance hatte zu laden.
`state.tasks.length` war zu diesem Zeitpunkt also immer 0 → Dialog erschien jedes Mal, unabhängig
vom eigentlichen Cloud-Zustand.

**Fix (Commit `f726caa`):** `showOnboardingIfNeeded()` wird jetzt erst innerhalb von
`cloudPullNow().then(...)` aufgerufen, also erst nachdem der initiale Pull-Versuch abgeschlossen
ist (egal ob erfolgreich, leer oder fehlgeschlagen – `cloudPullNow()` resolved in jedem Fall, nie
reject). Ist Cloud-Sync nicht aktiv, läuft der Dialog wie bisher sofort. Im Browser gegengeprüft:
No-Cloud-Pfad (leeres Board, kein Cloud-Sync) zeigt den Dialog weiterhin korrekt, keine neuen
Konsolenfehler. Der Cloud-Pfad selbst liess sich wegen der IIFE-Kapselung des gesamten Scripts
(alles ab Zeile ~523 in einer `(function(){ ... })()`-Closure, `state`/`cloudPullNow`/etc. sind
nicht auf `window` sichtbar) nicht per Browser-Konsole voll end-to-end simulieren – die
Codeänderung ist aber eine reine Verschiebung eines Funktionsaufrufs von "vor" nach "nach" einem
`.then()`, keine neue Logik.

**Offen:** Nutzer-Bestätigung, dass der Dialog nach diesem Fix (+ übliche GitHub-Pages-CDN-Wartezeit
bis 10 Min) nicht mehr bei jedem Laden erscheint und die Tasks aus der Cloud sichtbar sind.

Zusätzlich vorher schon gepusht (2026-08-25, alle bereits live): SW Network-first (`d709afa`),
Cloud-Pull-Autoload bei leerem lokalem Board (`030e639`), Push-Sicherheitscheck gegen Überschreiben
echter Cloud-Daten (`a1828df`), HTTP-Cache-Bypass via `{cache:'no-store'}` (`e241bd3`). Falls der
Nutzer nach dem neuen Fix immer noch Probleme meldet: die Debugging-Schritte unten weiter
abarbeiten.

## 🔴 URSPRÜNGLICHES PROBLEM (Beschreibung, für Kontext)

Der Nutzer meldet: Beim Öffnen der App (auf `https://poller404.github.io/work-board/`, seinem
echten Firmengerät) erscheint **immer wieder der Willkommens-Dialog**, obwohl unter
⚙️ Einstellungen → Cloud-Sync Token/Passphrase/Gist-ID sichtbar vorhanden sind. Das Board zeigt
0 Tasks. **Nutzer betont ausdrücklich: kein tatsächlicher Datenverlust seinerseits** – die
Daten sollten in seinem privaten GitHub Gist liegen.

**Bereits behoben in dieser Session (aber Problem besteht laut Nutzer weiterhin):**
1. `sw.js` von Cache-first auf Network-first umgestellt (Commit `d709afa`) – falls der Nutzer
   trotzdem noch eine alte gecachte `index.html` sieht, könnte der Browser den neuen Service
   Worker noch nicht übernommen haben (alter SW kontrolliert die Seite weiter, bis alle Tabs
   geschlossen/neu geöffnet werden oder man ihn manuell in DevTools → Anwendung → Service
   Worker → "Abmelden" entfernt – **löscht keine Daten**, nur den Seiten-Cache).
2. `cloudPullNow()` hat den Cloud-Stand bei leerem lokalem Board nie automatisch übernommen
   (Zeitstempel-Vergleich scheiterte systematisch bei frisch initialisiertem State) – gefixt in
   Commit `030e639`, mit gemocktem Gist reproduziert und verifiziert.

**Nächste Debugging-Schritte, falls der Nutzer nach diesen beiden Fixes (+ Hard-Refresh /
Service-Worker-Neustart) immer noch das leere Board sieht:**
- Prüfen, ob der Nutzer wirklich die NEUESTE `index.html` ausgeliefert bekommt: im Browser
  DevTools → Netzwerk-Tab → `index.html` anschauen, ob sie vom Server (200) oder aus dem Cache
  kommt, und ob ihr Inhalt z.B. `btnCompactToggle` oder `btnQuickTimeEntry` enthält (Marker für
  den aktuellen Stand, per `document.getElementById(...)` in der Konsole prüfbar).
- Prüfen, ob `cloudPullNow()` beim Start überhaupt erfolgreich läuft: Browser-Konsole öffnen,
  nach Fehlern suchen, insbesondere HTTP-Fehler beim Fetch zu `api.github.com/gists/...` (z.B.
  401 = Token ungültig/falscher Scope, 404 = Gist-ID stimmt nicht, evtl. wurde versehentlich
  mit falscher ID verbunden).
- Prüfen, ob `getCloudSyncConfig().enabled` tatsächlich `true` ist (localStorage-Key
  `wb-cloud-sync-config` in DevTools → Anwendung → Lokaler Speicher anschauen) – nur ausgefüllte
  Felder in den Settings heisst nicht zwingend `enabled:true`.
- Als garantiert funktionierender Workaround (unabhängig vom automatischen Pull): ⚙️
  Einstellungen → Cloud-Sync → **"🔗 Mit bestehendem Speicher verbinden"** klicken (nicht "Jetzt
  synchronisieren", da dieser Button zuerst pusht – bei leerem lokalem Board könnte das
  theoretisch den echten Cloud-Stand überschreiben, siehe Warnung unten!). "Mit bestehendem
  Speicher verbinden" pusht nie, sondern lädt nur (`cloudJoinExisting()`), das ist der sichere Weg.

**⚠️ Wichtige Erkenntnis aus dem Testen dieser Session:** Der Button "🔄 Jetzt synchronisieren"
(sowie der Topbar-Button "☁️ Sync") führt **erst Push, dann Pull** aus. Wenn ein Gerät lokal
leer ist (z.B. genau dieser Bug-Zustand) und dieser Button geklickt wird, **überschreibt der
Push den echten Cloud-Stand mit dem leeren lokalen Stand**, bevor der Pull überhaupt zum Zug
kommt – das wurde beim Testen dieser Session unabsichtlich reproduziert (siehe Bug-Historie
unten, Punkt 9). Das ist noch **nicht gefixt** und ein reales Risiko: Falls der Nutzer bereits
mehrfach auf "Sync" oder "Jetzt synchronisieren" geklickt hat, während sein Board leer war,
könnten seine echten Cloud-Daten dadurch bereits überschrieben worden sein. **Das sollte als
Erstes geprüft/gefixt werden**, bevor man dem Nutzer weitere Klicks auf diese Buttons empfiehlt
– z.B. indem `cloudPushNow()` sich weigert zu pushen, wenn `state.tasks.length === 0`, aber der
zuletzt bekannte Cloud-Stand nicht leer war (oder generell: Push bei komplett leerem lokalem
Board nur nach expliziter Bestätigung).

## Projektübersicht

Ein selbstgebautes Kanban-/Zeiterfassungs-Tool für den Nutzer (arbeitet mit Jira-Tickets,
Hotline-Support-Anrufen, Meetings, rapportiert Zeit über Dyce). Zentrale Randbedingung: Nutzer
sitzt auf einem gesperrten **Firmen-Arbeitsgerät** (keine Admin-Rechte, kein Server, keine
Installationen möglich) – das hat die gesamte Architektur geprägt.

**Architektur:** Eine einzige self-contained `index.html` (Vanilla JS, kein Framework, keine
externen Libraries/CDN, kein Build-Schritt) plus `manifest.json` (PWA) und `sw.js` (Service
Worker). Aktuell **ca. 6000+ Zeilen** (stark gewachsen durch eine 30-Feature-Batch-Runde am
2026-08-25).

## Dateispeicherorte

- `C:\Git\kanban-time-tracker\index.html` – die App (Hauptdatei)
- `C:\Git\kanban-time-tracker\manifest.json` – PWA-Manifest
- `C:\Git\kanban-time-tracker\sw.js` – Service Worker (**Network-first seit heute**, Cache nur
  Offline-Fallback, `CACHE_NAME = 'work-board-v2'`)
- `C:\Git\kanban-time-tracker\README.md` – vollständige Nutzer-Doku, wird bei jedem Feature
  synchron gehalten
- `C:\Git\kanban-time-tracker\PROJECT_CONTEXT.md` – diese Datei
- `C:\Git\kanban-time-tracker\.git\` – lokales Git-Repo (Branch `main`), **Remote `origin`
  konfiguriert und aktiv genutzt** (siehe Deployment – das hat sich seit der letzten
  Zusammenfassung geändert!)

## Deployment

Live auf **GitHub Pages**, Repo: **https://github.com/Poller404/work-board**, URL vermutlich
`https://poller404.github.io/work-board/`. Seit 2026-08-24 hat der Nutzer lokale
Git-Zugangsdaten eingerichtet – **Claude pusht direkt per `git push origin main`**, kein
manueller Upload mehr nötig. Nutzer hat das explizit so gewünscht ("wäre super wenn du die
neuen Files automatisch pushen könntest").

**Push-Historie der heutigen Session (2026-08-25, chronologisch):**
1. Cloud-Sync-UX-Überarbeitung, QR-Geräte-Kopplung, Mobile-Redesign, Zeit-erfassen-Button
2. Timer-Unterbrechung/Fortsetzen, Dyce-Rundung, Soll-/Ist-Vergleich, Zeitverteilungs-Chart
3. Undo, Kompaktansicht, WIP-Limits, Spalten-Icons/-Farben
4. Pomodoro, Journal, Erinnerungen, Morgen-Ritual
5. Tages-Vorlagen, Jira-Bookmarklets (Status/Bulk), Wissensdatenbank, SLA-Dashboard,
   Schichtübergabe, PDF-Export, iOS-Kurzbefehle, Read-only-Teilen-Link
6. Dashboard-Widget-Ansicht (nachträglich ergänzt, war in der 30er-Liste übersehen worden)
7. Visuelle Design-Politur (Farben/Schatten/Transitions/Animationen, keine Funktionsänderung)
8. Service-Worker Network-first-Fix
9. Cloud-Pull-Autoload-Fix bei leerem lokalem Board

**Einmaliger Sonderfall beim allerersten Push:** Lokale Git-Historie und die bereits auf GitHub
liegende Historie (alte manuelle Uploads, "Add files via upload") waren komplett unrelated →
nach Prüfung, dass der lokale Stand inhaltlich alles abdeckt, mit `git push --force-with-lease`
bereinigt (Nutzer hat das nach Rückfrage explizit gewählt). Seither normale Fast-Forward-Pushes.

## Datenspeicher-Architektur (mehrschichtig)

1. **localStorage** – automatisch, laufend, pro Browser/Gerät (`kanban-state-backup`)
2. **Manueller JSON-Export/Import** (💾 Sichern / 📂 Datei laden)
3. **File System Access API** ("Direkt mit Datei verbinden") – nur über `https://`
4. **☁️ Cloud-Sync via privatem GitHub Gist** – siehe unten, aktuell Gegenstand des offenen Bugs

## ☁️ Cloud-Sync – Kernfeature, Ende-zu-Ende-verschlüsselt

- **Verschlüsselung**: AES-256-GCM via Web Crypto API, Schlüssel aus Passphrase via PBKDF2
  (100'000 Iterationen). Alles im Browser – GitHub sieht nie Klartext.
- **Speicherort**: privater ("secret") GitHub Gist via `api.github.com/gists`.
- **Token-Typ**: Classic Personal Access Token, nur Scope `gist` (Fine-grained Tokens
  unterstützen die Gist-API nicht).
- Token/Passphrase/Gist-ID liegen in separatem localStorage-Key `wb-cloud-sync-config`, NICHT
  in `state.settings`.
- **Zusätzlich seit heute**: einmal täglich automatischer datierter Snapshot im selben Gist
  (7 Tage Aufbewahrung, `cloudMaybeSnapshot()`).
- Sync-Rhythmus: Push ~8s nach Änderung (debounced), Pull beim Start + alle 45s.
- Konflikt-UI: `cloudChangeBanner` – **liegt im normalen Dokumentfluss und kann vom
  volldeckenden Willkommens-Dialog verdeckt werden** (Teil des heute gefixten Bugs).
- Zwei UI-Wege zum Verbinden: **"☁️ Neuen Speicher erstellen"** (1. Gerät) und **"🔗 Mit
  bestehendem Speicher verbinden"** (weitere Geräte, braucht Gist-ID) – bewusst als zwei
  getrennte Buttons statt einem mehrdeutigen, weil Nutzer sonst auf zwei Geräten versehentlich
  zwei getrennte Speicher anlegte.
- Geräte-Kopplung auch per **QR-Code** möglich (Kamera-Scan via `BarcodeDetector`-API oder
  Zwischenablage-Fallback) – Passphrase wird bewusst NICHT im QR übertragen, muss manuell
  eingegeben werden (Sicherheits-Layer).
- Relevante Funktionen: `getCloudSyncConfig`, `setCloudSyncConfig`, `cloudEncryptState`,
  `cloudDecryptPayload`, `cloudCreateGist`, `cloudPushNow`, `cloudPullNow`, `cloudJoinExisting`,
  `cloudMaybeSnapshot`, `renderCloudSyncStatus`, `openCloudPairQr`, `openQrScanner`,
  `promptPassphraseAndJoin`.

## Vollständige Feature-Liste (sehr umfangreich – Kurzform)

**Kanban-Kern**: Spalten (Icons/Farben/WIP-Limits), DnD, Prioritäten, Checklisten,
Abhängigkeiten, Anpinnen, Suche/Filter, Tags, Links, Archiv, Bulk-Aktionen, Kontextmenü,
**Undo (Strg+Z)**, **Kompaktansicht**, **Dashboard-Widget-Ansicht** (Board-Ansicht-Auswahl).

**Zeiterfassung**: globaler Timer, Idle-Erkennung, Pausen-Erinnerung, Zeit-Budget,
Zeit-Preis-Rechner, **"⏱️ Zeit erfassen"-Schnellstart**, **Timer-Unterbrechung mit
Fortsetzen-Vorschlag**, **Dyce-Rundung (5/15 Min.)**, **Soll-/Ist-Vergleich**,
**Pomodoro-Modus** (automatische Pausen zwischen Fokus-Blöcken).

**Hotline/Meeting**: Schnellstart, Notizen, SLA-Ampel, **SLA-/Fälligkeits-Dashboard**,
.ics-Export/Import.

**Jira/Confluence**: Bookmarklets für Import, **Jira-Status zurückschreiben (Bookmarklet)**,
**Bulk-Import von Jira-Suchliste (Bookmarklet)**, Ähnliche-Tickets-Warnung,
**Lösungs-Wissensdatenbank** (Volltextsuche über erledigte/archivierte Tasks).

**KI**: eigener Anthropic-Key, Schnellerfassung, Wochenanalyse.

**Ansichten**: Status, Priorität, Eisenhower-Matrix, Team, Timeline/Gantt, Archiv, Zeitreise,
**Dashboard**.

**Produktivität**: "Was jetzt?" (jetzt mit leichter Tageszeit-Lernheuristik), Fokus-/Pomodoro-
Modus, Command Palette (Strg+K), Tastatur-Navigation, Shortcut-Cheatsheet, Wiedervorlage,
Wiederkehrende Tasks, Task-Vorlagen, **Tages-Vorlagen** (mehrere Tasks auf einmal),
Textbausteine, Diktat, Screenshot-Einfügen, **Journal**, **freistehende Erinnerungen**,
**Morgen-Ritual**, **Rückfragen-Feld** pro Task.

**Auswertung**: Statistik-Modal (jetzt inkl. **Kreisdiagramm**), Dyce-Export, Recap,
**Schichtübergabe-Report**, **E-Mail-Antwort-Button**, Tages-/Wochenbericht als
**E-Mail-Entwurf**, **PDF-Wochenbericht** (via Browser-Druckdialog), Druckansicht.

**Spielereien**: Konfetti, XP-System, Sounds, Glücksrad, Akzentfarbe, Hintergrundbild, DE/EN.

**Mehrere Boards & Mobile**: mehrere Boards, PWA, **QR-Code-Geräte-Kopplung** (Kamera-Scan +
Zwischenablage-Fallback), **iOS-Kurzbefehle-Integration** (`?action=...`-URL-Parameter),
**Read-only-Teilen-Link** (separater unverschlüsselter Snapshot-Gist), Safe-Area-Insets für
iPhone Dynamic Island, kollabierbare Mobile-Topbar.

**Datenschutz**: 🔒 PIN-Sperre (nur Sichtschutz), ☁️ Cloud-Sync, **Backup-Rotation**
(tägliche Snapshots im Cloud-Gist).

**Design (2026-08-25, rein visuell)**: verfeinerte Farb-Tokens beide Themes, Schatten-Stufen,
konsistente Rundungs-Skala, Transitions auf allen interaktiven Elementen, Card-Hover-Lift,
Modal-/Toast-Animationen (mit `prefers-reduced-motion`-Support).

## Verwendete Test-Methodik

- `file://` blockiert File System Access API + Service Worker → lokaler `python -m http.server`
  + Claude_Browser-Tool, danach aufräumen (Server killen, Tabs schliessen).
- Cloud-Sync-Tests: `window.fetch` mit einem simplen In-Memory/localStorage-basierten
  Fake-Gist-Store gemockt (POST/PATCH/GET nachgebaut). Für Push-vor-Pull-Isolation: PATCH
  temporär zum No-Op gemacht, um zu verhindern, dass ein Test-Push echte Gist-Daten überschreibt.
- Bookmarklets: Syntax-Check via `new Function(src)` (parst ohne auszuführen), Verhalten via
  `eval` mit gemocktem `alert`/`prompt` gegen eine Nicht-Jira-Seite geprüft (Fallback-Pfade).
- QR-Encoder zusätzlich gegen echte Python-Libs (`qrcode`, `pyzbar`, `Pillow`) verifiziert.
- **Bekannte Test-Artefakte, keine echten Bugs**: Service-Worker-Registrierung scheitert in der
  Claude_Browser-Sandbox; synthetische Enter-Taste feuert manchmal nicht zuverlässig (via
  `dispatchEvent` gegenprüfen); der Editor-Hook öffnet nach jedem `Edit`-Aufruf automatisch
  einen neuen `file://`-Vorschau-Tab – vor jedem Browser-Test-Schritt `tabs_context` prüfen und
  ggf. den richtigen `http://localhost:PORT`-Tab per `tabs_select` wieder aktivieren.

## Bug-Historie (behoben, chronologisch)

1. `window.confirm()` von Firmen-IT-Policy blockiert → eigener `confirmDialog()`
2. Screenshot-Paste-Listener duplizierte sich bei Modal-Reopen → globaler Listener
3. QR-Encoder: Umlaute ohne UTF-8-ECI-Segment falsch kodiert → behoben
4. Cloud-Sync: Timestamp-Vergleich beim expliziten Verbinden eines frischen Geräts scheiterte →
   explizites Verbinden übernimmt seither immer direkt den Cloud-Stand
5. Cloud-Sync: Bestätigungs-Dialog wurde durch Race Condition sofort zerstört → Settings-Reopen
   liegt jetzt in den Dialog-Callbacks
6. Statusleiste zeigte Cloud-Sync-Status nie an → live in `renderCloudSyncStatus()` gepflegt
7. UX-Falle: mehrdeutiger "Verbinden/Neu erstellen"-Button führte zu zwei getrennten Gists bei
   zwei Geräten → zwei explizite Buttons + Warnung
8. `computeLanes()` (Status-Ansicht) reichte neue Spalten-Felder (icon/color/wipLimit) nicht
   durch → gefunden beim Testen von Feature-Batch B, gefixt
9. `enterFocusMode()` bekam einen neuen Parameter, war aber noch direkt als
   `addEventListener('click', enterFocusMode)` verdrahtet → Klick-Event landete als Parameter,
   Absturz. Gefixt durch Wrapper-Funktion. **Lektion**: bei Signaturänderungen einer Funktion,
   die als Event-Handler-Referenz verdrahtet ist, immer grep, ob sie irgendwo direkt (nicht in
   einem Wrapper) übergeben wird.
10. Service Worker Cache-first → Network-first (siehe oben, "AKTUELL OFFENES PROBLEM")
11. `cloudPullNow()` lud bei leerem lokalem Board nie automatisch den Cloud-Stand (siehe oben)

## Aktueller Status (Stand 2026-08-25, Ende der Session)

Alle 30 vom Nutzer gewünschten Features + Dashboard-Nachtrag + Design-Politur implementiert,
getestet, gepusht. **Das offene Problem ganz oben in dieser Datei ist der aktive
Arbeitsauftrag für die nächste Session** – bitte zuerst dort weitermachen, inkl. der
identifizierten, noch ungefixten Push-vor-Pull-Gefahr bei leerem lokalem Board.
