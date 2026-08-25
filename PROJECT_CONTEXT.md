# Projekt-Kontext: Work Board (Kanban & Zeiterfassung)

## Projektübersicht

Ein selbstgebautes Kanban-/Zeiterfassungs-Tool für den Nutzer (arbeitet mit Jira-Tickets,
Hotline-Support-Anrufen, Meetings, rapportiert Zeit über Dyce). Zentrale Randbedingung: Nutzer
sitzt auf einem gesperrten **Firmen-Arbeitsgerät** (keine Admin-Rechte, kein Server, keine
Installationen möglich) – das hat die gesamte Architektur geprägt.

**Architektur:** Eine einzige self-contained `index.html` (Vanilla JS, kein Framework, keine
externen Libraries/CDN, kein Build-Schritt) plus `manifest.json` (PWA) und `sw.js` (Service
Worker). Aktuell ca. 4700+ Zeilen.

## Dateispeicherorte

- `C:\Git\kanban-time-tracker\index.html` – die App (Hauptdatei)
- `C:\Git\kanban-time-tracker\manifest.json` – PWA-Manifest
- `C:\Git\kanban-time-tracker\sw.js` – Service Worker (Cache-first, nur wirksam über `https://`)
- `C:\Git\kanban-time-tracker\README.md` – vollständige Nutzer-Doku, wird bei jedem Feature
  synchron gehalten
- `C:\Git\kanban-time-tracker\.git\` – lokales Git-Repo (Branch `main`), **kein Remote
  konfiguriert**. Der Nutzer lädt Änderungen manuell über die GitHub-Weboberfläche hoch
  (Drag & Drop, "uploading an existing file"), nutzt keinen `git push`-Workflow.

## Deployment

Live auf **GitHub Pages** (Nutzer hat einen GitHub-Account, öffentliches Repo). Nutzername wurde
nie mitgeteilt (bewusst offen gelassen). Nach jeder Code-Änderung muss der Nutzer die
`index.html` erneut manuell auf GitHub hochladen (`manifest.json`/`sw.js` unverändert seit dem
ersten Upload). Deployment dauert ca. 1 Minute; Nutzer prüft via "Deployments" auf der Repo-Seite
oder Strg+F5 + Einstellungen-Check auf das Vorhandensein neuer Features.

## Datenspeicher-Architektur (mehrschichtig)

1. **localStorage** – automatisch, laufend, pro Browser/Gerät (immer aktiv)
2. **Manueller JSON-Export/Import** (💾 Sichern / 📂 Datei laden) – Backup & Cross-Device-Fallback
3. **File System Access API** ("Direkt mit Datei verbinden") – war auf `file://` inaktiv, funktioniert
   jetzt über `https://` (GitHub Pages) für live-synchronisierte lokale Dateien (z.B. in
   OneDrive-Ordner)
4. **☁️ Cloud-Sync via privatem GitHub Gist** – neuestes, empfohlenes Feature, siehe unten

## ☁️ Cloud-Sync – Kernfeature, Ende-zu-Ende-verschlüsselt

Automatischer Hintergrund-Sync zwischen Geräten ohne manuellen Export/Import, mit
**Datenschutz als explizitem Anforderungsgrund** des Nutzers.

- **Verschlüsselung**: AES-256-GCM via Web Crypto API, Schlüssel aus Passphrase via PBKDF2
  (100'000 Iterationen) abgeleitet. Alles läuft im Browser – GitHub sieht nie Klartext.
- **Speicherort**: privater ("secret") GitHub Gist, angesprochen über die GitHub REST API
  (`api.github.com/gists`).
- **Token-Typ**: **Classic Personal Access Token** mit nur der Berechtigung `gist` – **Fine-grained
  Tokens unterstützen die Gist-API (Stand 2026) nicht**, das ist eine bekannte GitHub-Lücke.
- **Wichtig für Datenmodell**: Token/Passphrase/Gist-ID liegen bewusst in einem **separaten**
  localStorage-Key (`wb-cloud-sync-config`), NICHT in `state.settings` – damit sie nie in
  Sichern-Exports, Druckansicht oder der Gist-Nutzlast selbst landen.
- **Sync-Rhythmus**: Push ca. 8s nach Änderung (debounced), Pull beim Start + alle 45s.
- **Konflikt-UI**: `cloudChangeBanner` zeigt "Neuere Daten in der Cloud gefunden" statt stillem
  Überschreiben.
- **Zwei während des Testens gefundene und behobene Bugs**:
  1. Beim expliziten Verbinden mit einer bestehenden Gist-ID auf einem frischen/leeren Gerät
     verglich die App nur Zeitstempel – ein frisch initialisiertes leeres Board hat aber immer
     einen aktuelleren Zeitstempel als echte (ältere) Cloud-Daten, wodurch die App fälschlich
     "bereits aktuell" meldete und nie synchronisierte. Fix: explizites Verbinden mit
     Gist-ID übernimmt immer direkt den Cloud-Stand (kein Zeitstempel-Vergleich mehr).
  2. Der Bestätigungs-Dialog ("lokale Daten durch Cloud-Stand ersetzen?") wurde durch eine
     Race Condition sofort wieder zerstört (Settings-Reopen im äusseren Promise-Chain lief vor
     dem Dialog-Klick). Fix: Settings-Reopen liegt jetzt in den Dialog-Callbacks selbst.
- Relevante Funktionen im Code: `getCloudSyncConfig`, `setCloudSyncConfig`, `cloudEncryptState`,
  `cloudDecryptPayload`, `cloudCreateGist`, `cloudPushNow`, `cloudPullNow`, `cloudJoinExisting`,
  `renderCloudSyncStatus`.

## Vollständige Feature-Liste (chronologisch über mehrere "Alles umsetzen"-Runden gebaut)

**Kanban-Kern**: Spalten (frei benennbar/verschiebbar), Drag & Drop, Prioritäten, eigene
Task-Typen (dynamisches `TYPES`-Registry, gemerged mit `state.settings.customTypes`),
Checklisten/Subtasks, Task-Abhängigkeiten (`blockedBy`), Anpinnen, Suche/Filter, Tags, Links
(Jira/Confluence/Sonstige), Archiv (auto + manuell), Mehrfachauswahl + Bulk-Aktionen,
Rechtsklick-Kontextmenü.

**Zeiterfassung**: Ein aktiver Timer global, Live-Anzeige im Tab-Titel, Idle-Erkennung,
Übernacht-Timer-Wächter, kumulative Pausen-Erinnerung, Zeit-Budget pro Task mit
Fortschrittsbalken, Zeit-Preis-Rechner (Stundensatz → CHF-Wert in Statistik).

**Hotline/Meeting**: Schnellstart-Buttons (Task+Timer automatisch), zeitgestempelte Notizen,
"für Jira-Kommentar kopieren", SLA-Ampel (Alter-basiert, nur Hotline), Meeting-Titel-Gedächtnis,
.ics-Export (einzelnes Meeting) und .ics-Import (Outlook-Export → Meeting-Tasks).

**Jira/Confluence (keine echte API, da Arbeitsgerät)**: Bookmarklets (in Lesezeichenleiste
ziehen) scrapen Ticket-/Seiten-Daten → Zwischenablage → Import im Tool; Ähnliche-Tickets-Warnung
(Wort-Overlap-Heuristik).

**KI (eigener Anthropic-API-Key des Nutzers, lokal gespeichert)**: Schnellerfassung
(Text → strukturierter Task, Heuristik-Fallback ohne Key), KI-Wochenanalyse.

**Ansichten**: Status (klassisch), Prioritäts-Swimlanes, Eisenhower-Matrix (Anpinnen × Priorität
als 2×2), Team-Swimlanes (Zuweisung), Timeline/Gantt (30 Tage), Archiv, Zeitreise (tägliche
Snapshots, read-only).

**Produktivität**: "Was jetzt?"-Vorschlag, Fokus-Modus (Pomodoro), Command Palette (Strg+K),
Tastatur-Navigation (Pfeiltasten/Shift+Pfeil), Shortcut-Cheatsheet (`?`), Wiedervorlage/Snooze,
Wiederkehrende Tasks, Task-Vorlagen, Textbausteine, Sprach-Diktat (Web Speech API),
Screenshot-Einfügen (Strg+V → Notiz), automatische Zwischenablage-Erkennung, Datumserkennung im
Titel ("morgen" etc.), automatische Prioritäts-/Tag-Vorschläge aus Schlüsselwörtern.

**Auswertung**: Statistik-Modal (Zeit nach Typ, 7-Tage-Sparkline, 12-Wochen-Heatmap, Durchsatz,
Burndown, Wochen-Badges), Dyce-Tagesabschluss (TSV-Export), Tages-Recap/Wochenbericht,
Druckansicht.

**Spielereien**: Konfetti bei Erledigung, Level-/XP-System, Sound-Effekte (Web Audio API,
synthetisiert, standardmässig aus), Entscheidungs-Glücksrad, eigene Akzentfarbe, eigenes
Hintergrundbild, Deutsch/Englisch-Umschalter (nur Hauptnavigation übersetzt, kein voller i18n).

**Mehrere Boards & Mobile**: Mehrere benannte Boards umschaltbar, PWA (manifest+SW+responsives
CSS, auf Mobile-Viewport getestet), **📱 QR-Code-Sync**: selbst geschriebener QR-Encoder (Model 2,
Versionen 1–5, EC-Level L, Byte-Modus + UTF-8-ECI-Segment) für Einzel-Task-Sharing zwischen
Geräten – verifiziert gegen einen echten Python-QR-Decoder (pyzbar), dabei einen echten
UTF-8/ECI-Bug gefunden und behoben.

**Datenschutz/Sicherheit**: 🔒 PIN-Sperre (reiner Sichtschutz, KEINE echte Verschlüsselung),
☁️ Cloud-Sync (siehe oben, die eigentliche Verschlüsselungslösung).

## Verwendete Test-Methodik (für Konsistenz in Folge-Sessions wichtig)

- `file://` blockiert File System Access API und Service Worker (brauchen "secure context").
  Für Tests: lokaler `python -m http.server` (Bash-Tool) + Claude_Browser-Tool, danach immer
  aufräumen (Server killen, Tab schliessen). Ausgelieferte Dateien bleiben `file://`-kompatibel.
- QR-Encoder wurde zusätzlich gegen echte Python-Libraries (`qrcode`, `pyzbar`, `Pillow`)
  verifiziert – SVG→Canvas→PNG→Decode-Kette.
- Cloud-Sync wurde mit gemocktem `window.fetch` getestet (kein echter Token verfügbar) – der
  volle Verschlüsseln→Hochladen→Herunterladen→Entschlüsseln-Kreislauf wurde so verifiziert, plus
  ein Fake-Token gegen die echte GitHub-API bestätigte das korrekte Request-Format (sauberes
  "Bad credentials" statt Format-Fehler).
- **Bekannte Test-Artefakte, keine echten Bugs**: (a) Service-Worker-Registrierung schlägt in der
  Claude_Browser-Sandbox-Preview fehl (bestätigt via frischem Tab – echte Browser betroffen
  nicht); (b) synthetische "Enter"-Taste über das Computer-Tool feuert manchmal keinen
  keydown-Listener zuverlässig – immer via `dispatchEvent(new KeyboardEvent(...))` gegenprüfen,
  hat sich bisher immer als funktionierend bestätigt.

## Bereits gefundene & behobene echte Bugs (Historie)

1. `window.confirm()` wurde von Windows-IT-Policy auf dem Arbeitsgerät stumm blockiert →
   ersetzt durch eigenen `confirmDialog()`.
2. Screenshot-Paste-Listener registrierte sich bei jedem Modal-Reopen neu (Duplikate) → auf
   einen globalen Listener mit `openTaskModalId`-Tracking umgestellt.
3. QR-Encoder: Umlaute wurden ohne explizites UTF-8-ECI-Segment falsch interpretiert (Halfwidth-
   Katakana-Mojibake) → ECI-Segment (Assignment 26) ergänzt.
4. Cloud-Sync: Timestamp-Race beim Verbinden eines frischen Geräts (siehe oben).
5. Cloud-Sync: Race Condition beim Bestätigungs-Dialog (siehe oben).

## Aktueller Status

Alles oben Beschriebene ist implementiert, getestet und an den Nutzer ausgeliefert. Die zuletzt
gelieferte `index.html` enthält beide Cloud-Sync-Fixes. Nutzer wurde gebeten, sie erneut auf
GitHub hochzuladen. Keine offenen Aufgaben – der Nutzer wollte diese Zusammenfassung nur, weil
sein Kontextfenster voll wurde, um in einem neuen Chat nahtlos weiterzumachen.
