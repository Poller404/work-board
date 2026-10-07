# Work Board – Kanban & Zeiterfassung

Ein einziges lokales HTML-File, keine Installation, kein Server, keine Admin-Rechte nötig.
Funktioniert offline im Browser – ideal fürs Arbeitsgerät.

## Start

Doppelklick auf `index.html` (öffnet sich im Standardbrowser, idealerweise Edge oder Chrome).

Am besten die Datei selbst gleich in deinen OneDrive- oder iCloud-Drive-Ordner legen, dann hast du
sie automatisch auf allen Geräten verfügbar.

**Login ist Pflicht** – beim ersten Öffnen erscheint ein Anmelde-Bildschirm statt des Boards, siehe
nächster Abschnitt zur Einrichtung.

## 👤 Login & Registrierung (Supabase) – einmalige Einrichtung

Damit jede Person mit einer echten, eigenen Identität arbeitet (statt eines geteilten Passworts),
läuft die Anmeldung über **[Supabase](https://supabase.com)** – einen kostenlosen Dienst. Supabase
übernimmt Login/Registrierung und speichert zusätzlich **pro Person ein eigenes Board, Ende-zu-Ende-
verschlüsselt** (siehe "☁️ Cloud-Speicher" weiter unten); lesen kann es nur, wer die Passphrase kennt –
weder Supabase noch Admins.

**Einrichtung (einmalig, durch eine Person):**
1. Kostenloses Konto auf [supabase.com](https://supabase.com) anlegen, neues Projekt erstellen
   (Name/Passwort/Region frei wählbar – das DB-Passwort wird hier nicht weiter gebraucht).
2. Im Projekt-Dashboard: **Project Settings → API** öffnen, dort **Project URL** und den
   **`anon` `public`-Key** kopieren (nicht den `service_role`-Key – der ist geheim und wird hier
   nicht gebraucht).
3. **SQL Editor** im Supabase-Dashboard öffnen, neue Query, folgendes einfügen und ausführen – legt
   die Tabellen für Profile, Admins und die verschlüsselten Boards an:
   ```sql
   create table profiles (
     id uuid primary key references auth.users(id) on delete cascade,
     display_name text not null,
     email text
   );
   alter table profiles enable row level security;
   create policy "Profile lesbar für alle Angemeldeten" on profiles
     for select to authenticated using (true);
   create policy "Eigenes Profil bearbeitbar" on profiles
     for insert to authenticated with check (auth.uid() = id);
   create policy "Eigenes Profil aktualisierbar" on profiles
     for update to authenticated using (auth.uid() = id);

   create table admins (
     id uuid primary key references auth.users(id) on delete cascade
   );
   alter table admins enable row level security;
   create policy "Admin-Status fuer alle sichtbar" on admins
     for select to authenticated using (true);
   -- Bewusst KEINE insert/update/delete-Policy auf "admins": Admin-Rechte
   -- lassen sich dadurch nur manuell im Table Editor vergeben, nie über
   -- die App selbst (siehe Abschnitt "🛡️ Admin-Bereich" weiter unten).

   -- Verschlüsseltes Cloud-Board: eine Zeile pro Person. "payload" enthält nur
   -- Chiffretext (im Browser verschlüsselt), RLS erlaubt jeder Person nur die eigene Zeile.
   create table boards (
     user_id uuid primary key references auth.users(id) on delete cascade,
     payload text not null,
     updated_at timestamptz not null default now()
   );
   alter table boards enable row level security;
   create policy "Eigenes Board lesen" on boards
     for select to authenticated using (auth.uid() = user_id);
   create policy "Eigenes Board anlegen" on boards
     for insert to authenticated with check (auth.uid() = user_id);
   create policy "Eigenes Board aktualisieren" on boards
     for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
   create policy "Eigenes Board löschen" on boards
     for delete to authenticated using (auth.uid() = user_id);

   -- Tägliche Snapshots (letzte 7 Tage), ebenfalls nur Chiffretext:
   create table board_snapshots (
     user_id uuid not null references auth.users(id) on delete cascade,
     day date not null,
     payload text not null,
     primary key (user_id, day)
   );
   alter table board_snapshots enable row level security;
   create policy "Eigene Snapshots lesen" on board_snapshots
     for select to authenticated using (auth.uid() = user_id);
   create policy "Eigene Snapshots anlegen" on board_snapshots
     for insert to authenticated with check (auth.uid() = user_id);
   create policy "Eigene Snapshots aktualisieren" on board_snapshots
     for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
   create policy "Eigene Snapshots löschen" on board_snapshots
     for delete to authenticated using (auth.uid() = user_id);

   -- Neue Supabase-Projekte geben der Rolle "authenticated" auf selbst angelegte Tabellen
   -- nicht mehr automatisch Rechte (Fehler sonst: "permission denied for table ..."):
   grant select, insert, update, delete on public.boards to authenticated;
   grant select, insert, update, delete on public.board_snapshots to authenticated;
   ```
4. **Authentication → URL Configuration**: **Site URL** auf deine echte Adresse setzen, z.B.
   `https://poller404.github.io/work-board/` (steht standardmässig auf `localhost:3000` – lässt man
   das stehen, zeigen Bestätigungs-/Passwort-Reset-E-Mails ins Leere). Bei Bedarf dieselbe Adresse
   auch unter **Redirect URLs** eintragen.
5. Optional: **Authentication → Settings** – falls E-Mail-Bestätigung gewünscht ist, ist sie
   standardmässig aktiviert (neu Registrierte bekommen eine Bestätigungs-E-Mail); zum Testen im
   kleinen Team lässt sie sich dort auch deaktivieren, dann ist man sofort nach der Registrierung
   angemeldet.
6. **Dich selbst zum ersten Admin machen**: Supabase-Dashboard → **Table Editor** → Tabelle
   `admins` → neue Zeile → als `id` deine eigene User-ID eintragen (zu finden unter
   **Authentication → Users**, Spalte "UID", nachdem du dich einmal im Work Board registriert hast)
   → speichern. Danach siehst du in der App unter ⚙️ Einstellungen einen neuen Tab "🛡️ Admin".

**Im Work Board:** Project URL und `anon`/publishable-Key sind in `index.html` hinterlegt
(`DEFAULT_SUPABASE_URL`/`DEFAULT_SUPABASE_ANON_KEY`), niemand muss sie eintragen. Jede Person kann
sich selbst mit E-Mail/Passwort registrieren (Name wird dabei einmalig festgelegt und
taucht danach bei Zuweisungen sowie im Aktivitäts-Verlauf jedes Tasks auf). Abmelden geht über
⚙️ Einstellungen → 👤 Konto.

### 🛡️ Admin-Bereich

Nur für Personen, deren User-ID manuell in der `admins`-Tabelle eingetragen wurde (Schritt 6 oben)
erscheint in ⚙️ Einstellungen ein zusätzlicher Tab **"🛡️ Admin"** mit einer Liste aller
registrierten Personen und einem Button **"🔑 Passwort-Reset"** pro Person (schickt denselben
E-Mail-Link wie "Passwort vergessen" beim Login, ohne das aktuelle Passwort zu kennen).

**Bewusste Einschränkung, technisch bedingt:** Es gibt in diesem Admin-Bereich absichtlich **keine**
Buttons zum direkten Anlegen, Löschen oder Sperren von Konten. Das würde den geheimen
`service_role`-Schlüssel von Supabase voraussetzen – der darf aus Sicherheitsgründen **niemals** im
Browser-Code einer öffentlich gehosteten Seite wie GitHub Pages landen, da ihn dann jede Person
über "Seitenquelltext anzeigen" auslesen und damit vollen Zugriff auf das gesamte Supabase-Projekt
bekommen könnte (nicht nur auf Work Board, auf *alles* in diesem Projekt). Neue Personen müssen sich
deshalb weiterhin selbst registrieren (die Registrierung ist absichtlich offen – einfach den
App-Link weitergeben); Admin-Rechte vergeben/entziehen bleibt ein manueller Schritt im
Supabase-Dashboard (Schritt 6 oben, dieselbe Zeile für eine andere Person entfernen entzieht sie
wieder).

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

## ☁️ Cloud-Speicher (automatisch, Ende-zu-Ende-verschlüsselt)

Nach der Anmeldung liegt dein Board automatisch in Supabase – **pro Person ein eigenes Board**, ganz
ohne manuelles Sichern/Laden und ohne GitHub-Token.

**Wie es funktioniert:** Deine Daten werden direkt in deinem Browser mit einer selbst gewählten
**Passphrase** verschlüsselt (AES-256-GCM), bevor irgendetwas hochgeladen wird. Supabase speichert
nur den unlesbaren Chiffretext (Tabelle `boards`); entschlüsselt wird ausschliesslich lokal im
Browser. Die Passphrase ist bewusst **nicht** dein Login-Passwort: Das Login-Passwort kennt bzw.
ersetzt Supabase (Passwort-Reset), die Passphrase verlässt dein Gerät nie.

**Einrichtung (pro Person, einmalig):**
1. Anmelden bzw. registrieren. Beim ersten Mal erscheint **"🔐 Verschlüsselung einrichten"** – eine
   Passphrase (mind. 8 Zeichen) festlegen, am besten im Passwort-Manager ablegen.
2. **Auf jedem weiteren Gerät:** anmelden, einmalig **dieselbe Passphrase** eingeben ("🔑 Passphrase
   eingeben") – danach wird sie auf dem Gerät gemerkt, das Board lädt automatisch. Kein Token, keine
   ID, kein QR-Code nötig.
3. **Bisher den Gist-Sync genutzt?** Die bisherige Passphrase ist beim ersten Mal vorausgefüllt; der
   Stand dieses Geräts wird einfach in die neue Cloud übernommen. Der alte Gist wird nicht mehr
   benutzt und kann in GitHub gelöscht werden.

Danach läuft alles automatisch: jede Änderung wird verzögert (ca. 8 Sek.) hochgeladen, und beim
Öffnen bzw. alle 45 Sekunden wird geprüft, ob ein anderes Gerät etwas Neueres hochgeladen hat –
falls ja, erscheint ein Hinweisbanner zum Nachladen (dein aktueller Stand wird dabei **nicht**
automatisch überschrieben). Oben rechts gibt es neben **💾 Sichern** den Button **☁️ Sync** für
einen sofortigen Abgleich.

In ⚙️ Einstellungen → **☁️ Cloud-Speicher** siehst du den Status und kannst
- die Passphrase **auf diesem Gerät übernehmen** (nötig, wenn du sie auf einem anderen Gerät
  geändert hast), oder
- die Passphrase **ändern & neu verschlüsseln** (andere Geräte müssen danach die neue eingeben).

**Wichtig:**
- **Passphrase verloren = Cloud-Daten unwiederbringlich weg.** Es gibt keine
  Wiederherstellungsmöglichkeit (auch Admins können nichts tun) – das ist der Preis für echte
  Verschlüsselung. Wer sie vergisst, kann beim Login "Passphrase vergessen?" wählen und ein
  **neues, leeres** Board anlegen (das alte wird dabei gelöscht). Dein lokales "💾 Sichern"-Backup
  ist davon nicht betroffen.
- **Eigene Boards:** Tasks sind nur für die jeweilige Person sichtbar; eine Zuweisung an andere
  Personen landet daher nur als Name/Hinweis im eigenen Board.
- **Gerätewechsel der Person:** Meldet sich auf demselben Gerät jemand anderes an, werden die
  lokalen Daten der vorherigen Person verworfen (sie liegen verschlüsselt in deren Cloud-Board).
- Ohne Verbindung arbeitet die App lokal weiter und gleicht beim nächsten Online-Moment ab.
- Das Anlegen der Tabellen `boards`/`board_snapshots` (SQL oben, Schritt 3) ist Voraussetzung;
  fehlen sie, zeigt die App beim Login "Cloud-Speicher nicht erreichbar" mit der Option, vorerst nur
  lokal weiterzumachen.
- Der optionale **GitHub-Token** in den Einstellungen (Scope `gist`) wird nur noch für
  "🔗 Read-only-Link teilen" gebraucht.

## 👥 Geteilte Boards (Zusammenarbeit)

Mehrere Personen können am selben Board arbeiten, Tasks zuweisen und Zeit erfassen – weiterhin
**Ende-zu-Ende-verschlüsselt** (Supabase und Admins sehen nur Chiffretext).

**Benutzung:**
- Oben links auf den Boardnamen klicken: **Meine Boards**, **Geteilte Boards**, "Neues Board…" (persönlich oder geteilt)
  und "Dieses Board teilen…" (legt eine geteilte Kopie des aktuellen persönlichen Boards an).
- Im geteilten Board: **Mitglieder verwalten…** (Person hinzufügen oder entfernen, Board umbenennen, verlassen oder löschen).
- Tasks lassen sich im Task-Fenster oder per Rechtsklick **zuweisen**. Die Zuweisung erscheint als Namens-Chip auf der Karte,
  es gibt den Filter **"Mir zugewiesen"** und die Ansicht **"Nach Person"**. Wer eine Zuweisung bekommt, sieht einen Hinweis.
- Zeiterfassung ist **pro Person**: Du siehst die Gesamtzeit eines Tasks, deine Tages- und Wochenzeiten zählen nur deine eigenen Sitzungen.
- Der **Name**, der bei Zuweisungen erscheint, wird bei der Registrierung abgefragt und lässt sich unter ⚙️ Einstellungen → Konto ändern.

**Einrichtung (einmalig, im Supabase SQL-Editor):**

```sql
-- Öffentlicher Schlüssel im Profil
alter table profiles add column if not exists public_key text;

-- Privater Schlüssel, mit der eigenen Passphrase verschlüsselt (nur die eigene Zeile)
create table user_keys (
  user_id uuid primary key references auth.users(id) on delete cascade,
  private_key_enc text not null,
  updated_at timestamptz not null default now()
);
alter table user_keys enable row level security;
create policy "Eigenen Schluessel lesen" on user_keys for select to authenticated using (auth.uid() = user_id);
create policy "Eigenen Schluessel anlegen" on user_keys for insert to authenticated with check (auth.uid() = user_id);
create policy "Eigenen Schluessel aendern" on user_keys for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Eigenen Schluessel loeschen" on user_keys for delete to authenticated using (auth.uid() = user_id);

-- Geteilte Boards und ihre Mitglieder
create table shared_boards (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  payload text not null,
  version integer not null default 1,
  updated_at timestamptz not null default now()
);
create table board_members (
  board_id uuid not null references shared_boards(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'editor' check (role in ('owner','editor')),
  wrapped_key text not null,
  wrapper_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (board_id, user_id)
);
alter table shared_boards enable row level security;
alter table board_members enable row level security;

create function is_board_member(b uuid) returns boolean
  language sql security definer stable set search_path = public
  as $$ select exists (select 1 from board_members where board_id = b and user_id = auth.uid()) $$;
create function is_board_owner(b uuid) returns boolean
  language sql security definer stable set search_path = public
  as $$ select exists (select 1 from board_members where board_id = b and user_id = auth.uid() and role = 'owner') $$;

create policy "Board lesen" on shared_boards for select to authenticated
  using (is_board_member(id) or owner_id = auth.uid());
create policy "Board anlegen" on shared_boards for insert to authenticated
  with check (owner_id = auth.uid());
create policy "Board aendern" on shared_boards for update to authenticated
  using (is_board_member(id)) with check (is_board_member(id));
create policy "Board loeschen" on shared_boards for delete to authenticated
  using (owner_id = auth.uid());

create policy "Mitglieder sehen" on board_members for select to authenticated
  using (user_id = auth.uid() or is_board_member(board_id));
create policy "Mitglieder hinzufuegen" on board_members for insert to authenticated
  with check (is_board_owner(board_id) or (user_id = auth.uid() and role = 'owner'
    and exists (select 1 from shared_boards b where b.id = board_id and b.owner_id = auth.uid())));
create policy "Mitglieder aendern" on board_members for update to authenticated
  using (is_board_owner(board_id)) with check (is_board_owner(board_id));
create policy "Entfernen oder verlassen" on board_members for delete to authenticated
  using (is_board_owner(board_id) or user_id = auth.uid());

-- Rechte (neue Supabase-Projekte vergeben sie nicht mehr automatisch).
-- Bei shared_boards sind nur Inhalt, Version und Zeitstempel änderbar, nicht der Eigentümer.
grant select, insert, delete on shared_boards to authenticated;
grant update (payload, version, updated_at) on shared_boards to authenticated;
grant select, insert, update, delete on board_members to authenticated;
grant select, insert, update, delete on user_keys to authenticated;
```

**So ist es abgesichert:**
- Jedes Board hat einen zufälligen AES-256-Schlüssel. Pro Mitglied wird er per ECDH (P-256) für dessen öffentlichen
  Schlüssel verpackt; nur diese Person kann ihn öffnen. Der private Schlüssel liegt nur mit der eigenen Passphrase
  verschlüsselt in Supabase (`user_keys`).
- Wird jemand entfernt, bekommt das Board einen **neuen Schlüssel** (für die Verbleibenden neu verpackt).
- **Gleichzeitiges Arbeiten:** Änderungen werden Task für Task zusammengeführt (Drei-Wege-Abgleich mit Versionsprüfung).
  Bearbeiten zwei Personen verschiedene Tasks, bleiben beide Änderungen. Am selben Task gewinnt der neuere Stand,
  Notizen, Verlauf und Zeitsitzungen werden vereinigt. Löschen gewinnt nur, wenn niemand den Task inzwischen geändert hat.
- **Einschränkung:** Welcher öffentliche Schlüssel zu welcher Person gehört, liefert Supabase selbst. Wer das
  Supabase-Projekt kontrolliert, könnte theoretisch einen falschen Schlüssel unterschieben. Für ein Team im selben
  Unternehmen ist das ein vertretbarer Kompromiss.
- **Passphrase vergessen:** Dann gehen auch die Schlüssel für geteilte Boards verloren; andere Mitglieder behalten ihren
  Zugriff und können dich nach dem Neustart erneut hinzufügen.
- Geteilte Boards benötigen den eingerichteten Cloud-Speicher (Passphrase) und die Tabellen oben.

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
zwischen PC und Handy: siehe **☁️ Cloud-Speicher** oben – damit läuft es im Hintergrund, ganz ohne
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
- **📅 Kalender** (Board-Ansicht-Auswahl): die nächsten 7 Tage als Spalten, pro Tag chronologisch
  gemischt geplante Tasks und tatsächlich erfasste Zeitsitzungen – zeigt auf einen Blick Planung
  *und* wo bereits wirklich Zeit rapportiert wurde. Eine Spalte "Nicht geplant" sammelt offene
  Tasks ohne Zeit; per Drag & Drop auf einen Tag ziehen plant sie ein (Uhrzeit direkt in der
  Ansicht per Zeit-Feld anpassbar, ohne den Task zu öffnen). Im Task-Fenster selbst legt das Feld
  "📅 Geplant für" die Zeit fest; danach lässt sich der Termin per **📤 Outlook-Termin (.ics)**
  herunterladen und direkt in Outlook eintragen.
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
- Der Cloud-Speicher legt automatisch täglich einen **Snapshot** (Tabelle `board_snapshots`) ab (letzte 7 Tage) –
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
