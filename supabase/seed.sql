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
),
(
  'bbbbbbbb-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'doraemon@joke.com',
  crypt('11111111A', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"first_name":"哆啦a夢","last_name":"野比"}',
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

-- Seed Toy Bear product listed by doraemon seller
-- profiles row is auto-created by handle_new_user trigger, so user_id = auth user id
INSERT INTO public.products (
  id,
  user_id,
  product_name,
  price,
  color,
  leather,
  year_purchased,
  stamp,
  location,
  description,
  created_at,
  updated_at
) VALUES (
  '8c492cae-c61e-4d45-a03a-af4c88e1da34',
  'bbbbbbbb-0000-0000-0000-000000000001',
  'Toy Bear',
  199.00,
  'white',
  'Cotton',
  2025,
  '12345 52310421',
  'Mountain View, CA, USA',
  'I bought this lovely toy bear last year but now my 3-year-old boy has 20+ toys so I need to clean up a bit!',
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

-- Seed product image for Toy Bear
INSERT INTO public.product_images (
  product_id,
  image_url
) VALUES (
  '8c492cae-c61e-4d45-a03a-af4c88e1da34',
  'http://127.0.0.1:54321/storage/v1/object/public/product-images/bbbbbbbb-0000-0000-0000-000000000001/toy_bear.png'
)
ON CONFLICT DO NOTHING;
