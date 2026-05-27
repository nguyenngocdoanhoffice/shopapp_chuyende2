-- 1) CATEGORY MANAGEMENT

create table if not exists public.categories (
  id bigserial primary key,
  name text not null unique,
  description text not null default '',
  created_at timestamptz not null default now()
);

alter table public.products
  add column if not exists category_id bigint;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'products'
      and constraint_name = 'products_category_id_fkey'
  ) then
    alter table public.products
      add constraint products_category_id_fkey
      foreign key (category_id)
      references public.categories(id)
      on update cascade
      on delete set null;
  end if;
end $$;

-- 3) Atomic checkout function to prevent overselling and decrement stock
create or replace function public.create_order_with_stock_check(
  p_shipping_address text,
  p_payment_method text,
  p_cart_items jsonb,
  p_coupon_id bigint default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_order_id bigint;
  v_item jsonb;
  v_product record;
  v_coupon record;
  v_quantity int;
  v_unit_price numeric(12,2);
  v_subtotal numeric(12,2) := 0;
  v_discount numeric(12,2) := 0;
  v_shipping_fee numeric(12,2) := 5.00;
  v_total numeric(12,2);
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_cart_items is null or jsonb_array_length(p_cart_items) = 0 then
    raise exception 'Cart is empty';
  end if;

  for v_item in select * from jsonb_array_elements(p_cart_items)
  loop
    v_quantity := coalesce((v_item->>'quantity')::int, 0);
    if v_quantity <= 0 then
      raise exception 'Invalid quantity';
    end if;

    select id, name, stock, price
    into v_product
    from public.products
    where id = (v_item->>'product_id')::bigint
    for update;

    if not found then
      raise exception 'Product not found';
    end if;

    if v_product.stock < v_quantity then
      raise exception 'Số lượng mua của "%" vượt quá tồn kho. Chỉ còn % sản phẩm.',
        v_product.name,
        v_product.stock;
    end if;

    v_subtotal := v_subtotal + (v_product.price * v_quantity);
  end loop;

  if p_coupon_id is not null then
    select *
    into v_coupon
    from public.coupons
    where id = p_coupon_id
      and is_active = true
      and start_at <= now()
      and end_at >= now()
    for update;

    if not found then
      raise exception 'Coupon is invalid or expired';
    end if;

    if v_subtotal < v_coupon.min_order_amount then
      raise exception 'Subtotal does not meet coupon minimum amount';
    end if;

    if v_coupon.discount_type = 'percent' then
      v_discount := v_subtotal * v_coupon.discount_value / 100;
      if v_coupon.max_discount is not null and v_discount > v_coupon.max_discount then
        v_discount := v_coupon.max_discount;
      end if;
    else
      v_discount := least(v_coupon.discount_value, v_subtotal);
    end if;
  end if;

  v_total := v_subtotal - v_discount + v_shipping_fee;

  insert into public.orders (
    user_id,
    coupon_id,
    status,
    payment_method,
    subtotal,
    discount_amount,
    shipping_fee,
    total_amount,
    shipping_address
  ) values (
    v_user_id,
    p_coupon_id,
    'pending',
    p_payment_method,
    v_subtotal,
    v_discount,
    v_shipping_fee,
    v_total,
    p_shipping_address
  )
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_cart_items)
  loop
    v_quantity := (v_item->>'quantity')::int;

    select id, price, stock
    into v_product
    from public.products
    where id = (v_item->>'product_id')::bigint
    for update;

    v_unit_price := v_product.price;

    update public.products
    set stock = stock - v_quantity
    where id = v_product.id
      and stock >= v_quantity;

    if not found then
      raise exception 'Số lượng mua của "%" vượt quá tồn kho. Chỉ còn % sản phẩm.',
        v_product.name,
        v_product.stock;
    end if;

    insert into public.order_items (
      order_id,
      product_id,
      quantity,
      unit_price,
      line_total
    ) values (
      v_order_id,
      v_product.id,
      v_quantity,
      v_unit_price,
      v_unit_price * v_quantity
    );
  end loop;

  if p_coupon_id is not null then
    perform public.increment_coupon_usage(p_coupon_id);
  end if;

  return v_order_id;
end;
$$;

create index if not exists idx_products_category_id on public.products(category_id);

-- Optional: seed categories from old products.category text
insert into public.categories(name, description)
select distinct p.category, ''
from public.products p
where coalesce(p.category, '') <> ''
on conflict (name) do nothing;

update public.products p
set category_id = c.id
from public.categories c
where c.name = p.category
  and p.category_id is null;

-- 2) Enable RLS policies for categories (if not yet configured)
alter table public.categories enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and policyname = 'categories_read_all'
  ) then
    create policy categories_read_all
      on public.categories
      for select
      using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'categories'
      and policyname = 'categories_admin_write'
  ) then
    create policy categories_admin_write
      on public.categories
      for all
      using (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid() and u.role = 'admin'
        )
      )
      with check (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid() and u.role = 'admin'
        )
      );
  end if;
end $$;
