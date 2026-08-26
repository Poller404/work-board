# Work Board – Kanban & Zeiterfassung

Ein einziges lokales HTML-File, keine Installation, kein Server, keine Admin-Rechte nötig.
Funktioniert offline im Browser – ideal fürs Arbeitsgerät.

## Start

Doppelklick auf `index.html` (öffnet sich im Standardbrowser, idealerweise Edge oder Chrome).

Am besten die Datei selbst gleich in deinen OneDrive- oder iCloud-Drive-Ordner legen, dann hast du
sie automatisch auf allen Geräten verfügbar.

## Wie werden meine Daten gespeichert?

Da die Datei per Doppelklick (`file://`) geöffnet wird, kann sie aus Sicherheitsgründen nicht
direkt und automatisch in eine beliebige Cloud-Datei schreiben (das würde nur mit einem echten
Server/`https://` funktionieren – auf einem Arbeitsgerät meist nicht möglich). Deshalb funktioniert
die Speicherung zweistufig:

1. **Automatisch, laufend:** Jede Änderung wird sofort im Browser gespeichert (localStorage).
   Solange du die Browserdaten nicht löschst, bleibt alles erhalten – auch nach Neustart.
2. **Cloud-Backup, 1 Klick:** Oben rechts auf **💾 Sichern** klicken (oder `Strg+S`). Das lädt eine
   Datei `work-board-daten.json` herunter. Über **📂 Datei laden** kannst du sie (z.B. auf einem
   zweiten Gerät) wieder einlesen.

**Empfohlene Einmal-Einrichtung**, damit das Backup automatisch im Cloud-Ordner landet:
Browser-Einstellungen → Downloads → Standard-Speicherort auf deinen OneDrive- oder
iCloud-Drive-Ordner ändern, und "Vor dem Herunterladen jedes Mal fragen" aktivieren. Dann zeigt
`💾 Sichern` jedes Mal den Speicherort mit der Option "Ersetzen" – ein Klick, und OneDrive/iCloud
synchronisiert den Rest von selbst.

Die Statusleiste unten zeigt jederzeit, wie viele Änderungen seit dem letzten Cloud-Backup
angefallen sind – und, falls eingerichtet, auch den aktuellen Cloud-Sync-Status (aktiv, Fehler,
oder nicht eingerichtet).

## ☁️ Cloud-Sync (automatisch, Ende-zu-Ende-verschlüsselt)

Läuft die App über `https://` (z.B. via GitHub Pages), kannst du dir das manuelle
Sichern/Laden komplett sparen: **⚙️ Einstellungen → Cloud-Sync** synchronisiert automatisch im
Hintergrund über einen **privaten GitHub Gist** – ohne dass GitHub oder sonst jemand deine Daten
lesen kann.

**Wie es funktioniert:** Deine Daten werden direkt in deinem Browser mit einer selbst gewählten
Passphrase verschlüsselt (AES-256-GCM), bevor irgendetwas hochgeladen wird. Erst danach geht die
verschlüsselte Datei an GitHub. Entschlüsselt wird ebenfalls nur lokal im Browser des jeweiligen
Geräts – nie unterwegs oder auf einem Server.

**Einrichtung:**
1. Einen GitHub **Personal Access Token** erstellen: GitHub → Settings → Developer settings →
   Personal access tokens → **nur die Berechtigung `gist`** aktivieren (keine anderen Rechte
   nötig).
2. **Auf dem ersten Gerät:** In ⚙️ Einstellungen → Cloud-Sync: Token einfügen, eine
   **Passphrase** wählen, Gist-ID-Feld leer lassen → **"☁️ Neuen Speicher erstellen (1. Gerät)"**.
   Das legt einen neuen, privaten ("secret") Gist an. Die neu erzeugte Gist-ID erscheint danach
   im Gist-ID-Feld, daneben ein **"📋 Kopieren"**-Button.
3. **Auf jedem weiteren Gerät** – am einfachsten fürs Handy per QR-Code, siehe unten. Alternativ
   manuell: gleicher Token (oder ein eigener mit `gist`-Recht), **dieselbe Passphrase**, und die
   kopierte **Gist-ID** ins Gist-ID-Feld einfügen → **"🔗 Mit bestehendem Speicher verbinden
   (weiteres Gerät)"** klicken.

   ⚠️ Wichtig: Auf dem zweiten (und jedem weiteren) Gerät **nicht** erneut "Neuen Speicher
   erstellen" klicken – das würde einen zweiten, komplett getrennten Speicher anlegen, der nicht
   mit dem ersten synchronisiert (die App warnt davor, falls auf einem Gerät schon Sync aktiv
   ist, aber zwischen zwei brandneuen Geräten kann sie das nicht automatisch erkennen).

### 📱 Handy per QR-Code koppeln (wie z.B. bei 1Password)

**Auf dem bereits eingerichteten Gerät:** in ⚙️ Einstellungen → Cloud-Sync auf **"📱 Gerät per
QR-Code koppeln"** klicken. Das zeigt einen QR-Code mit Token und Gist-ID dieses Geräts (**ohne**
Passphrase – die wird aus Sicherheitsgründen nie im QR-Code übertragen).

**Auf dem neuen Gerät (z.B. Smartphone):** beim Willkommensbildschirm (oder später in
⚙️ Einstellungen → Cloud-Sync) auf **"📷 Mit QR-Code verbinden"** tippen. Das öffnet die
Handy-Kamera direkt in der App (nutzt die native Scan-Funktion des Browsers, ohne zusätzliche
Kamera-App). Code scannen → Token und Gist-ID werden automatisch übernommen, danach fragt die App
nach der **Passphrase** – die muss man einmalig selbst eingeben (zweite Sicherheitsebene: wer nur
den QR-Code sieht/fotografiert, kommt ohne Passphrase trotzdem nicht an die Daten).

🔒 Der QR-Code enthält deinen GitHub-Token im Klartext (Design-bedingt) – trotzdem nicht
fotografieren/weiterleiten, Fenster nach dem Koppeln schliessen. Die Passphrase steckt bewusst
nicht mit drin, damit ein blosses Foto des QR-Codes allein nicht reicht, um an die Daten zu
kommen.

Unterstützt der Browser keinen Kamera-Scan direkt in der App (z.B. iPhone/Safari – dort gibt es
die nötige Browser-Funktion `BarcodeDetector` bislang nicht), zeigt die App das automatisch an und
verweist auf die Alternative: mit der normalen Kamera-App scannen, erkannten Text kopieren, in
Work Board auf **"📋 Aus Zwischenablage"** tippen – landet ebenfalls bei der Passphrase-Abfrage.

Danach läuft alles automatisch: jede Änderung wird verzögert (ca. 8 Sek.) hochgeladen, und beim
Öffnen bzw. alle 45 Sekunden wird geprüft, ob ein anderes Gerät etwas Neueres hochgeladen hat –
falls ja, erscheint ein Hinweisbanner zum Nachladen (dein aktueller Stand wird dabei **nicht**
automatisch überschrieben).

Für den manuellen Fall zwischendurch gibt es oben rechts direkt neben **💾 Sichern** den Button
**☁️ Sync** – ein Klick stößt sofort ein Hoch- und Herunterladen an, ohne die Einstellungen zu
öffnen (ist Cloud-Sync noch nicht eingerichtet, öffnet der Button stattdessen direkt die
Einstellungen dafür).

**Wichtig:**
- **Passphrase verloren = Cloud-Daten unwiederbringlich weg.** Es gibt keine
  Wiederherstellungsmöglichkeit – das ist der Preis für echte Verschlüsselung. Dein lokales
  "💾 Sichern"-Backup ist davon nicht betroffen.
- Der Token braucht wirklich nur die Berechtigung `gist`, sonst nichts.
- Cloud-Sync ist optional und komplett unabhängig vom manuellen Sichern/Laden – du kannst
  jederzeit beides parallel nutzen oder Cloud-Sync über "⏸ Sync deaktivieren" wieder ausschalten.
- **Zugriff für eine zweite Person** funktioniert genauso wie ein zweites eigenes Gerät: Token,
  Passphrase und Gist-ID mit ihr teilen (am einfachsten per **📷 QR-Code**, siehe oben – Passphrase
  aus Sicherheitsgründen separat mitteilen). Beide nutzen dann denselben Zugang; das ist für zwei
  vertraute Personen der mit Abstand einfachste Weg, ganz ohne zusätzliche Einrichtung.

## 🔔 Push-Benachrichtigungen aufs Handy (ntfy.sh)

Für Momente, in denen zwei Personen als Management schnell mitbekommen sollen, dass sich etwas
tut (z.B. eine Aufgabe zugewiesen wurde) – ganz ohne eigenen Server über den kostenlosen,
quelloffenen Relay-Dienst **[ntfy.sh](https://ntfy.sh)**.

**Einrichtung:**
1. Die kostenlose **ntfy-App** aus dem App Store / Play Store installieren (auf beiden Handys).
2. Einen **privaten, geheimen Themennamen** ausdenken (z.B. eine lange zufällige Zeichenfolge –
   wer den Namen kennt, kann mitlesen, ntfy-Themen sind nicht per Passwort geschützt) und in der
   App abonnieren – beide Personen abonnieren **denselben** Namen.
3. In Work Board: ⚙️ Einstellungen → Abschnitt "🔔 Push-Benachrichtigungen" → denselben
   Themennamen eintragen, "Aktiviert" anhaken, mit **"🔔 Test senden"** prüfen.

**Löst aus bei:** Task wird jemandem zugewiesen, neues Hotline-Ticket erstellt, ein Hotline-Ticket
wird SLA-kritisch, Task wird als erledigt markiert.

⚠️ Die Benachrichtigungstexte sind bewusst **generisch** gehalten (kein Task-Titel, kein
Kundenname) – anders als der Cloud-Sync-Inhalt läuft der Text kurz über ntfys Server und ist
**nicht** Ende-zu-Ende-verschlüsselt. Für Details muss man das Board selbst öffnen.

## Jira- & Confluence-Inhalte automatisch übernehmen (Bookmarklets)

Da eine echte API-Anbindung auf dem Arbeitsgerät nicht möglich ist, gibt es stattdessen zwei
Lesezeichen-Werkzeuge:

1. Im Tool: ⚙️ Einstellungen → Abschnitt "Jira- & Confluence-Import per Bookmarklet".
2. Die Links **📌 Jira → Board** und **📘 Confluence → Board** in die Lesezeichenleiste deines
   Browsers **ziehen** (nicht klicken).
3. Ein Jira-Ticket bzw. eine Confluence-Seite öffnen und auf das passende Lesezeichen klicken.
   Bei Jira werden Titel, Ticket-Nummer, Beschreibung und Priorität automatisch in die
   Zwischenablage kopiert; bei Confluence Titel, Space und Link.
4. Im Work Board auf **📋 Aus Zwischenablage** klicken – der Task-Entwurf ist bereits ausgefüllt
   (inkl. automatisch verknüpftem Link), nur noch prüfen und "Task erstellen" klicken.

Jira/Confluence Cloud ändern gelegentlich ihre Seitenstruktur – falls ein Bookmarklet nichts
findet, einfach Titel/Beschreibung manuell markieren, kopieren und stattdessen
**🤖 Schnellerfassung** nutzen (dort reicht simples Einfügen/`Strg+V`).

## Hotline-Anrufe, Meetings & freie Zeiterfassung

- **📞 Hotline-Anruf**: Ein Klick erstellt sofort einen Task, startet den Timer und öffnet ein
  Notizfeld. Während des Gesprächs einfach Notizen eintippen (mit Zeitstempel). Am Ende:
  **📋 Notizen + Dauer für Jira-Kommentar kopieren** – fertig formatiert zum Einfügen ins Ticket.
- **📅 Meeting**: gleiches Prinzip, misst automatisch die Meeting-Dauer.
- **⏱️ Zeit erfassen**: für alles andere, was nicht Hotline/Meeting/Jira ist. Ein Klick, kurz
  eintippen wofür (z.B. "Rechnungen kontrollieren"), Enter oder "▶ Starten" – legt sofort einen
  Ad-hoc-Task in "In Bearbeitung" an und startet direkt den Timer. Titel leer lassen geht auch,
  dann heisst der Task "Zeiterfassung HH:MM" und kann jederzeit im Task selbst umbenannt werden.
  Auch über die Command Palette (`Strg+K`) erreichbar.

## Mail zu Task

Eine vollautomatische Mail-Überwachung ist mit einer rein lokalen Datei technisch nicht möglich
(es bräuchte einen dauerhaft laufenden Dienst). Stattdessen: Mailtext markieren, kopieren, im Tool
auf **🤖 Schnellerfassung** klicken, einfügen (`Strg+V`), "Task-Entwurf erstellen" – dauert
wenige Sekunden. Mit einem eigenen Anthropic-API-Key (⚙️ Einstellungen) erstellt eine KI daraus
automatisch Titel, Beschreibung, Typ und Priorität; ohne Key wird eine einfache Texterkennung
verwendet.

## Tagesabschluss für Dyce

**🧾 Tagesabschluss** zeigt alle an einem Tag erfassten Zeiten gruppiert nach Ticket/Task, inkl.
Total. Über **📋 Als Tabelle kopieren** lässt sich die Übersicht direkt in Dyce oder Excel
einfügen.

## Statistik

**📊 Statistik** zeigt für Heute/Woche/Monat: Zeit pro Typ, **Zeit pro Projekt/Kunde** (gruppiert
nach Jira-Projekt-Präfix, z.B. "PROJ-123" → "PROJ" – praktisch fürs Rapportieren an mehrere
Kunden), Durchsatz (erledigte Tasks), eine 7-Tage-Sparkline, eine 12-Wochen-Verlaufs-Heatmap,
offen-vs-erledigt sowie ein paar Wochen-Kennzahlen (Anrufe, Meetings, längste Sitzung).

## Fokus, Priorität & Tempo

- **🧭 Was jetzt?** schlägt automatisch den nächsten Task vor (angepinnt zuerst, dann höchste
  Priorität, dann ältester Task).
- **🎯 Fokus** startet einen Pomodoro-artigen Fokus-Block (Dauer einstellbar) für den aktuellen
  bzw. vorgeschlagenen Task, mit Countdown-Overlay.
- **🎯 Nach Priorität**: Board umschalten von Status-Spalten auf Prioritäts-Swimlanes; Karten
  zwischen Spalten ziehen ändert dann die Priorität statt den Status.
- **📌 Anpinnen**: wichtige Tasks bleiben immer oben in ihrer Spalte.
- **☑️ Auswahl**: Mehrfachauswahl von Karten für Bulk-Verschieben/-Priorisieren/-Archivieren/
  **-Löschen** (mit Bestätigung). Einzelne Karten anklicken, **Umschalt+Klick** wählt einen
  ganzen Bereich innerhalb einer Spalte, und ☑️ im Spalten-Header wählt alle Tasks dieser
  Spalte auf einmal.
- Titel/Beschreibung werden beim Verlassen des Feldes automatisch nach Dringlichkeits-Wörtern
  ("dringend", "ASAP" …), passenden Tags (z.B. "VPN" → #vpn) und relativen Datumsangaben
  ("morgen", "Freitag", "in 3 Tagen") durchsucht – Priorität/Tags/Fälligkeitsdatum werden
  automatisch vorgeschlagen. Ähnlich klingende, evtl. doppelte Tickets werden ebenfalls erkannt.

## Zeiterfassung – Komfort & Sicherheit

- **Zeit-Budget**: pro Task eine Schätzung (Minuten) hinterlegen, Fortschrittsbalken auf der
  Karte zeigt Ist vs. Soll.
- **SLA-Ampel** für Hotline-Tickets: färbt sich gelb/rot, wenn ein Ticket zu lange offen ist
  (Schwellwerte in ⚙️ Einstellungen).
- **Idle-Erkennung**: warst du >10 Min. inaktiv während ein Timer lief, fragt das Tool beim
  Weitermachen, ob die Zeit abgezogen werden soll.
- **Übernacht-Timer-Wächter**: erkennt beim Start, wenn ein Timer vergessen wurde zu stoppen
  (>10 h ununterbrochen), und bietet an, ihn zu stoppen oder auf 18:00 des Vortags zu kürzen.
- **Pausen-Erinnerung**: meldet sich, wenn seit der letzten markierten Pause zu lange gearbeitet
  wurde ("☕ Pause jetzt markieren" in den Einstellungen).
- **😴 Wiedervorlage**: Tasks für später "einschlafen" lassen (morgen 9 Uhr / in 2h / eigenes
  Datum) – sie verschwinden vom Board und tauchen automatisch (mit Hinweis) wieder auf.
- **🔁 Wiederkehrend**: Task täglich/wöchentlich bei Erledigung automatisch neu anlegen.

## Aktivität, Übergabe & Abhängigkeiten

- **Aktivitäts-Verlauf**: jeder Task protokolliert automatisch Erstellung, Verschiebungen und
  Prioritätsänderungen.
- **🤝 Übergabe**: Task mit "an wen + Grund" als übergeben markieren.
- **Abhängigkeiten**: "Blockiert durch"-Verknüpfungen zu anderen Tasks, inkl. Erledigt-Status.

## Eingabe-Komfort

- **⌨️ Strg+K**: Command Palette – Tasks suchen oder Aktionen ausführen, ohne die Maus.
- **Pfeiltasten**: zwischen Karten navigieren (bei fokussierter Karte), **Shift+Pfeil** verschiebt
  die Karte in die Nachbarspalte (bzw. ändert die Priorität in der Swimlane-Ansicht).
- **📎 Textbausteine**: wiederkehrende Notizen/Antworten in den Einstellungen anlegen, per
  📎-Button in Notizen und Schnellerfassung einfügen.
- **🎙️ Diktieren**: Notizen per Spracheingabe eintippen (sofern der Browser das unterstützt).
- **Tag-Autocomplete**: beim Tippen im Tags-Feld werden passende, bereits verwendete Tags
  vorgeschlagen (pro Komma-Segment, nicht nur für das ganze Feld).
- **Screenshot einfügen**: Bild aus der Zwischenablage direkt mit `Strg+V` im Task-Fenster
  einfügen – landet automatisch als Notiz.
- **Automatische Zwischenablage-Erkennung** (optional, ⚙️ Einstellungen): erinnert von selbst,
  wenn Bookmarklet-Daten in der Zwischenablage liegen.
- **Meeting-Titel-Gedächtnis**: häufige Meeting-Titel als Chips zum schnellen Wiederverwenden.
- **📅 .ics-Export**: ein Meeting nachträglich als Kalendereintrag herunterladen (Outlook-Import).

## Berichte & Spielereien

- **📝 Tages-Recap** / **📄 Wochenbericht** (über `Strg+K`): fertig formatierte Zusammenfassung
  aus Tasks, Zeiten und Notizen – kopierbar für Status-Updates.
- **🎡 Entscheidungs-Glücksrad** (über `Strg+K`): wenn mehrere Tasks gleich wichtig sind, wählt
  ein kleines Glücksrad eins davon aus.
- **🎉 Konfetti**, wenn ein Task nach "Erledigt" wandert.
- **Boards**: mehrere getrennte Boards (z.B. "Arbeit"/"Privat") anlegen und wechseln, in
  ⚙️ Einstellungen.
- **Eigene Akzentfarbe** in den Einstellungen.

## Handy / mobiler Zugriff

Die Oberfläche ist responsiv (schmale Spalten, grössere Touch-Ziele) und lässt sich auf dem Handy
per "Zum Home-Bildschirm hinzufügen" ablegen (`manifest.json` liegt bei). Für automatischen Sync
zwischen PC und Handy: siehe **☁️ Cloud-Sync** oben – damit läuft es im Hintergrund, ganz ohne
manuelles Exportieren/Importieren. Alternativ weiterhin **💾 Sichern** über OneDrive/iCloud, oder
das **📱 QR-Code**-Feature für einzelne Tasks (siehe unten).

## Struktur-Ansichten

- **Eigene Task-Typen**: über ⚙️ Einstellungen zusätzliche Typen mit eigenem Icon definieren.
- **Checklisten**: pro Task Unterpunkte mit Fortschrittsanzeige (X/Y) auf der Karte.
- **Board-Ansicht umschalten** (oben): Status (klassisches Kanban), Priorität, **Eisenhower-Matrix**
  (Wichtig×Dringend, basierend auf Anpinnen + Priorität) oder **nach Person** (Teammitglieder in
  ⚙️ Einstellungen anlegen, Tasks per Drag&Drop zuweisen).
- **📦 Task-Gruppierung**: im Task-Fenster ein Gruppenname vergeben (z.B. "VPN-Rollout" – praktisch
  bei "gleiches Thema, ein Task pro Kunde"), mit Autocomplete über bereits vergebene Gruppen. Im
  normalen Status-Board klappen 2+ Tasks derselben Gruppe innerhalb einer Spalte automatisch zu
  einem einklappbaren Block zusammen (Anzahl + Gesamtzeit); dazu eine eigene **📦 Nach
  Gruppe**-Board-Ansicht mit einer Spalte pro Gruppe. Der ganze Block lässt sich per Drag & Drop
  in eine andere Spalte ziehen (bewegt alle Tasks der Gruppe auf einmal), und eine einzelne Karte
  auf einen bestehenden Gruppen-Block ziehen ordnet sie dieser Gruppe zu.
- **🗺️ Timeline** (`Strg+K`): Tasks mit Fälligkeitsdatum als Balken über die nächsten 30 Tage.
- **🕰️ Zeitreise** (`Strg+K`): Board-Zustand von einem früheren Tag ansehen (Snapshots werden
  automatisch einmal täglich erstellt).
- **📥 .ics-Import** (`Strg+K`): Outlook-Kalenderexport als Meeting-Tasks mit Fälligkeitsdatum
  einlesen, optional mit einer Erinnerung X Minuten vor Meeting-Start (nutzt die Uhrzeit aus der
  .ics-Datei, nicht nur das Datum).

## Bedienkomfort & Vorlagen

- **Rechtsklick auf eine Karte**: Schnellmenü (Öffnen, Anpinnen, Duplizieren, Priorität, Archivieren,
  Löschen) ohne den Task zu öffnen.
- **📐 Task-Vorlagen**: komplette Vorlagen (Typ, Priorität, Tags, Beschreibung) anlegen – im Task auf
  "💾 Als Vorlage", neue Tasks daraus über `Strg+K` → "Aus Vorlage".
- **`?`-Taste**: zeigt alle Tastaturkürzel.
- **🔒 PIN-Sichtschutz** (⚙️ Einstellungen): Startbildschirm blendet sich aus, bis der PIN eingegeben
  wird – reiner Sichtschutz vor vorbeigehenden Blicken, **keine echte Verschlüsselung**.

## Auswertung, KI & Spielereien

- **🧠 KI-Wochenanalyse** (`Strg+K`, benötigt eigenen Anthropic-API-Key): kurze Einschätzung +
  2-3 konkrete Tipps zur laufenden Woche.
- **💰 Zeit-Preis-Rechner**: Stundensatz hinterlegen (⚙️ Einstellungen) – die Statistik zeigt den
  erarbeiteten Wert für den gewählten Zeitraum.
- **🖨️ Board drucken/als PDF** (`Strg+K`): saubere Druckansicht, gruppiert nach Spalte.
- **📱 QR-Code-Sync**: einzelnen Task als QR-Code anzeigen (im Task-Fenster), mit dem Handy scannen
  und die Daten über "📋 Aus Zwischenablage" bzw. Schnellerfassung auf einem zweiten Gerät
  übernehmen – funktioniert komplett ohne Server.
- **🏆 Level-/XP-System**: für jeden erledigten Task gibt's XP (mehr bei hoher Priorität), inkl.
  Level-Anzeige oben in der Leiste.
- **🔊 Sound-Effekte** (⚙️ Einstellungen, standardmässig aus): dezente Töne bei Timer-Start und
  erledigtem Task.
- **🖼️ Eigenes Hintergrundbild** fürs Board (⚙️ Einstellungen).
- **🌐 Deutsch/Englisch**: übersetzt die Hauptnavigation (Menüs/Formulare bleiben Deutsch).

## Weitere Erweiterungen (Batch-Update)

**Zeiterfassung**
- **Timer-Unterbrechung**: startest du während eines laufenden Timers einen neuen (z.B. Hotline-
  Anruf), merkt sich die App den unterbrochenen Task und bietet nach Ende der Unterbrechung per
  Toast "▶ Fortsetzen" an.
- **Dyce-Rundung**: im Tagesabschluss auf 5/15 Minuten rundbar.
- **Soll-/Ist-Vergleich**: optionale Ziel-Arbeitszeit/Tag (⚙️ Einstellungen), Statistik zeigt Soll
  vs. Ist für Heute/Woche/Monat.
- **Zeitverteilung als Kreisdiagramm** in der Statistik.
- **🍅 Pomodoro-Modus**: Fokus-Modus reiht optional automatisch Pausen zwischen den Blöcken ein
  (kurze/lange Pause, konfigurierbar), mit "Nächster Block"-Erinnerung danach.
- **🖼️ Schwebendes Timer-Fenster**: Button im Timer-Banner öffnet den laufenden Timer als kleines
  Always-on-Top-Fenster (Picture-in-Picture) – bleibt sichtbar, auch während in Jira/Outlook
  gearbeitet wird und der Board-Tab im Hintergrund ist. Benötigt Chrome/Edge ab v116.

**Board & Darstellung**
- **Undo** (`Strg+Z`): letzte Aktion rückgängig (Löschen, Archivieren, Bulk-Aktionen, Verschieben).
- **🗜️ Kompaktansicht**: schmalere Spalten, reduzierte Karten – Umschalter im Topbar.
- **WIP-Limits & eigenes Icon/Farbe pro Spalte** (Spalten-Menü ⋯).
- **🏠 Dashboard-Ansicht** (Board-Ansicht-Auswahl): Widget-Übersicht statt Spalten – heutige
  Prioritäten, SLA-Risiko, nächste Erinnerungen, Wochenzeit, "Was jetzt?" auf einen Blick.

**Persönliche Produktivität** (`Strg+K` durchsuchbar)
- **📓 Journal**: freie Notizen, getrennt von Tasks.
- **⏰ Erinnerungen**: freistehend, unabhängig von Tasks, per Toast/Notification fällig.
- **🌅 Morgen-Ritual**: Tagesprioritäten aus dem Backlog wählen, hervorgehoben im Board.
- **🗓️ Tages-Vorlagen**: wiederkehrende Routinen (z.B. "Montags-Setup") als Vorlage mit mehreren
  Tasks auf einmal anlegen.
- **Rückfragen-Feld** im Task (getrennt vom Notizen-Log, für später zu klärende Punkte).

**Jira & Wissen**
- **🔄 Jira-Status setzen** (Bookmarklet): schreibt den Status direkt im Ticket zurück (Best-Effort,
  abhängig von Jira-Version/-Berechtigung). Alle Jira-/Confluence-Bookmarklets erkennen jetzt eine
  abgelaufene oder fehlende Jira-Session (Login-Seite bzw. HTTP 401/403) und melden das klar,
  statt stillschweigend mit falschen/leeren Daten weiterzumachen.
- **📦 Jira-Suchliste → Board** (Bookmarklet): mehrere Tickets von einer Suchergebnisliste auf
  einmal importieren.
- **🔍 Lösungs-Wissensdatenbank**: durchsucht erledigte/archivierte Tasks nach Titel/Notizen.
- **🚨 SLA-/Fälligkeits-Dashboard**: alle Hotline-SLA-Risiken und überfälligen Termine auf einen Blick.
- **🤝 Schichtübergabe-Report** & **✉️ E-Mail-Antwort** direkt aus dem Task, sowie Tages-/
  Wochenberichte als E-Mail-Entwurf statt nur Kopieren.

**Daten & Zugriff**
- Cloud-Sync legt automatisch täglich einen **Snapshot** im selben Gist ab (letzte 7 Tage) –
  zusätzliche Absicherung gegen einen fehlerhaft hochgeladenen Stand.
- **Automatischer Sync-Retry**: meldet der Browser die Internetverbindung zurück (z.B. nach
  VPN-Wechsel oder WLAN-Aussetzer), synchronisiert Cloud-Sync sofort statt bis zu 45s auf das
  nächste Poll-Intervall zu warten.
- **🖨️ Wochenbericht als PDF**: formatierter Report über den nativen "Als PDF speichern"-Druckdialog.
- **🔗 Read-only-Link teilen**: erstellt einen separaten, unverschlüsselten Snapshot-Link (offene
  Tasks, ohne Notizen) zum reinen Ansehen – z.B. für den Chef. Kein Live-Sync, jede Änderung
  braucht einen neuen Snapshot; wer den Link kennt, kann ihn lesen (wie ein unlisted Link).
- **📱 Kurzbefehle (iOS Shortcuts)**: die App reagiert auf `?action=hotline`, `?action=meeting`,
  `?action=timeentry&title=…`, `?action=pause`, `?action=whatnow` in der URL. In der
  Kurzbefehle-App: Aktion "URL öffnen" mit z.B. `https://DEINE-PAGES-URL/index.html?action=hotline`,
  optional per Siri-Phrase auslösbar.

## Tastenkürzel

- `N` – neuen Task erstellen
- `Leertaste` – laufenden Timer pausieren
- `Strg+S` – Cloud-Backup herunterladen
- `Strg+K` – Command Palette öffnen
- `Strg+Z` – letzte Aktion rückgängig
- Pfeiltasten (bei fokussierter Karte) – navigieren; `Shift`+Pfeil – Karte verschieben
- `Rechtsklick` auf Karte – Schnellmenü
- `?` – Tastaturkürzel-Übersicht
- `Esc` – Dialog schliessen

## Weitere Funktionen

- Spalten frei benennen, verschieben, per Priorität sortieren
- Suche & Filter nach Typ/Priorität
- Fälligkeitsdatum, Tags, mehrere Links (Jira/Confluence/Sonstige) pro Task
- Erledigte Tasks werden nach X Tagen automatisch archiviert (einstellbar), Archiv jederzeit einsehbar
- Hell/Dunkel-Theme
