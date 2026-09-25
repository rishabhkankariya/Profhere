create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  full_name text not null,
  role text not null check (role in ('student', 'faculty')),
  auth_id uuid unique,
  created_at timestamptz not null default now()
);

create table if not exists public.faculty (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  name text not null,
  cabin text not null,
  department text,
  created_at timestamptz not null default now()
);

create table if not exists public.timetable (
  id uuid primary key default gen_random_uuid(),
  faculty_id uuid not null references public.faculty(id) on delete cascade,
  day_of_week text not null check (
    day_of_week in (
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    )
  ),
  start_time time not null,
  end_time time not null,
  subject text not null,
  created_at timestamptz not null default now(),
  constraint timetable_time_range_check check (end_time > start_time)
);

create index if not exists idx_users_role
on public.users(role);

create index if not exists idx_faculty_user_id
on public.faculty(user_id);

create index if not exists idx_timetable_faculty_day
on public.timetable(faculty_id, day_of_week);

create index if not exists idx_timetable_time_range
on public.timetable(start_time, end_time);

comment on table public.timetable is
'Faculty availability must be computed from timetable slots. If the current time falls inside a slot, faculty is BUSY; otherwise AVAILABLE.';
