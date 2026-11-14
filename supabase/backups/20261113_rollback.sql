-- Undoes migrations/20261113090000_single_session_push_reasons.sql.
-- Function bodies below are the live definitions read on 2026-11-12, before the change.
-- No data is touched. Decision reasons already written stay in review_note.
begin;

drop trigger if exists require_correction_decision_reason on public.attendance_correction_requests;
drop function if exists private.require_correction_decision_reason();
alter table public.attendance_correction_requests drop constraint if exists correction_decision_reason;

create or replace function private.is_active() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_active = true and must_change_password = false
  );
$$;

create or replace function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
      and is_active = true and must_change_password = false
  );
$$;

create or replace function private.can_review_attendance_corrections() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p
  where p.id=auth.uid() and p.role='employee' and p.is_active
  and not p.must_change_password and p.can_review_attendance_corrections);
$$;

create or replace function private.can_review_expense_advances() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p
  where p.id=auth.uid() and p.role='employee' and p.is_active
  and not p.must_change_password and p.can_review_expense_advances);
$$;

create or replace function private.can_review_overtime() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p
  where p.id=auth.uid() and p.role='employee' and p.is_active
  and not p.must_change_password and p.can_review_overtime);
$$;

create or replace function private.require_actor(p_admin boolean default false)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  account public.profiles%rowtype;
begin
  if p_admin is null then
    raise exception 'Authorization mode is required' using errcode = '22023';
  end if;
  select * into account from public.profiles where id = auth.uid() for share;
  if account.id is null
     or account.is_active is distinct from true
     or account.must_change_password is distinct from false
     or (p_admin and account.role <> 'admin') then
    raise exception 'An active, password-ready authorized account is required'
      using errcode = '42501';
  end if;
  return account.id;
end;
$$;

create or replace function public.get_account_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  account public.profiles%rowtype;
begin
  select * into account from public.profiles where id = auth.uid();
  if account.id is null then
    raise exception 'Account has not been provisioned' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'id', account.id,
    'full_name', account.full_name,
    'username', account.username,
    'employee_code', account.employee_code,
    'role', account.role,
    'is_active', account.is_active,
    'must_change_password', account.must_change_password
  );
end;
$$;

create or replace function public.register_push_device(p_installation_id text, p_token text)
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

drop function public.claim_push_deliveries();
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
revoke all on function public.claim_push_deliveries() from public, anon, authenticated, service_role;
grant execute on function public.claim_push_deliveries() to service_role;

create or replace function private.enqueue_notification_push() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into private.push_deliveries (notification_id, installation_id)
  select new.id, d.installation_id from private.push_devices d
  where d.user_id = new.recipient_id;
  return new;
end;
$$;

drop function if exists private.session_is_current();
commit;
