-- StudySync audit and device-isolation fixes.
-- Safe to re-run.

begin;

alter table public.study_sessions
  add column if not exists chapter text,
  add column if not exists last_activity_at timestamptz,
  add column if not exists missed_checkins integer,
  add column if not exists device_id uuid;

update public.study_sessions
set last_activity_at = coalesce(last_activity_at, end_time, start_time, created_at, now())
where last_activity_at is null;

update public.study_sessions
set missed_checkins = 0
where missed_checkins is null;

update public.study_sessions
set device_id = gen_random_uuid()
where device_id is null;

alter table public.study_sessions
  alter column last_activity_at set default now(),
  alter column missed_checkins set default 0,
  alter column missed_checkins set not null,
  alter column device_id set default gen_random_uuid(),
  alter column device_id set not null;

drop index if exists public.idx_one_active_session_per_user;

create unique index if not exists idx_one_active_session_per_user_device
  on public.study_sessions (user_id, device_id)
  where is_active = true;

create or replace function public.start_session_atomic(
  p_room_id uuid,
  p_subject text default null,
  p_chapter text default null,
  p_device_id uuid default null
)
returns public.study_sessions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.study_sessions;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_device_id is null then
    raise exception 'device_id is required';
  end if;

  insert into public.study_sessions (
    user_id,
    room_id,
    subject,
    chapter,
    device_id,
    start_time,
    end_time,
    is_active,
    created_at,
    last_activity_at,
    missed_checkins
  )
  values (
    auth.uid(),
    p_room_id,
    p_subject,
    p_chapter,
    p_device_id,
    now(),
    null,
    true,
    now(),
    now(),
    0
  )
  on conflict (user_id, device_id) where (is_active = true)
  do nothing;

  select *
  into v_session
  from public.study_sessions
  where user_id = auth.uid()
    and device_id = p_device_id
    and is_active = true
  order by created_at desc
  limit 1;

  return v_session;
end;
$$;

commit;
