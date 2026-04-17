-- IMPORTANT: Create these users first in Supabase Auth dashboard:
-- admin@shop.com / 12345678
-- user@shop.com / 12345678
-- Then run this seed script.

insert into public.users (id, email, full_name, phone, address, role)
select id, email, 'Shop Admin', '0900000001', 'Admin Street', 'admin'
from auth.users
where email = 'admin@shop.com'
on conflict (id) do update
set role = 'admin', full_name = excluded.full_name;

insert into public.users (id, email, full_name, phone, address, role)
select id, email, 'Demo User', '0900000002', 'User Street', 'user'
from auth.users
where email = 'user@shop.com'
on conflict (id) do nothing;

insert into public.products (name, description, category, price, stock, image_url)
values
  ('iPhone 15', 'Apple iPhone 15 128GB', 'Phone', 899.00, 15, 'https://images.unsplash.com/photo-1603898037225-1a8f00579f38?w=800'),
  ('Samsung Galaxy S24', 'Samsung flagship with AMOLED display', 'Phone', 799.00, 20, 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800'),
  ('iPad Air', 'Apple tablet for work and entertainment', 'Tablet', 599.00, 10, 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800'),
  ('AirPods Pro', 'Noise-cancelling wireless earbuds', 'Accessories', 249.00, 25, 'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=800');

insert into public.carts (user_id)
select id from public.users where email = 'user@shop.com'
on conflict (user_id) do nothing;

insert into public.cart_items (cart_id, product_id, quantity, unit_price)
select c.id, p.id, 1, p.price
from public.carts c
join public.users u on u.id = c.user_id and u.email = 'user@shop.com'
join public.products p on p.name = 'iPhone 15'
on conflict (cart_id, product_id) do nothing;

insert into public.coupons (
  code, discount_type, discount_value, min_order_amount, max_discount,
  start_at, end_at, is_active, created_by
)
select
  'WELCOME10', 'percent', 10, 100, 50,
  now() - interval '1 day', now() + interval '30 days', true, u.id
from public.users u
where u.email = 'admin@shop.com'
on conflict (code) do nothing;

insert into public.coupons (
  code, discount_type, discount_value, min_order_amount, max_discount,
  start_at, end_at, is_active, created_by
)
select
  'SAVE20', 'fixed', 20, 150, null,
  now() - interval '1 day', now() + interval '30 days', true, u.id
from public.users u
where u.email = 'admin@shop.com'
on conflict (code) do nothing;

with user_row as (
  select id from public.users where email = 'user@shop.com' limit 1
),
inserted_order as (
  insert into public.orders (
    user_id, status, payment_method, subtotal,
    discount_amount, shipping_fee, total_amount, shipping_address
  )
  select
    user_row.id, 'pending', 'cod', 899.00,
    50.00, 5.00, 854.00, '123 Demo Street'
  from user_row
  returning id
)
insert into public.order_items (order_id, product_id, quantity, unit_price, line_total)
select o.id, p.id, 1, p.price, p.price
from inserted_order o
join public.products p on p.name = 'iPhone 15';
