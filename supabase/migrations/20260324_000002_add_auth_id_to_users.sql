alter table public.users
add column if not exists auth_id uuid unique;
