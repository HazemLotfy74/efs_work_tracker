-- Live in-app notifications: lets Supabase Realtime tell a signed-in phone that
-- its own rows in public.notifications changed (InboxRepository.watch).
--
-- NOT APPLIED. Safe to run more than once. It adds a table to a publication and
-- changes no data, no policy and no function. Realtime checks the table's
-- existing row-level security for every listener, so an account is only told
-- about notifications addressed to it.
-- Undo: alter publication supabase_realtime drop table public.notifications;
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
