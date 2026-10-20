-- Seite pro Task: Bilder der Whiteboard-Seiten (einmalig im Supabase SQL Editor ausführen).
-- "payload" enthält nur Chiffretext. Jedes Bild hat einen eigenen zufälligen Schlüssel,
-- der nur im (ebenfalls verschlüsselten) Task steht; Supabase kann die Bilder nicht lesen.
-- Voraussetzung: Tabellen und Funktionen der geteilten Boards (shared_boards, is_board_member).

create table if not exists task_files (
  id text primary key check (id ~ '^[A-Za-z0-9_-]{1,64}$'),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  board_id uuid references shared_boards(id) on delete cascade,
  payload text not null check (length(payload) < 20000000),
  created_at timestamptz not null default now()
);
alter table task_files enable row level security;

create policy "Seitenbilder lesen" on task_files for select to authenticated
  using (owner_id = auth.uid() or (board_id is not null and is_board_member(board_id)));
create policy "Seitenbilder anlegen" on task_files for insert to authenticated
  with check (owner_id = auth.uid() and (board_id is null or is_board_member(board_id)));
create policy "Seitenbilder loeschen" on task_files for delete to authenticated
  using (owner_id = auth.uid() or (board_id is not null and is_board_member(board_id)));

-- Kein Update: ein Bild wird nie geändert, nur angelegt oder gelöscht.
grant select, insert, delete on public.task_files to authenticated;
