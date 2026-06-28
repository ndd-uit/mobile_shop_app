-- Admin policies for Daisy Admin.
-- Run this in Supabase SQL Editor after schema.sql.
-- To grant the first admin, create a separate admin user in Supabase Auth first.
-- Recommended email example: admin@daisyshop.app
-- Then run:
--
-- insert into public.admin_users (user_id, role)
-- select id, 'admin'
-- from auth.users
-- where email = 'admin@daisyshop.app'
-- on conflict (user_id) do update set role = excluded.role, is_active = true;

alter table public.products
  add column if not exists image_urls text[] not null default '{}';

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin', 'manager', 'staff')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

-- Cleanup older recursive policies before recreating role checks.
drop policy if exists "admins read admin users" on public.admin_users;
drop policy if exists "admin users read own role" on public.admin_users;
drop policy if exists "super admins manage admin users" on public.admin_users;

create table if not exists public.categories (
  id text primary key,
  name text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;

insert into public.categories (id, name, sort_order)
values
  ('dress', 'Váy', 10),
  ('shirt', 'Áo', 20),
  ('pants', 'Quần', 30),
  ('accessory', 'Phụ kiện', 40),
  ('shoes', 'Giày dép', 50)
on conflict (id) do update set
  name = excluded.name,
  sort_order = excluded.sort_order,
  updated_at = now();

update public.products
set image_urls = array[image_url]
where image_url <> ''
  and coalesce(array_length(image_urls, 1), 0) = 0;

create or replace function public.is_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = auth.uid()
      and au.is_active = true
      and au.role in ('admin', 'manager')
  )
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = auth.uid()
      and au.is_active = true
      and au.role = 'admin'
  )
$$;

drop policy if exists "admins read all products" on public.products;
drop policy if exists "admins insert products" on public.products;
drop policy if exists "admins update products" on public.products;
drop policy if exists "admins delete products" on public.products;
drop policy if exists "categories are publicly readable" on public.categories;
drop policy if exists "admins manage categories" on public.categories;
drop policy if exists "admins manage vouchers" on public.vouchers;
drop policy if exists "admins read all orders" on public.orders;
drop policy if exists "admins update orders" on public.orders;
drop policy if exists "admins read all order items" on public.order_items;

create policy "admin users read own role" on public.admin_users
  for select to authenticated
  using (auth.uid() = user_id);

create policy "admins read all products" on public.products
  for select to authenticated
  using (public.is_admin());

create policy "admins insert products" on public.products
  for insert to authenticated
  with check (public.is_admin());

create policy "admins update products" on public.products
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "admins delete products" on public.products
  for delete to authenticated
  using (public.is_admin());

create policy "categories are publicly readable" on public.categories
  for select using (is_active = true);

create policy "admins manage categories" on public.categories
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "admins manage vouchers" on public.vouchers
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "admins read all orders" on public.orders
  for select to authenticated
  using (public.is_admin());

create policy "admins update orders" on public.orders
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "admins read all order items" on public.order_items
  for select to authenticated
  using (public.is_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "product images are publicly readable" on storage.objects;
drop policy if exists "admins upload product images" on storage.objects;
drop policy if exists "admins update product images" on storage.objects;
drop policy if exists "admins delete product images" on storage.objects;

create policy "product images are publicly readable" on storage.objects
  for select using (bucket_id = 'product-images');

create policy "admins upload product images" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'product-images'
    and public.is_admin()
  );

create policy "admins update product images" on storage.objects
  for update to authenticated using (
    bucket_id = 'product-images'
    and public.is_admin()
  ) with check (
    bucket_id = 'product-images'
    and public.is_admin()
  );

create policy "admins delete product images" on storage.objects
  for delete to authenticated using (
    bucket_id = 'product-images'
    and public.is_admin()
  );

notify pgrst, 'reload schema';
