# Projekt-Kontext: Work Board (Kanban & Zeiterfassung)

> Diese Datei ist der Übergabe-Kontext für eine neue Claude-Instanz (Kontextfenster der
> vorherigen Session wurde voll). Bitte zuerst diesen Abschnitt lesen, dann den Rest als
> Hintergrundwissen.

## ✅ Stand 2026-10-07 (Fortsetzung): Zusammenarbeit mit geteilten Boards

Umgesetzt (README-Abschnitt "Geteilte Boards" enthält das einmalige SQL):
- **Architektur:** Block "GETEILTE BOARDS" vor "PUSH-BENACHRICHTIGUNGEN". Board-Schlüssel (AES-GCM) pro Board; pro Mitglied per ECDH P-256 verpackt
  (`wrapBoardKey`/`unwrapBoardKey`); eigenes Schlüsselpaar in `ensureUserKeys()` (privat verschlüsselt in `user_keys`, öffentlich in `profiles.public_key`).
  Entfernen einer Person = Rekey (`removeBoardMember`).
- **Zustand:** Geteilter Inhalt wird in `state.columns/tasks` "ausgecheckt", das persönliche Board liegt in `personalStash`. Alle persönlichen Speicher-/Sync-Stellen
  laufen über `withPersonalState()` / `serializePersonalState()` (doSave, Datei, Export, Cloud-Sync, Importe). Siehe `activeShared`, `sharedList`,
  `enterSharedBoard()`, `leaveSharedBoard()`, `currentBoardName()`.
- **Sync:** `sharedSync()` = holen, Drei-Wege-Merge (`mergeContent` mit Basis `sb.base`), ggf. Hochladen mit Versionsprüfung (`eq('version')`), Wiederholung bei Konflikt;
  Poll alle 10 s (`sharedPoll`), Push 1,5 s nach Änderung (`scheduleSharedPush`), lokaler Cache `wb-sb-<id>`. Merge in-place (`applyMergedToState`),
  damit offene Dialoge gültige Task-Objekte behalten.
- **Zeit:** Sitzungen in geteilten Boards tragen `by` (User-ID); `isMySession`, `myOpenSession`, `isRunning` und `secondsInRange` zählen nur eigene.
- **Zuweisung:** `task.assigneeId` + `assignee` (Name); Chip auf der Karte, Filter "Mir zugewiesen", Lanes "Nach Person" aus den Mitgliedern, Rechtsklick "Zuweisen an",
  Hinweis bei neuer Zuweisung (`notifyAssignments`).
- **UI:** Board-Umschalter in der Seitenleiste (`#boardSwitchBtn`, `#boardMenu`, `renderBoardMenu`), `openNewBoardDialog`, `openShareLocalBoardDialog`,
  `openBoardMembers`/`renderMembersModal`, Einstellungen → Board (`settingsBoardsHtml`, `wireSettingsBoards`), Anzeigename ändern (`updateOwnDisplayName`);
  die Registrierung verlangt Vor- und Nachnamen.
- Getestet im Browser gegen einen Supabase-Mock mit RLS-Nachbildung und zwei Personen (Anlegen, Einladen, Zuweisen, Timer pro Person, Notizen, Entfernen mit Rekey)
  sowie Unit-Tests der Merge-Logik. **Noch nicht gegen das echte Supabase getestet; das SQL aus der README muss zuerst ausgeführt werden.**

## ✅ Stand 2026-10-07 (Fortsetzung): Hotline-Formular, Control-Center, Reporter, KI-Ausbau, Task-Fenster

- **Statistik/Tagesabschluss** sind eigene Ansichten (`boardViewMode` = `stats`/`dyce`, `switchToView()`, `renderStatsView()`/`renderDyceView()`), keine Dialoge mehr.
- **Hotline-Anruf** (`openHotlineDialog()`, `createHotlineTask()`): nur Reporter, Anliegen, Notizen, Priorität, Rückruf-Nr.;
  Vorschläge beim Tippen (`findSimilarTasks()`, bisherige Tickets des Reporters), Button "Aus Notizen ausfüllen" (KI).
- **Reporter** (`task.reporter`, `task.phone`) = wer das Ticket eröffnet hat; Autofill über `uniqueReporters()`; Chip auf der Karte; in Suche enthalten.
- **Ähnliche Tasks** (`e_similar`-Block vor `quickStart`): Wortüberlappung inkl. erledigter/archivierter Tasks; Hinweis im Task-Fenster und im Entwurf.
- **Control-Center** (`toggleControlCenter()`, `ccBuild()`, `ccRefresh()`): Document-PiP-Fenster (Fallback: Panel `#ccPanel` in der Seite) mit laufendem Timer,
  Pause/Erledigt, Notiz, Schnell-Anlegen, Hotline/Meeting/Zeit erfassen, zuletzt bearbeitete Tasks. Ersetzt das alte Mini-Timer-Fenster.
- **KI-Ausbau:** "Ticket aus Text" (`openQuickCapture`, `processQuickCapture`) erkennt mehrere Tasks mit Reporter, Frist, Tags, Checkliste, Aufwand;
  `openDraftPreview` zeigt Entwürfe (mehrere, abwählbar, Duplikat-Hinweise); Strg+V auf dem Board startet es automatisch; Einfach-Erkennung ohne Key
  (`heuristicParse`); im Task: Verbessern/Zusammenfassen/Checkliste/Antwort (`runTaskAi`); Modellwahl (`AI_MODELS`, Standard Haiku 4.5).
- **Task-Fenster** zweispaltig: links Beschreibung, Notizen, Checkliste, Links, "Weitere Optionen" (Wiedervorlage, Übergabe, Abhängigkeiten, Rückfragen);
  rechts Zeit-Karte und Eigenschaften; Titel im Kopf; "Mehr"-Menü im Fuss. Alle IDs unverändert.
- Löschen-Button im Fuss wird nicht mehr gestreckt.

## ✅ Stand 2026-10-07 (Fortsetzung): Design-Erweiterung um neue Funktionen

Auf Wunsch ("erweitere es wie du es für richtig hältst") zusätzlich zu Variante A:
- **Schnellfilter-Chips** (`#filterBar`, `renderFilterBar()`, `QUICK_FILTERS`, `quickFilters`, `filterTag`): Heute fällig, Überfällig,
  Hohe Priorität, SLA-Risiko, Angeheftet, Läuft + die 6 häufigsten Tags, mit Zählern, UND-verknüpft; in `taskMatchesFilters()` integriert.
  Nur in Board-Ansichten sichtbar (nicht Dashboard/Kalender/Archiv).
- **Schnell-Anlegen** in der Spalte (`inlineAddColId`, `createQuickTask()`): Enter legt an und bleibt offen, Umschalt+Enter öffnet,
  Esc bricht ab; Kurzschreibweise `PROJ-123` (Jira-Key+Typ), `#tag`, `!kritisch|hoch|mittel|niedrig`.
- **Kartenmenü** (Rechtsklick, `openCardContextMenu`) neu: Timer, Anheften, Duplizieren, Priorität (4 Kacheln), Verschieben nach Spalte, Archivieren, Löschen.
- **Seitenleiste:** Tagesfortschritt (`renderSidebarToday()`, Ziel = `targetHoursPerDay`), Theme-Umschalter (System/Hell/Dunkel),
  einklappbar (`body.sb-collapsed`, localStorage `wb-sb-collapsed`, nur Desktop).
- **Dashboard neu** (`renderDashboardWidgets()`): Begrüssung, 5 Kennzahlen (klickbar → gefilterte Board-Ansicht), Fällig/Überfällig, Heute im Fokus,
  Wochen-Balkendiagramm (SVG, Ziel-Linie), Zeit nach Typ, Erinnerungen, "Was jetzt?". `#board.dashboard-mode` ermöglicht Scrollen.
- **Task-Fenster:** Zeit-Karte oben, ruhigere Formular-Beschriftungen/Abstände. Leere Spalten mit gestrichelter Fläche und Hinweis.
- Neue Tastenkürzel: `/` fokussiert die Suche. Cheatsheet (`?`) ergänzt.

## ✅ Stand 2026-10-07 (Fortsetzung): Gesamtdesign "Variante A – modern und clean"

Nutzer wählte nach zwei Mockups Variante A. Umbau (Funktionen unverändert, alle Element-IDs erhalten):
- **Layout:** linke Seitenleiste `#sidebar` (Board, Kalender, Statistik, Archiv, Tagesabschluss, Ansichten
  Dashboard/Priorität/Eisenhower/Person/Gruppe, unten XP + Uhr + Benutzer-Chip = `#btnSettings`),
  Hauptspalte `#mainCol` mit Kopfzeile. Das alte `<select id="boardViewSelect">` bleibt versteckt im DOM
  (Command-Palette setzt `.value`); `renderSidebarActive()` (in `renderBoard()`) hält die Markierung aktuell.
- **Kopfzeile:** Suche, Filter, "Was jetzt?", "Fokus", Timer-Pille (`#timerBanner` jetzt IN der Kopfzeile),
  Sync, geteilter Button "Neuer Task" (+ Menü `#newMenu`: Hotline, Meeting, Zeit erfassen, Schnellerfassung,
  Zwischenablage) und "⋯"-Menü `#moreMenu` (Auswahl, Kompaktansicht, Sichern). Menüs über `closeAllMenus()`.
- **Karten:** Typ als getöntes Symbol (`typeIconHtml`, SVG-Sprite `#i-*` am Anfang von `<body>`), Ticket-Key
  oder Typ-Name, Priorität als 3 Balken statt linkem Rand, laufende Karte `.is-running`. Zeit-Anzeige:
  `[data-time-for] .tv` (tick() aktualisiert nur `.tv`). Spalten sind transparent, Spaltenfarbe als Punkt.
- **Tokens:** neue Palette in `:root` (hell) + dunkel (`data-theme` und `prefers-color-scheme`), Schrift
  Instrument Sans (Google Fonts, Fallback System), `--hover`, `--side`, `--ty-*`.
- **Sprache:** `data-i18n` auf `.lbl`-Spans statt `textContent` auf Buttons (I18N-Wörterbuch ohne Emoji).
- **Mobil (<680px):** Seitenleiste als Schublade (`body.sb-open`, ☰-Button `#btnMoreToggle`), zweite
  Kopfzeile mit Filtern/Was jetzt/Fokus scrollbar.
- Getestet gegen gemocktes Supabase im Browser (Hell/Dunkel, Navigation, Menüs, Dialoge, Auswahl, Kompakt).

## ✅ Stand 2026-10-07 (Fortsetzung): Einstellungsmenü neu aufgebaut

Nutzer fand das Menü "schrecklich". Neu: Seitenleiste (auf dem Handy horizontale Tab-Leiste) mit
5 Tabs statt 6: Konto & Daten (Konto, Cloud-Speicher, Lokale Sicherung, Sichtschutz/PIN), Darstellung,
Zeit (Erinnerungen, Pomodoro, SLA, Auswertung), Board (einklappbar: Spalten, Boards, Team, Vorlagen,
Textbausteine, Typen), Integrationen (Jira/Confluence, ntfy, KI, Read-only-Link/GitHub-Token) + Admin.
Aufbau über Helfer `sCard/sRow/sMore/sCollapsible/sNum/sCheck` (vor `openSettings()`), CSS `.s-*`.
Lange Erklärungstexte stehen in aufklappbaren "Mehr erfahren"-Bereichen. **Alle Element-IDs blieben
unverändert**, damit die Verdrahtung unterhalb von `openSettings()` nicht angepasst werden musste.

## ✅ Stand 2026-10-07: Board-Daten jetzt in Supabase (pro Person, Ende-zu-Ende-verschlüsselt)

Nutzer-Erwartung war, dass die Daten nach dem Login in Supabase liegen (vorher nur Identität via
Supabase, Daten im Gist). Entscheidungen des Nutzers: **pro Person ein eigenes Board** (kein
gemeinsames), **verschlüsselt, nicht im Klartext**. Umsetzung:
- Neue Tabellen `boards` (user_id PK, payload text = Chiffretext-JSON, updated_at) und
  `board_snapshots` (user_id, day, payload; letzte 7 Tage) – SQL in der README. RLS: nur eigene Zeile.
  **Der Nutzer muss dieses SQL einmalig im Supabase-SQL-Editor ausführen** (sonst Fehlerscreen
  "Cloud-Speicher nicht erreichbar" mit Option "nur lokal fortfahren").
- Verschlüsselung unverändert (AES-256-GCM + PBKDF2, `cloudEncryptState`/`cloudDecryptPayload`), aber
  Transport statt Gist jetzt `cloudRemoteGet/Put` (Supabase). Bewusst EIGENE Passphrase statt
  Login-Passwort (Reset würde sonst Daten unlesbar machen). Passphrase nur in localStorage
  (`wb-cloud-sync-config`, jetzt mit `backend:'supabase'`, `userId`).
- Neuer Ablauf direkt nach Login, vor `init()`: `ensureBoardSetup()` (im Auth-Overlay): kein Board in
  der Cloud → Passphrase festlegen (alte Gist-Passphrase wird vorgeschlagen), Board vorhanden →
  Passphrase eingeben (Entschlüsselungstest), "Passphrase vergessen?" → Board löschen + neu anlegen.
  `resetLocalBoardIfOtherUser()` (Marker `wb-board-owner`) verwirft lokale Daten, wenn auf demselben
  Gerät eine andere Person anmeldet.
- Entfernt: Gist-Sync (Create/Join/Snapshot im Gist), QR-Kopplung (WBP1), Willkommens-Dialog (jetzt
  nur einmaliger Toast). Gist-Token bleibt optional NUR für "Read-only-Link teilen" (`cloudGistHeaders`).
- Einstellungen → Speicher: Cloud-Speicher-Block steht jetzt oben; "Speicherort" heisst
  "Lokale Sicherung (optional)".
- Standard-URL/Key sind in `DEFAULT_SUPABASE_URL`/`DEFAULT_SUPABASE_ANON_KEY` (publishable key) hinterlegt.
- Konsequenz pro-Person-Board: Zuweisen an andere Personen wirkt nur als Namensfeld im eigenen Board;
  ntfy-Push/Teamfunktionen sind damit nur noch begrenzt sinnvoll (ggf. später gemeinsames Board).
- Getestet nur gegen gemocktes Supabase (In-Memory-DB): Erst-Setup, Verifikation Chiffretext,
  zweites Gerät mit falscher/richtiger Passphrase, Personenwechsel, Vergessen-Flow, Passphrase-Fehler
  in Einstellungen. Echter Supabase-Test steht aus.

## ✅ Stand 2026-10-01 (Fortsetzung): Admin-Bereich für Benutzerverwaltung

Direkt im Anschluss an den Pflicht-Login (siehe Eintrag unten) gewünscht: "Admin Login, mit welchem
ich User verwalten kann (PW-Zurücksetzen, Benutzer erstellen, etc.)". Wichtige Design-Entscheidung
dabei, dem Nutzer klar erklärt statt stillschweigend umgesetzt: **echtes Benutzer-Anlegen/-Löschen/
-Sperren ist clientseitig grundsätzlich NICHT sicher machbar** – das bräuchte Supabase's geheimen
`service_role`-Key, der niemals im öffentlich gehosteten GitHub-Pages-Code stehen darf (jede Person
könnte ihn über "Seitenquelltext anzeigen" auslesen → voller Zugriff aufs ganze Supabase-Projekt).
Deshalb bewusst nur den sicheren Teil gebaut (Commit `a788b26`):
- Neue `admins`-Tabelle, RLS nur mit SELECT-Policy (lesbar für alle Angemeldeten), **bewusst ohne
  insert/update/delete-Policy** – Admin-Rechte vergeben geht nur manuell im Supabase Table Editor,
  nie über die App (verhindert jede Form von Selbst-Ernennung zum Admin über die REST-API).
- `isCurrentUserAdmin` (einmal beim Login gegen diese Tabelle geprüft) schaltet einen neuen
  "🛡️ Admin"-Tab in den Einstellungen frei – reine UI-Bequemlichkeit, die eigentliche Absicherung
  läuft über RLS in der Datenbank, nicht über diese Variable.
- Admin-Tab zeigt alle registrierten Profile (Name, E-Mail, Admin-Badge) mit Button
  "🔑 Passwort-Reset" pro Person – ruft einfach `resetPasswordForEmail()` auf (dieselbe Funktion wie
  "Passwort vergessen" beim Login), kein Kenntnis des aktuellen Passworts nötig.
- "Neue Benutzer anlegen" bewusst NICHT als Button gebaut, da nicht sicher möglich – Registrierung
  bleibt offen (jede Person registriert sich selbst über den App-Link), das deckt denselben Bedarf
  bereits ab.
- README ergänzt um SQL für die `admins`-Tabelle, Schritt-für-Schritt "dich selbst zum ersten Admin
  machen", und eine explizite Erklärung, warum Benutzer-Anlegen/-Löschen fehlt.

**Nebenbei behoben:** Nutzer testete mit einem echten Supabase-Projekt und bekam
Bestätigungs-E-Mails mit Links auf `localhost:3000` (Supabase-Standard-Platzhalter für "Site URL").
Kein Code-Bug, sondern fehlende Dashboard-Konfiguration – Anleitung dafür direkt in die README
eingebaut (Authentication → URL Configuration → Site URL auf die echte GitHub-Pages-Adresse).

**Getestet** (gemockter Supabase-Client, zwei separate registrierte Test-Nutzer): Admin-Tab
erscheint korrekt NUR für die in `__mockAdmins` vorab eingetragene Person, bleibt für eine zweite,
normal registrierte Person unsichtbar; Passwort-Reset-Button ruft korrekt die richtige E-Mail auf
und zeigt eine Bestätigung. Kein echtes Supabase-Projekt für den Test verfügbar.

**Wiederkehrendes Muster, drittes Mal in dieser Session:** Beim Pushen kam wiederholt ein leerer
"Add files via upload"-Commit auf GitHub dazwischen (inhaltlich jedes Mal identisch zum vorherigen
Stand – alle drei Male sauber gemerged, kein Datenverlust). Das ist dem Nutzer aufgefallen gemeldet
worden, Ursache noch ungeklärt (evtl. ein Automatismus oder wiederholtes Klicken im GitHub-
Webinterface) – falls es nochmal auftaucht, lohnt sich eine gezielte Rückfrage beim Nutzer, was das
auslöst, statt es nur stillschweigend wegzumergen.

## ✅ Stand 2026-10-01: Pflicht-Login via Supabase Auth eingebaut

Neue Claude-Instanz nach Kontext-Reset (altes Fenster voll) – Session ging nahtlos weiter, da der
Nutzer mitten in einer Rückfrage ("Login Pflicht oder optional?") mit "Echte ID ist notwendig"
geantwortet hatte. Interpretiert als **Pflicht-Login**, dem Nutzer das kurz gespiegelt, dann
umgesetzt ohne weitere Rückfrage (Auto-Mode).

**Hintergrund:** Nutzer fragte nach einem "normalen Login/Registrierungs-Mechanismus, z.B. mit
Supabase". Per AskUserQuestion geklärt, DASS es nicht um strengere Zugriffskontrolle ging, sondern
um echte Identität pro Person + Erweiterbarkeit auf mehr Nutzer + "fühlt sich richtiger an". Daraus
bewusst die LEICHTGEWICHTIGE Variante gebaut statt einer vollen Backend-Migration: Supabase macht
NUR Login/Identität, die Board-Daten laufen unverändert über den bestehenden Ende-zu-Ende-
verschlüsselten Gist-Cloud-Sync weiter. Das ist die erste externe Script-Abhängigkeit im ganzen
Projekt (`@supabase/supabase-js` per CDN) – bewusste Abweichung von der bisherigen "alles
selbstgebaut"-Regel, aber technisch weiterhin ohne Build-Schritt/Installation kompatibel mit dem
gesperrten Firmengerät (reiner `<script src=https://cdn.jsdelivr.net/...>`-Tag).

**Was gebaut wurde** (Commit `2e5879d`):
- `#authOverlay`: Vollbild-Gate (höherer z-index als `#lockOverlay`), blockiert `init()` komplett
  bis eine echte Anmeldung vorliegt. Zustände: Setup (Supabase Project URL + anon-Key eintragen,
  einmalig) → Login/Registrieren/Passwort-vergessen (alles über `supabase.auth`). Einzige
  Quelle der Wahrheit ist `onAuthStateChange` (nicht zusätzlich `getSession()` separat abfragen –
  vermeidet Race Conditions); `appStarted`-Guard verhindert Doppel-Init bei mehrfachen Auth-Events.
- `profiles`-Tabelle (SQL-Setup in README) hält Anzeigenamen pro registrierter Person, wird beim
  Login upserted; die "Zugewiesen an"-Auswahl im Task-Modal nutzt jetzt echte registrierte Namen
  (`registeredProfiles`) statt nur der alten freien `teamMembers`-Liste, mit Fallback falls die
  Tabelle (noch) nicht eingerichtet ist.
- `logActivity()` hängt jetzt automatisch "(von <Name>)" an, wenn `currentUser` gesetzt ist; drei
  ntfy-Push-Nachrichten (Hotline-Ticket, Task erledigt, zuvor schon Zuweisung) ebenfalls.
- Settings: neuer "👤 Konto"-Block oben im Speicher&Team-Tab (aktueller Nutzer + Abmelden-Button).
- README: neuer Abschnitt "👤 Login & Registrierung (Supabase)" mit kompletter Einrichtung
  (Supabase-Projekt anlegen, Project URL/anon-Key finden, SQL für `profiles`-Tabelle + RLS-Policies
  zum Copy-Paste in den Supabase SQL Editor).

**Getestet** (gemockter `supabase.createClient`, da kein echtes Supabase-Projekt verfügbar):
kompletter Zyklus Setup → Registrierung → `SIGNED_IN`-Event → `init()` startet automatisch →
Board rendert → Profil korrekt upserted → Zuweisen-Dropdown zeigt echten Namen → Aktivitäts-Log-
Attribution korrekt ("Verschoben: ... (von Timo Schmid)") → Abmelden lädt neu und zeigt wieder den
Login-Bildschirm (Konfiguration bleibt erhalten, nur die Session wird gelöscht). Die echte
Supabase-JS-Bibliothek lädt nachweislich übers CDN (nicht blockiert) – nur die Projekt-Zugangsdaten
selbst waren in diesem Test gefaked.

**Offen für die nächste Session:** Nutzer hat das noch nicht mit einem echten Supabase-Projekt
durchgetestet. Insbesondere prüfen: (1) klappt Registrierung inkl. evtl. E-Mail-Bestätigung wie in
der README beschrieben, (2) landen die `profiles`-Zeilen wirklich korrekt in der Datenbank (RLS-
Policies könnten bei echtem Testen noch Feinschliff brauchen, z.B. falls `anon`-Key allein nicht
reicht), (3) funktioniert die Zuweisen-Auswahl mit mehreren echten registrierten Personen.

**Nebenbei aufgefallen:** Zum zweiten Mal ist ein leerer "Add files via upload"-Commit auf GitHub
aufgetaucht (zwischen Session-Pushes), inhaltlich jedes Mal identisch zum vorherigen Stand – beide
Male sauber gemerged, kein Datenverlust. Falls das kein bewusstes Nutzer-Verhalten ist, lohnt sich
ein Nachfragen, was das verursacht (z.B. versehentliches Klicken im GitHub-Webinterface).

## ✅ Stand 2026-08-26 (spät abends): Repo-Team-Backend wieder entfernt, Settings-Tabs, Fixes

Nach dem Bau des Repo-Team-Backends (siehe Abschnitt unten für den Hintergrund) ist der Nutzer
beim ersten echten Testlauf auf einen `HTTP 404` bei "Neues Team-Repo erstellen" gestossen
(vermutlich Token ohne `repo`-Scope oder Fine-grained-Token, siehe Diagnose weiter unten). Danach
äusserte er, der ganze Prozess bis mehrere Personen Zugriff haben sei "sehr komplex". Auf
Rückfrage (AskUserQuestion) klar entschieden: **zurück auf den einfachen geteilten-Gist-Weg**,
Team-Repo-Backend **komplett entfernen** statt nur ausblenden.

**Was rückgebaut wurde** (Commit folgt in dieser Session): `cloudSyncConfigDefaults()` wieder ohne
`backend`/`repoOwner`/`repoName`; `cloudRepoHeaders/-ContentsUrl/-GetFile/-PutFile`,
`cloudCreateRepo()`, `cloudInviteCollaborator()`, `cloudFetchGistFile()`/`cloudFetchRemoteFile()`/
`cloudBackendReady()` komplett gelöscht; `cloudPushNow`/`cloudPullNow`/`cloudJoinExisting` zurück
auf die ursprüngliche reine Gist-Logik (kein Backend-Branching mehr); Settings-UI: Speicherart-
Radio, Repo-Felder, "Neues Team-Repo erstellen"-/"Einladen"-Buttons entfernt, ursprünglicher
Snapshot-Hinweistext in der Cloud-Sync-Einleitung wiederhergestellt (war beim Repo-Umbau versehentlich
generisch umformuliert worden und dabei verlorengegangen). README-Abschnitt "Team-Modus" entfernt,
durch einen kurzen Hinweis ersetzt: Zugriff für eine zweite Person = Token/Passphrase/Gist-ID
teilen (am einfachsten per bereits vorhandenem QR-Pairing).

**Lektion für die Zukunft:** Bei der nächsten Anfrage nach "mehreren Personen Zugriff geben" oder
"Team-Feature" zuerst den einfachen geteilten-Token-Weg vorschlagen (ist quasi ohne Zusatzaufwand
sofort nutzbar, da die App eh schon Multi-Geräte-Sync kann) und nur bei explizitem Wunsch nach
getrennten Identitäten pro Person den aufwändigeren Repo/Collaborator-Weg anbieten – nicht
standardmässig den komplexeren Weg vorschlagen, auch wenn er "sauberer" ist.

**Zusätzlich in dieser Session behoben:**
- Settings-Modal-Tab-Leiste (`position:sticky` + negative Margins) verursachte je nach
  Fensterbreite/Zoom eine sichtbare Text-Überlappung (Screenshot vom Nutzer bestätigt: Hint-Text
  über der Tab-Leiste sichtbar). Behoben durch simples `position:static` statt sticky - entfernt
  die ganze Fehlerklasse, statt den exakten Repro-Fall zu jagen (liess sich in der Test-Sandbox
  nur bei bestimmten Scroll-Positionen reproduzieren, nicht 1:1 wie im Nutzer-Screenshot).
- `HTTP 404` bei "Neues Team-Repo erstellen" diagnostiziert (bevor die Team-Funktion wieder entfernt
  wurde): wahrscheinlichste Ursache war ein wiederverwendeter Gist-Scope-Token oder ein
  Fine-grained-Token statt eines klassischen PAT mit `repo`-Scope – für den Fall, dass Repo-Sync
  o.ä. in Zukunft nochmal gebraucht wird, ist das die erste Diagnose-Richtung.

## ✅ Stand 2026-08-26 (Abend, historisch – Feature seither wieder entfernt): Team-Backend (Repo-Sync) + Push-Notifications (ntfy.sh) gepusht

Nutzer wünschte geteilten Board-Zugriff für zwei Management-Personen + Push-Benachrichtigungen
aufs Handy. Nach Rückfrage (AskUserQuestion) entschieden: **Repo-basiertes Team-Backend** (nicht
der einfachere geteilte-Token-Weg) und **ntfy.sh** für Push, ausgelöst bei: Task zugewiesen, neues
Hotline-Ticket, SLA kritisch, Task erledigt.

**Was gebaut wurde** (Commits `56c9a0f`, `d9debb8`):
- Cloud-Sync-Konfiguration bekam ein `backend`-Feld (`'gist'` Standard/unverändert, `'repo'` neu).
  Grund fürs Repo-Backend statt geteiltem Gist-Token: die GitHub-Gist-API lässt nur den
  *Besitzer*-Token schreiben; ein privates Repo unterstützt echte Collaborator-Einladungen, jede
  Person nutzt ihren eigenen Token. Neue Funktionen `cloudRepoGetFile`/`cloudRepoPutFile`
  (Contents API mit SHA-Handling), `cloudCreateRepo()` (POST /user/repos + Erstbefüllung),
  `cloudInviteCollaborator()` (PUT .../collaborators/{user}). `cloudPushNow`/`cloudPullNow`/
  `cloudJoinExisting` branchen jetzt über `cloudFetchRemoteFile()`/`cloudBackendReady()` statt
  Code zu duplizieren. Snapshots gibt's nur bei Gist – beim Repo übernimmt die Git-Historie das.
  Settings-UI: Radio-Umschalter "Persönlich (Gist)" / "Team (Repo)", bedingt sichtbare Felder.
- **ntfy.sh-Push**: `sendNtfyPush(title, message)` postet JSON an `https://ntfy.sh`. Bewusst
  generische Texte (kein Task-Titel/Kundenname), da der Text unverschlüsselt über ntfys Server
  läuft – anders als der Cloud-Sync-Inhalt selbst. Trigger: `createTask()` bei `type==='hotline'`,
  `updateTask()` bei Zuweisung (`patch.assignee` ändert sich) und bei Erledigt-Setzen, plus
  periodischer `checkSlaCriticalPush()` (alle 60s, dedupliziert über
  `state.settings.notifiedSlaCriticalIds`).
- Neue Settings-Sektion "🔔 Push-Benachrichtigungen" mit Thema-Feld, Aktiviert-Toggle, Testbutton.

**Bug gefunden und gefixt während der Arbeit:** klassischer JS-ASI-Fallstrick – eine IIFE mit
`return` direkt gefolgt von Zeilenumbruch vor dem eigentlichen Rückgabewert gab automatisch
`undefined` zurück (Automatic Semicolon Insertion), wodurch der komplette Radio-Button-Block für
die Speicherart-Auswahl im Settings-Modal fehlte (durch `"undefined<div id=..."` im gerenderten
HTML sichtbar geworden). Behoben, indem die IIFE durch eine normale, vorher berechnete Variable
ersetzt wurde. **Lektion:** `return` und der zurückgegebene Ausdruck müssen in derselben Zeile
stehen (oder in Klammern gesetzt werden), sonst greift ASI und man bekommt `undefined` zurück –
gilt für jede zukünftige mehrzeilige Return-Anweisung in diesem Code.

**Getestet** (lokaler `python -m http.server`, gemocktes `fetch`, siehe Test-Methodik unten):
Repo-Backend-Push→Pull-Zyklus komplett end-to-end mit echter Web-Crypto-Verschlüsselung
verifiziert (Base64-Payload nach Push korrekt entschlüsselbar). Alle drei ereignisbasierten
ntfy-Trigger (Hotline, Zuweisung, Erledigt) live im Browser ausgelöst und die gesendeten
JSON-Payloads geprüft. SLA-kritisch-Trigger nur per Code-Review verifiziert (periodischer
60s-Timer, zu lange fürs Testfenster; nutzt die bereits bestehende, getestete `slaLevel()`-Logik).

**Offen für die nächste Session:** Nutzer hat das Repo-Team-Backend und ntfy-Push noch nicht mit
echten GitHub-Accounts/Handys durchgetestet – reine Simulation mit gemocktem `fetch` bisher.
Insbesondere die Collaborator-Einladung (`cloudInviteCollaborator`) und der komplette
Zwei-Personen-Setup-Flow (zweite Person nimmt Einladung an, trägt eigenen Token ein, "Mit
bestehendem Speicher verbinden") sind gegen die echte GitHub-API noch nicht verifiziert worden.

## ✅ Stand 2026-08-26: Welcome-Dialog-Bug behoben + 6 neue Features gepusht

Nutzer hat den Welcome-Dialog-Fix bestätigt ("Funktioniert nun"). Danach in derselben Session auf
Nachfrage "was gibt es noch für Features" fünf Vorschläge gemacht, die der Nutzer alle umsetzen
liess, plus drei explizit gewünschte Verbesserungen an der Mehrfachauswahl. Alles implementiert,
im Browser getestet (lokaler `python -m http.server`, siehe Test-Methodik unten) und gepusht:

- **Mehrfachauswahl**: Umschalt+Klick wählt einen Bereich innerhalb einer Spalte, Spalten-Header
  hat einen "Alle auswählen"-Button, Bulk-Leiste kann jetzt auch endgültig löschen (mit
  Bestätigung). Commit `e95b12a`.
- **Statistik**: neue Auswertung "Zeit pro Projekt/Kunde" (gruppiert nach Jira-Projekt-Präfix).
- **Schwebendes Timer-Fenster** (Document Picture-in-Picture) über neuen Button im Timer-Banner.
  Im Test-Sandbox mit `NotAllowedError`/"Internal error: no window" abgelehnt (kein echtes
  User-Gesture bzw. keine PiP-Fensterverwaltung in der Sandbox) – das ist eine Einschränkung der
  Test-Umgebung, kein Code-Fehler; Fallback-Toast greift sauber. Auf echten Chrome/Edge-Geräten
  (ab v116) sollte es normal funktionieren – vom Nutzer noch nicht auf dem echten Gerät bestätigt.
- **Cloud-Sync-Retry bei Wiederverbindung**: `window.addEventListener('online', ...)` stösst
  sofort Push+Pull an, statt bis zu 45s zu warten.
- **.ics-Import mit Vor-Meeting-Erinnerung**: neues Feld "Erinnerung X Minuten vorher" im
  Import-Dialog, nutzt die volle Startzeit aus der .ics-Datei (bisher wurde nur das Datum
  geparst) und die bestehende `state.reminders`-Infrastruktur.
- **Jira-Bookmarklet Session-Ablauf-Erkennung**: alle vier Bookmarklets (Ticket-Erfassung,
  Confluence, Status setzen, Bulk-Import) erkennen jetzt Login-Seiten und (im Status-Bookmarklet
  zusätzlich) HTTP 401/403, statt mit leeren/falschen Daten weiterzumachen. Verifiziert per
  `eval()`-Testharness gegen eine gemockte Login-Seite und eine normale Nicht-Jira-Seite
  (Regressionscheck) – siehe Test-Methodik unten, gleiches Vorgehen wie in früheren Sessions.

README.md wurde für alle sechs Features synchron aktualisiert (Commit `26b0a9e`).

**Offen für die nächste Session:** Nutzer-Bestätigung, ob das schwebende Timer-Fenster auf dem
echten Gerät (Chrome/Edge) tatsächlich öffnet.

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
