insert into public.users (id, email, full_name, role)
values
  ('00000000-0000-0000-0000-000000000000', 'admin@profhere.edu', 'System Administrator', 'admin'),
  ('11111111-1111-1111-1111-111111111111', 'meera.sharma@profhere.edu', 'Dr. Meera Sharma', 'faculty'),
  ('22222222-2222-2222-2222-222222222222', 'arjun.iyer@profhere.edu', 'Prof. Arjun Iyer', 'faculty'),
  ('33333333-3333-3333-3333-333333333333', 'student1@profhere.edu', 'Riya Patel', 'student')
on conflict (id) do nothing;

insert into public.faculty (id, user_id, name, cabin, department)
values
  ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'Dr. Meera Sharma', 'C-204', 'Computer Science'),
  ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '22222222-2222-2222-2222-222222222222', 'Prof. Arjun Iyer', 'B-112', 'Information Technology')
on conflict (id) do nothing;

insert into public.timetable (faculty_id, day_of_week, start_time, end_time, subject)
values
  ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'Monday', '09:00', '10:00', 'Data Structures'),
  ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'Wednesday', '11:00', '12:00', 'Algorithms'),
  ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'Tuesday', '10:00', '11:00', 'Database Systems'),
  ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'Thursday', '14:00', '15:00', 'Operating Systems')
on conflict do nothing;
