-- Apply after the existing inbox migration. Schedule the sender only after configuring Firebase.
begin;
create table private.push_devices (
  installation_id text primary key check (installation_id ~ '^[a-f0-9]{32}$'),
  user_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references auth.sessions(id) on delete cascade,
  token text not null unique check (length(token) between 1 and 4096)
);
alter table private.push_devices enable row level security;

create table private.push_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  installation_id text not null references private.push_devices(installation_id) on delete cascade,
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  lease uuid,
  unique (notification_id, installation_id)
);
alter table private.push_deliveries enable row level security;
create index push_deliveries_ready on private.push_deliveries (available_at, id);
create index push_devices_recipient on private.push_devices (user_id);

create function public.register_push_device(p_installation_id text, p_token text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  session uuid := (auth.jwt()->>'session_id')::uuid;
begin
  if not exists (
    select 1 from auth.sessions s
    join public.profiles p on p.id = s.user_id
    where s.id = session and s.user_id = actor and p.is_active and not p.must_change_password
  ) then
    raise exception 'Session unavailable' using errcode = '42501';
  end if;
  delete from private.push_devices d where d.token = p_token and d.installation_id <> p_installation_id;
  insert into private.push_devices values (p_installation_id, actor, session, p_token)
  on conflict (installation_id) do update
    set user_id = excluded.user_id, session_id = excluded.session_id, token = excluded.token;
end;
$$;

create function public.unregister_push_device(p_installation_id text)
returns void language sql security definer set search_path = '' as $$
  delete from private.push_devices d
  where d.installation_id = p_installation_id and d.user_id = auth.uid()
    and d.session_id = (auth.jwt()->>'session_id')::uuid;
$$;

create function private.enqueue_notification_push() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into private.push_deliveries (notification_id, installation_id)
  select new.id, d.installation_id from private.push_devices d
  where d.user_id = new.recipient_id;
  return new;
end;
$$;
create trigger enqueue_notification_push after insert on public.notifications
for each row execute function private.enqueue_notification_push();

create function public.claim_push_deliveries()
returns table (id uuid, lease uuid, token text, attempts integer)
language sql security definer set search_path = '' as $$
  with expired as (
    delete from private.push_deliveries j where j.expires_at <= now()
      or (j.attempts >= 8 and j.available_at <= now())
  ), ready as (
    select j.id, d.token from private.push_deliveries j
    join private.push_devices d on d.installation_id = j.installation_id
    join public.notifications n on n.id = j.notification_id and n.recipient_id = d.user_id
    join public.profiles p on p.id = d.user_id and p.is_active and not p.must_change_password
    where j.available_at <= now() and j.expires_at > now() and j.attempts < 8
      and n.read_at is null
    order by j.available_at, j.id limit 10
    for update of j skip locked
  )
  update private.push_deliveries j set
    attempts = j.attempts + 1, lease = gen_random_uuid(), available_at = now() + interval '5 minutes'
  from ready where j.id = ready.id returning j.id, j.lease, ready.token, j.attempts;
$$;

create function public.finish_push_delivery(p_id uuid, p_lease uuid, p_retry_seconds integer, p_invalid_token text)
returns void language plpgsql security definer set search_path = '' as $$
declare device text;
begin
  if p_retry_seconds is not null then
    update private.push_deliveries j set lease = null,
      available_at = now() + make_interval(secs => greatest(60, least(p_retry_seconds, 86400)))
    where j.id = p_id and j.lease = p_lease;
  else
    delete from private.push_deliveries j where j.id = p_id and j.lease = p_lease
    returning j.installation_id into device;
    if p_invalid_token is not null then
      delete from private.push_devices d where d.installation_id = device and d.token = p_invalid_token;
    end if;
  end if;
end;
$$;

revoke all on function private.enqueue_notification_push() from public, anon, authenticated;
revoke all on function public.register_push_device(text, text), public.unregister_push_device(text)
  from public, anon, authenticated, service_role;
grant execute on function public.register_push_device(text, text), public.unregister_push_device(text) to authenticated;
revoke all on function public.claim_push_deliveries(), public.finish_push_delivery(uuid, uuid, integer, text)
  from public, anon, authenticated, service_role;
grant execute on function public.claim_push_deliveries(), public.finish_push_delivery(uuid, uuid, integer, text) to service_role;
commit;

