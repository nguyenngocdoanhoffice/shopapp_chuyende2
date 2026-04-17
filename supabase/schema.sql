-- Run this file in Supabase SQL Editor.
-- It creates schema, constraints, trigger/functions, and RLS policies.

create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  phone text not null default '',
  address text not null default '',
  role text not null default 'user' check (role in ('user', 'admin')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id bigserial primary key,
  name text not null,
  description text not null default '',
  category text not null,
  price numeric(12,2) not null check (price >= 0),
  stock int not null default 0 check (stock >= 0),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.carts (
  id bigserial primary key,
  user_id uuid not null unique references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cart_items (
  id bigserial primary key,
  cart_id bigint not null references public.carts(id) on delete cascade,
  product_id bigint not null references public.products(id),
  quantity int not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cart_id, product_id)
);

create table if not exists public.coupons (
  id bigserial primary key,
  code text not null unique,
  discount_type text not null check (discount_type in ('percent', 'fixed')),
  discount_value numeric(12,2) not null check (discount_value > 0),
  min_order_amount numeric(12,2) not null default 0,
  max_discount numeric(12,2),
  start_at timestamptz not null,
  end_at timestamptz not null,
  is_active boolean not null default true,
  usage_limit int,
  used_count int not null default 0,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  check (end_at > start_at)
);

create table if not exists public.orders (
  id bigserial primary key,
  user_id uuid not null references public.users(id),
  coupon_id bigint references public.coupons(id),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'shipped', 'completed', 'cancelled')),
  payment_method text not null default 'cod',
  subtotal numeric(12,2) not null check (subtotal >= 0),
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
  shipping_fee numeric(12,2) not null default 0 check (shipping_fee >= 0),
  total_amount numeric(12,2) not null check (total_amount >= 0),
  shipping_address text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id bigserial primary key,
  order_id bigint not null references public.orders(id) on delete cascade,
  product_id bigint not null references public.products(id),
  quantity int not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  line_total numeric(12,2) not null check (line_total >= 0),
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create or replace function public.is_admin(uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.users where id = uid and role = 'admin'
  );
$$;

create or replace function public.increment_coupon_usage(coupon_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.coupons
  set used_count = used_count + 1
  where id = coupon_id;
end;
$$;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists trg_products_updated_at on public.products;
create trigger trg_products_updated_at
before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists trg_carts_updated_at on public.carts;
create trigger trg_carts_updated_at
before update on public.carts
for each row execute function public.set_updated_at();

drop trigger if exists trg_cart_items_updated_at on public.cart_items;
create trigger trg_cart_items_updated_at
before update on public.cart_items
for each row execute function public.set_updated_at();

drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

alter table public.users enable row level security;
alter table public.products enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.coupons enable row level security;

-- USERS
create policy "users_select_own_or_admin"
on public.users
for select
using (auth.uid() = id or public.is_admin(auth.uid()));

create policy "users_insert_self"
on public.users
for insert
with check (auth.uid() = id);

create policy "users_update_own_or_admin"
on public.users
for update
using (auth.uid() = id or public.is_admin(auth.uid()))
with check (auth.uid() = id or public.is_admin(auth.uid()));

-- PRODUCTS
create policy "products_public_read"
on public.products
for select
using (is_active = true or public.is_admin(auth.uid()));

create policy "products_admin_insert"
on public.products
for insert
with check (public.is_admin(auth.uid()));

create policy "products_admin_update"
on public.products
for update
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

create policy "products_admin_delete"
on public.products
for delete
using (public.is_admin(auth.uid()));

-- CARTS
create policy "carts_owner_all"
on public.carts
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- CART ITEMS
create policy "cart_items_owner_all"
on public.cart_items
for all
using (
  exists (
    select 1 from public.carts c
    where c.id = cart_items.cart_id and c.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.carts c
    where c.id = cart_items.cart_id and c.user_id = auth.uid()
  )
);

-- COUPONS
create policy "coupons_authenticated_read"
on public.coupons
for select
using (auth.uid() is not null);

create policy "coupons_admin_write"
on public.coupons
for all
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

-- ORDERS
create policy "orders_owner_read"
on public.orders
for select
using (auth.uid() = user_id or public.is_admin(auth.uid()));

create policy "orders_owner_insert"
on public.orders
for insert
with check (auth.uid() = user_id);

create policy "orders_admin_update"
on public.orders
for update
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

-- ORDER ITEMS
create policy "order_items_owner_read"
on public.order_items
for select
using (
  exists (
    select 1 from public.orders o
    where o.id = order_items.order_id
      and (o.user_id = auth.uid() or public.is_admin(auth.uid()))
  )
);

create policy "order_items_owner_insert"
on public.order_items
for insert
with check (
  exists (
    select 1 from public.orders o
    where o.id = order_items.order_id
      and o.user_id = auth.uid()
  )
);

create policy "order_items_admin_delete"
on public.order_items
for delete
using (public.is_admin(auth.uid()));
