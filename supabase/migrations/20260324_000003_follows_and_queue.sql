create table if not exists public.follows (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.users(id) on delete cascade,
  faculty_id uuid references public.faculty(id) on delete cascade,
  created_at timestamptz default now(),
  unique(student_id, faculty_id)
);

create table if not exists public.queue (
  id uuid primary key default gen_random_uuid(),
  faculty_id uuid references public.faculty(id) on delete cascade,
  student_id uuid references public.users(id) on delete cascade,
  position int,
  status text check (status in ('waiting', 'called', 'completed')) default 'waiting',
  called_at timestamptz,
  created_at timestamptz default now()
);

create index if not exists idx_follows_student_faculty
on public.follows(student_id, faculty_id);

create index if not exists idx_queue_faculty_position
on public.queue(faculty_id, position);

create unique index if not exists idx_queue_active_student_faculty
on public.queue(faculty_id, student_id, status)
where status in ('waiting', 'called');
