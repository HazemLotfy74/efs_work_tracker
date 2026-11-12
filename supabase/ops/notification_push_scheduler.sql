begin;
create extension if not exists pg_net;

-- Store the signing secret in Vault and send only short-lived tokens through pg_net.
select vault.create_secret(
  replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  'push_scheduler_token'
)
where not exists (select 1 from vault.secrets where name = 'push_scheduler_token');

create function private.push_scheduler_token(p_secret text, p_minute bigint)
returns text language sql immutable set search_path = '' as $$
  select encode(sha256(convert_to(p_minute::text || ':' || p_secret, 'UTF8')), 'hex');
$$;
revoke all on function private.push_scheduler_token(text, bigint) from public, anon, authenticated, service_role;

create function public.verify_push_scheduler_token(p_token text)
returns boolean language sql security definer set search_path = '' as $$
  select exists (
    select 1 from vault.decrypted_secrets
    cross join (select floor(extract(epoch from now()) / 60)::bigint as minute) t
    where name = 'push_scheduler_token'
      and p_token in (private.push_scheduler_token(decrypted_secret, t.minute),
                      private.push_scheduler_token(decrypted_secret, t.minute - 1))
  );
$$;
revoke all on function public.verify_push_scheduler_token(text) from public, anon, authenticated, service_role;
grant execute on function public.verify_push_scheduler_token(text) to service_role;

create function private.invoke_push_scheduler()
returns bigint language sql set search_path = '' as $$
  select net.http_post(
    url := 'https://fotxyzooanysjthovpfz.supabase.co/functions/v1/send-notification-push',
    headers := jsonb_build_object('X-Push-Scheduler-Token',
      private.push_scheduler_token(decrypted_secret, floor(extract(epoch from now()) / 60)::bigint)),
    timeout_milliseconds := 45000
  )
  from vault.decrypted_secrets where name = 'push_scheduler_token';
$$;
revoke all on function private.invoke_push_scheduler() from public, anon, authenticated, service_role;

select cron.schedule('send-notification-push', '* * * * *', 'select private.invoke_push_scheduler();');
commit;
