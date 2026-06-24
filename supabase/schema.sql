-- Daisy Shop initial schema. Run this once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  phone_number text not null default '',
  avatar_url text,
  default_address_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  name text not null,
  price integer not null check (price >= 0),
  old_price integer check (old_price is null or old_price >= price),
  category text not null,
  image_url text not null default '',
  description text not null default '',
  rating numeric(2,1) not null default 0 check (rating between 0 and 5),
  stock integer not null default 0 check (stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shipping_addresses (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text not null,
  address text not null,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.profiles
    add constraint profiles_default_address_fk
    foreign key (default_address_id)
    references public.shipping_addresses(id)
    on delete set null;
exception when duplicate_object then null;
end $$;

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  size text not null default '',
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id, size)
);

create table if not exists public.vouchers (
  code text primary key,
  discount_type text not null check (discount_type in ('percent', 'fixed', 'shipping')),
  discount_value integer not null default 0 check (discount_value >= 0),
  max_discount integer,
  minimum_order integer not null default 0,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  usage_limit integer,
  used_count integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.orders (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete restrict,
  status text not null check (
    status in (
      'pending_payment', 'pending_confirmation', 'preparing', 'delivering',
      'completed', 'cancelled', 'return_requested', 'returned'
    )
  ),
  customer_name text not null,
  phone_number text not null,
  shipping_address text not null,
  payment_method text not null,
  payment_status text not null default 'unpaid' check (
    payment_status in ('unpaid', 'pending', 'paid', 'refunded')
  ),
  subtotal integer not null check (subtotal >= 0),
  shipping_fee integer not null default 0 check (shipping_fee >= 0),
  discount integer not null default 0 check (discount >= 0),
  voucher_code text references public.vouchers(code) on delete set null,
  cancellation_reason text,
  return_reason text,
  ordered_at timestamptz not null default now(),
  status_updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id text not null references public.orders(id) on delete cascade,
  product_id text references public.products(id) on delete set null,
  product_name text not null,
  unit_price integer not null check (unit_price >= 0),
  image_url text,
  quantity integer not null check (quantity > 0),
  size text
);

create table if not exists public.order_status_history (
  id bigint generated always as identity primary key,
  order_id text not null references public.orders(id) on delete cascade,
  status text not null,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  order_id text not null references public.orders(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null check (char_length(comment) >= 10),
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  unique (user_id, product_id, order_id)
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone_number)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone_number', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.shipping_addresses enable row level security;
alter table public.favorites enable row level security;
alter table public.cart_items enable row level security;
alter table public.vouchers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.reviews enable row level security;

drop policy if exists "products are publicly readable" on public.products;
drop policy if exists "active vouchers are readable" on public.vouchers;
drop policy if exists "users read own profile" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
drop policy if exists "users manage own addresses" on public.shipping_addresses;
drop policy if exists "users manage own favorites" on public.favorites;
drop policy if exists "users manage own cart" on public.cart_items;
drop policy if exists "users read own orders" on public.orders;
drop policy if exists "users create own orders" on public.orders;
drop policy if exists "users update own actionable orders" on public.orders;
drop policy if exists "users read own order items" on public.order_items;
drop policy if exists "users create own order items" on public.order_items;
drop policy if exists "users read own order history" on public.order_status_history;
drop policy if exists "reviews are publicly readable" on public.reviews;
drop policy if exists "users create own reviews" on public.reviews;
drop policy if exists "users update own reviews" on public.reviews;
drop policy if exists "users delete own reviews" on public.reviews;

create policy "products are publicly readable" on public.products
  for select using (is_active = true);
create policy "active vouchers are readable" on public.vouchers
  for select using (is_active = true and (expires_at is null or expires_at > now()));

create policy "users read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "users update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "users manage own addresses" on public.shipping_addresses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own favorites" on public.favorites
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own cart" on public.cart_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users read own orders" on public.orders
  for select using (auth.uid() = user_id);
create policy "users create own orders" on public.orders
  for insert with check (auth.uid() = user_id);
create policy "users update own actionable orders" on public.orders
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users read own order items" on public.order_items
  for select using (
    exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
  );
create policy "users create own order items" on public.order_items
  for insert with check (
    exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
  );
create policy "users read own order history" on public.order_status_history
  for select using (
    exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
  );

create policy "reviews are publicly readable" on public.reviews
  for select using (true);
create policy "users create own reviews" on public.reviews
  for insert with check (auth.uid() = user_id);
create policy "users update own reviews" on public.reviews
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users delete own reviews" on public.reviews
  for delete using (auth.uid() = user_id);

insert into public.vouchers (
  code, discount_type, discount_value, max_discount, minimum_order, expires_at
) values
  ('DAISY10', 'percent', 10, 100000, 0, now() + interval '1 year'),
  ('FREESHIP', 'shipping', 100, null, 0, now() + interval '1 year')
on conflict (code) do nothing;

insert into public.products (
  id, name, price, old_price, category, image_url, description, rating, stock
) values
  ('p01', 'Váy lụa Midi dáng xòe', 550000, null, 'Váy', '', 'Váy midi nhẹ nhàng và thanh lịch.', 4.9, 20),
  ('p02', 'Áo sơ mi lụa tơ tằm', 420000, null, 'Áo', '', 'Áo sơ mi mềm mại, dễ phối đồ.', 4.8, 25),
  ('p03', 'Dây chuyền mặt nụ hoa', 250000, null, 'Phụ kiện', '', 'Phụ kiện nữ tính tạo điểm nhấn.', 4.7, 30),
  ('p04', 'Quần short linen cạp cao', 380000, 450000, 'Quần', '', 'Quần short thoải mái cho mùa hè.', 4.6, 18)
on conflict (id) do nothing;

-- RPC: cập nhật rating trung bình sản phẩm (Security Definer để bypass RLS trên products)
create or replace function public.update_product_rating(p_product_id text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  avg_rating numeric;
begin
  select round(avg(rating)::numeric, 1)
  into avg_rating
  from public.reviews
  where product_id = p_product_id;

  update public.products
  set rating = coalesce(avg_rating, 0)
  where id = p_product_id;
end;
$$;

revoke execute on function public.update_product_rating(text) from public, anon;
grant execute on function public.update_product_rating(text) to authenticated;
notify pgrst, 'reload schema';

-- Backfill product images for databases created from an earlier schema version.
update public.products set image_url = 'https://lh3.googleusercontent.com/aida-public/AB6AXuDIBBuFHwWpIkQAvs0CCkebq7Tk_6QTRLLOQol8oJiZbAggUXZ8FJ9YTBVHFUehuM1OxY2QEv518sZ3wIHqaHBRmvXJdd69qCHzzi1s1JRBTI15KCxX-VAsvTWHgtNjmOAyBPqffGWSMKCzJEbTMwGReSL8esOOSMdFF8YpLd9zAL54A_0yD0KjHP5i8fGJvjnHObwmUMHqvhiLKHL3frZ-8jZyMVnGvRPJ8JVQDUoe-YpdiLdQdZVLJcxFJbl2qHbH0MVED8ZCbOw' where id = 'p01' and image_url = '';
update public.products set image_url = 'https://lh3.googleusercontent.com/aida-public/AB6AXuAv4c9a8iZW8rHyhcxDlzi8xYvxzeo-X1fVrGAgDeMqXNUUcAx2T-qsyVDgDiMgXL5HMnKm5hJyYlupGdwC8kXTox0y6Z37w5ShZsr-GVeK6hGgpXqG7zH1pQqeA3rvvpqCAwBsRKeTVt-JI_O_Rf3CoJ_dA4A35A5A2jh_CaJd6LRqhoqqSptQzDRQvZO1D5zxOjlfjL1_-uAvCkUTsCygr_FiyolMFcNR8cjdv-zZMkPokGdu-m4PIuwdxrHsCVcm9gIunO7pX7w' where id = 'p02' and image_url = '';
update public.products set image_url = 'https://lh3.googleusercontent.com/aida-public/AB6AXuD_BIi6HfTHtln_PiX14B1WRlpHAVK2pYtvoOYXlxv0usmhyCLhb3a1F7gKURubnCi0QK5u7OUxKchUkwb6DkiVa9nIp8e7nK8dx753UIOnIF_4jWqAoTXj1slz29tMJH-3L5ABufSebvmygZI8kWGauWxwZwTc1pznraN0wd1dW9-c6d5pqANWtUT9FB2mDtJNcV8MTsT1lfBthOEzSNXYGWXH18Ck-4f-DRkvV06-HTsakLYrKXgQZIhFDFc_lB0G5-4swjrbkEE' where id = 'p03' and image_url = '';
update public.products set image_url = 'https://lh3.googleusercontent.com/aida-public/AB6AXuApnpPr-XXeBwLhyIWErvJHg4JBgzYeqqhVm0wE9Sm-BvHu55WB2b5Nk9jcjpCRDdTo_fCTTMVBDcsQwL2ST7NBgsbjwtv0uUQDi4N1YumiYWidHBEOhjxrDDoalZ3IVugeFO7BahHREXRRuR2suGGHC6fsppoEot2v-QLgY-Bn6ThYiw1ca9I59nfAsrCEzLLPqbyJtfXXSQpUVsu4BXoSat-bj6fWvosf3gvFJYE-NTabaPigqdwlWr8BIIbVJG_3Tug7eW4DLLE' where id = 'p04' and image_url = '';
