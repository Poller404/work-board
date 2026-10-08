-- =========================================================
-- Work Board: Supabase aufräumen und absichern
-- Einmalig im Supabase SQL-Editor ausführen. Es werden KEINE Daten gelöscht.
--
-- Behebt (Stand der Prüfung vom 08.10.2026):
--  * Die App durfte keine Profile anlegen (profiles blieb leer) und geteilte Boards nicht speichern
--    (fehlendes UPDATE-Recht auf shared_boards); die Admin-Abfrage scheiterte (kein SELECT auf admins).
--  * Die Funktion delete_own_account() fehlte ("Mein Konto löschen" lief ins Leere).
--  * anon hatte überflüssige Rechte (REFERENCES/TRIGGER/TRUNCATE) und konnte die Hilfsfunktionen aufrufen.
--  * Policies riefen auth.uid() pro Zeile auf (Performance-Warnung), uneinheitliche Namen.
--  * Keine Grössenlimits und keine Indizes auf Fremdschlüsseln.
-- =========================================================

-- 1. Tabellenrechte: nur noch das, was die App wirklich braucht
revoke all on all tables in schema public from anon, authenticated;

grant select on public.admins to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.boards, public.board_snapshots, public.user_keys to authenticated;
grant select, insert, delete on public.shared_boards, public.board_members to authenticated;
grant update (payload, version, updated_at) on public.shared_boards to authenticated;
grant update (wrapped_key, wrapper_id) on public.board_members to authenticated;

alter default privileges for role postgres in schema public revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from anon, authenticated;

-- 2. Hilfsfunktionen der Policies: nicht mehr für anonyme Aufrufe
revoke execute on function public.is_board_member(uuid), public.is_board_owner(uuid) from public, anon;
grant execute on function public.is_board_member(uuid), public.is_board_owner(uuid) to authenticated;

-- 3. Konto löschen
create or replace function public.delete_own_account() returns void
  language plpgsql security definer set search_path = public, auth
as $$
begin
  if auth.uid() is null then raise exception 'NOT_SIGNED_IN'; end if;
  if exists (select 1 from public.shared_boards b where b.owner_id = auth.uid()
             and exists (select 1 from public.board_members m where m.board_id = b.id and m.user_id <> auth.uid())) then
    raise exception 'OWNS_SHARED_BOARDS';
  end if;
  delete from auth.users where id = auth.uid();
end $$;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- 4. Profil automatisch bei der Registrierung anlegen (und für bestehende Konten nachtragen)
create or replace function public.handle_new_user() returns trigger
  language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), split_part(new.email, '@', 1)), new.email)
  on conflict (id) do nothing;
  return new;
end $$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

insert into public.profiles (id, display_name, email)
select u.id, coalesce(nullif(u.raw_user_meta_data->>'display_name', ''), split_part(u.email, '@', 1)), u.email
from auth.users u
on conflict (id) do nothing;

-- 5. Policies neu, einheitlich benannt und mit (select auth.uid()) für bessere Performance
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public' and tablename <> 'admins' loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

create policy "Profile lesen" on public.profiles for select to authenticated using (true);
create policy "Eigenes Profil anlegen" on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy "Eigenes Profil aktualisieren" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "Eigenes Board lesen" on public.boards for select to authenticated using (user_id = (select auth.uid()));
create policy "Eigenes Board anlegen" on public.boards for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Eigenes Board aktualisieren" on public.boards for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Eigenes Board löschen" on public.boards for delete to authenticated using (user_id = (select auth.uid()));

create policy "Eigene Snapshots lesen" on public.board_snapshots for select to authenticated using (user_id = (select auth.uid()));
create policy "Eigene Snapshots anlegen" on public.board_snapshots for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Eigene Snapshots aktualisieren" on public.board_snapshots for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Eigene Snapshots löschen" on public.board_snapshots for delete to authenticated using (user_id = (select auth.uid()));

create policy "Eigenen Schlüssel lesen" on public.user_keys for select to authenticated using (user_id = (select auth.uid()));
create policy "Eigenen Schlüssel anlegen" on public.user_keys for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Eigenen Schlüssel ändern" on public.user_keys for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Eigenen Schlüssel löschen" on public.user_keys for delete to authenticated using (user_id = (select auth.uid()));

create policy "Board lesen" on public.shared_boards for select to authenticated using (public.is_board_member(id) or owner_id = (select auth.uid()));
create policy "Board anlegen" on public.shared_boards for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "Board ändern" on public.shared_boards for update to authenticated using (public.is_board_member(id)) with check (public.is_board_member(id));
create policy "Board löschen" on public.shared_boards for delete to authenticated using (owner_id = (select auth.uid()));

create policy "Mitglieder sehen" on public.board_members for select to authenticated using (user_id = (select auth.uid()) or public.is_board_member(board_id));
create policy "Mitglieder hinzufügen" on public.board_members for insert to authenticated with check (
  public.is_board_owner(board_id)
  or (user_id = (select auth.uid()) and role = 'owner'
      and exists (select 1 from public.shared_boards b where b.id = board_members.board_id and b.owner_id = (select auth.uid()))));
create policy "Mitglieder ändern" on public.board_members for update to authenticated using (public.is_board_owner(board_id)) with check (public.is_board_owner(board_id));
create policy "Entfernen oder verlassen" on public.board_members for delete to authenticated using (public.is_board_owner(board_id) or user_id = (select auth.uid()));

-- 6. Grössenlimits gegen Missbrauch (Chiffretext)
alter table public.boards add constraint boards_payload_size check (length(payload) < 8000000);
alter table public.shared_boards add constraint shared_boards_payload_size check (length(payload) < 8000000);
alter table public.board_snapshots add constraint board_snapshots_payload_size check (length(payload) < 8000000);
alter table public.user_keys add constraint user_keys_size check (length(private_key_enc) < 20000);
alter table public.profiles add constraint profiles_public_key_size check (public_key is null or length(public_key) < 2000);
alter table public.board_members add constraint board_members_wrapped_key_size check (length(wrapped_key) < 10000);

-- 7. Indizes für Fremdschlüssel
create index if not exists board_members_user_id_idx on public.board_members (user_id);
create index if not exists board_members_wrapper_id_idx on public.board_members (wrapper_id);
create index if not exists shared_boards_owner_id_idx on public.shared_boards (owner_id);
