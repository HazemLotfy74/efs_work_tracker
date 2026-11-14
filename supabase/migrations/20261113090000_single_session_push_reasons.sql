-- Single active session, push hardening, mandatory correction decision reasons.
--
-- NOT APPLIED AUTOMATICALLY. Review, dry-run (supabase/verify/20261113_dry_run.sql),
-- then run in the SQL editor. Rollback: supabase/backups/20261113_rollback.sql.
--
-- Additive only: no table is dropped, no row is changed or deleted by this file.
-- (Afterwards, a sign-in removes that account's OLDER auth sessions; that is the feature.)
begin;

-- ───────────────────────── 1. Single active session ─────────────────────────
-- The active session of an account is its most recently created Auth session.
-- auth.sessions is written only by Supabase Auth, and the session id comes from
-- the signed access token, so the phone cannot choose which session is active.
create function private.session_is_current() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from auth.sessions mine
    where mine.id = (auth.jwt() ->> 'session_id')::uuid
      and mine.user_id = auth.uid()
      and not exists (
        select 1 from auth.sessions newer
        where newer.user_id = mine.user_id
          and (newer.created_at, newer.id) > (mine.created_at, mine.id)
      )
  );
$$;
-- Called only from the SECURITY DEFINER helpers below, never by a client role.
revoke all on function private.session_is_current() from public, anon, authenticated;

-- Every RLS policy goes through one of these five helpers, and every write
-- function through require_actor: adding the check here covers all of them.
create or replace function private.is_active() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_active = true and must_change_password = false
  ) and private.session_is_current();
$$;

create or replace function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
      and is_active = true and must_change_password = false
  ) and private.session_is_current();
$$;

create or replace function private.can_review_attendance_corrections() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'employee' and p.is_active
      and not p.must_change_password and p.can_review_attendance_corrections)
    and private.session_is_current();
$$;

create or replace function private.can_review_expense_advances() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'employee' and p.is_active
      and not p.must_change_password and p.can_review_expense_advances)
    and private.session_is_current();
$$;

create or replace function private.can_review_overtime() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'employee' and p.is_active
      and not p.must_change_password and p.can_review_overtime)
    and private.session_is_current();
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

  if not private.session_is_current() then
    raise exception 'This session is no longer active' using errcode = '42501';
  end if;

  return account.id;
end;
$$;

-- Tells the app whether this phone still holds the active session, and, when it
-- does, ends the account's older sessions (their refresh tokens go with them,
-- and so do their push registrations: push_devices.session_id cascades).
-- A phone that lost the session gets no account data.
create or replace function public.get_account_status() returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  account public.profiles%rowtype;
  v_session uuid := (auth.jwt() ->> 'session_id')::uuid;
begin
  select * into account from public.profiles where id = auth.uid();

  if account.id is null then
    raise exception 'Account has not been provisioned' using errcode = '42501';
  end if;

  if not private.session_is_current() then
    return jsonb_build_object(
      'id', account.id,
      'is_active', false,
      'must_change_password', true,
      'session_state', case when exists (
          select 1 from auth.sessions s where s.user_id = account.id
        ) then 'replaced' else 'ended' end
    );
  end if;

  delete from auth.sessions s where s.user_id = account.id and s.id <> v_session;

  return jsonb_build_object(
    'id', account.id,
    'full_name', account.full_name,
    'username', account.username,
    'employee_code', account.employee_code,
    'role', account.role,
    'is_active', account.is_active,
    'must_change_password', account.must_change_password,
    'session_state', 'current'
  );
end;
$$;

-- ───────────────────────────── 2. Push delivery ─────────────────────────────
-- Only the active session may register a phone.
create or replace function public.register_push_device(p_installation_id text, p_token text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  session uuid := (auth.jwt() ->> 'session_id')::uuid;
begin
  if not private.session_is_current() or not exists (
    select 1 from public.profiles p
    where p.id = actor and p.is_active and not p.must_change_password
  ) then
    raise exception 'Session unavailable' using errcode = '42501';
  end if;
  delete from private.push_devices d where d.token = p_token and d.installation_id <> p_installation_id;
  -- One account, one phone: registrations left by the account's other sessions go.
  delete from private.push_devices d where d.user_id = actor and d.session_id <> session;
  insert into private.push_devices values (p_installation_id, actor, session, p_token)
  on conflict (installation_id) do update
    set user_id = excluded.user_id, session_id = excluded.session_id, token = excluded.token;
end;
$$;

-- The sender now also learns what the notification is about (for its text) and
-- never sends to a phone whose session is no longer the account's newest.
drop function public.claim_push_deliveries();
create function public.claim_push_deliveries()
returns table (id uuid, lease uuid, token text, attempts integer, request_kind text, event_type text)
language sql security definer set search_path = '' as $$
  with expired as (
    delete from private.push_deliveries j where j.expires_at <= now()
      or (j.attempts >= 8 and j.available_at <= now())
  ), ready as (
    select j.id, d.token, n.request_kind, n.event_type from private.push_deliveries j
    join private.push_devices d on d.installation_id = j.installation_id
    join auth.sessions s on s.id = d.session_id and s.user_id = d.user_id
    join public.notifications n on n.id = j.notification_id and n.recipient_id = d.user_id
    join public.profiles p on p.id = d.user_id and p.is_active and not p.must_change_password
    where j.available_at <= now() and j.expires_at > now() and j.attempts < 8
      and n.read_at is null
      and not exists (
        select 1 from auth.sessions newer
        where newer.user_id = s.user_id and (newer.created_at, newer.id) > (s.created_at, s.id)
      )
    order by j.available_at, j.id limit 10
    for update of j skip locked
  )
  update private.push_deliveries j set
    attempts = j.attempts + 1, lease = gen_random_uuid(), available_at = now() + interval '5 minutes'
  from ready where j.id = ready.id
  returning j.id, j.lease, ready.token, j.attempts, ready.request_kind, ready.event_type;
$$;
revoke all on function public.claim_push_deliveries() from public, anon, authenticated, service_role;
grant execute on function public.claim_push_deliveries() to service_role;

-- Wake the sender as soon as a notification is queued instead of waiting for
-- the next minute of the cron job (which stays as the retry path). pg_net sends
-- after commit; a failure here must never undo the business change.
create or replace function private.enqueue_notification_push() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into private.push_deliveries (notification_id, installation_id)
  select new.id, d.installation_id from private.push_devices d
  where d.user_id = new.recipient_id;
  if found then
    begin
      perform private.invoke_push_scheduler();
    exception when others then
      null;
    end;
  end if;
  return new;
end;
$$;

-- ─────────────────── 3. Mandatory correction decision reason ───────────────────
-- A reason must contain visible text (btrim alone lets a note of only line
-- breaks or tabs through). Enforced on the table, so review_request, review_assigned_attendance_correction
-- and any future path all obey it. NOT VALID keeps the one historical decision
-- that has no note; every new decision is checked.
alter table public.attendance_correction_requests
  add constraint correction_decision_reason
  check (status = 'pending' or (review_note is not null and review_note ~ '[^[:space:]]'
    and length(review_note) <= 2000)) not valid;

-- Same rule with a readable error, raised before the constraint.
create function private.require_correction_decision_reason() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.status in ('approved', 'rejected') and old.status = 'pending'
     and (new.review_note is null or new.review_note !~ '[^[:space:]]' or length(new.review_note) > 2000) then
    raise exception 'A decision reason of 1-2000 characters is required'
      using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke all on function private.require_correction_decision_reason() from public, anon, authenticated;
create trigger require_correction_decision_reason
  before update on public.attendance_correction_requests
  for each row execute function private.require_correction_decision_reason();

commit;
