-- Seed test users directly into auth.users.
-- The trigger handle_new_user auto-creates the matching profiles row.
-- Password for all test users: Test1234!

INSERT INTO auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES
(
  'aaaaaaaa-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'user001@gmail.com',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"first_name":"user001","last_name":"Lai"}',
  now(),
  now()
),
(
  'aaaaaaaa-0000-0000-0000-000000000002',
  'authenticated',
  'authenticated',
  'user002@gmail.com',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"first_name":"user002","last_name":"Chen"}',
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;
