alter table public.queue
add column if not exists called_at timestamptz;
