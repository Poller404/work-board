-- =========================================================
-- Work Board: Profile gegen Verwechslung absichern
-- Einmalig im Supabase SQL-Editor ausführen. Es werden KEINE Daten gelöscht.
--
-- Behebt (Sicherheitsprüfung vom 15.10.2026):
--  * Jede angemeldete Person konnte über die API in ihrem eigenen Profil eine fremde E-Mail-Adresse
--    eintragen. Beim Hinzufügen zu einem geteilten Board hätte sie sich so als jemand anderes ausgeben
--    und den Board-Schlüssel bekommen können.
-- Neu: Die E-Mail im Profil wird immer aus dem Login (auth.users) übernommen, der Anzeigename gekürzt.
-- =========================================================

create or replace function public.profiles_enforce_email() returns trigger
  language plpgsql security definer set search_path = public, auth
as $$
begin
  new.email := (select u.email from auth.users u where u.id = new.id);
  new.display_name := left(coalesce(nullif(trim(new.display_name), ''), split_part(new.email, '@', 1)), 60);
  return new;
end $$;
revoke all on function public.profiles_enforce_email() from public, anon, authenticated;

drop trigger if exists profiles_enforce_email on public.profiles;
create trigger profiles_enforce_email before insert or update on public.profiles
  for each row execute function public.profiles_enforce_email();

-- Bestehende Profile einmal auf die echte Login-Adresse setzen
update public.profiles p set email = u.email from auth.users u where u.id = p.id and p.email is distinct from u.email;
