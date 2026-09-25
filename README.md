# ProfHere

Smart Campus Faculty Availability System built with Flutter, Riverpod, and Supabase.

## Supabase setup

Create a local `.env` file in the project root:

```bash
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
```

The app loads these values with `flutter_dotenv` before startup. Supabase initialization is wrapped in safe async startup logic, and the app still boots even if the `.env` file is empty or the backend is unavailable.

`SupabaseService.testConnection()` provides a simple connection check by reading one row from a table such as `profiles`.

## Profiles table

Authentication expects a `profiles` table in Supabase for storing the user role:

```sql
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  role text not null check (role in ('student', 'faculty'))
);
```

`AuthService` signs users up with email/password, stores the selected role in auth metadata, and upserts the same role into `public.profiles`.

## Faculty table

Faculty listing expects a `faculty` table:

```sql
create table if not exists public.faculty (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  name text not null,
  status text not null default 'Available',
  cabin text not null
);
```

Faculty records are listed in the app, and only the signed-in faculty member who owns a row can update that row's `status`.

## Queue table

Queue logic expects a `queue_entries` table:

```sql
create table if not exists public.queue_entries (
  id uuid primary key default gen_random_uuid(),
  faculty_id uuid not null references public.faculty (id) on delete cascade,
  student_id uuid not null references auth.users (id) on delete cascade,
  student_name text not null,
  position integer not null,
  created_at timestamptz not null default now(),
  unique (faculty_id, student_id)
);
```

Queue positions are assigned in the app using `max(position) + 1` per faculty.

## Follow table

Follow logic expects a `faculty_follows` table:

```sql
create table if not exists public.faculty_follows (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users (id) on delete cascade,
  faculty_id uuid not null references public.faculty (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (student_id, faculty_id)
);
```

Students can follow or unfollow faculty, and followed faculty can be fetched from the relation table.

## Core schema

The foundational schema for the timetable-driven availability model is stored in [20260324_000001_initial_profhere_schema.sql](C:/Profhere2/supabase/migrations/20260324_000001_initial_profhere_schema.sql).

It creates:

- `public.users`
- `public.faculty`
- `public.timetable`

For the auth mapping used by the app, make sure `public.users.auth_id` exists.
If your table was created before this field was added, run
[20260324_000002_add_auth_id_to_users.sql](C:/Profhere2/supabase/migrations/20260324_000002_add_auth_id_to_users.sql).

Important design rule:

- Faculty availability is not stored directly.
- Availability is computed from `public.timetable`.
- If the current time falls within a faculty timetable slot, the faculty member is `BUSY`; otherwise `AVAILABLE`.

To see data in the current app:

1. Run [20260324_000001_initial_profhere_schema.sql](C:/Profhere2/supabase/migrations/20260324_000001_initial_profhere_schema.sql) in Supabase SQL Editor.
2. Run [seed_profhere_demo.sql](C:/Profhere2/supabase/seed_profhere_demo.sql) in Supabase SQL Editor.
3. Refresh the Flutter app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
