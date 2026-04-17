# Flutter + Supabase Setup Guide (Mobile Device Shop)

This guide gives you everything needed to run this project with Supabase.

## 1. Install tools

1. Install Flutter SDK and Android Studio (or VS Code + Android emulator).
2. Create/run an emulator or connect a real device.
3. Verify Flutter:

```bash
flutter doctor
```

## 2. Create a Supabase project

1. Go to https://supabase.com and sign in.
2. Click New project.
3. Fill project name, strong database password, and region.
4. Wait until project status is healthy.

## 3. Enable Authentication (Email/Password)

1. In Supabase dashboard, open Authentication > Providers.
2. Enable Email provider.
3. Keep Confirm email enabled if you want email verification.
4. Go to Authentication > Users, click Add user and create:
   - admin@shop.com / 12345678
   - user@shop.com / 12345678

## 4. Create database schema (tables + relationships + RLS)

1. Open SQL Editor in Supabase dashboard.
2. Copy all SQL from [supabase/schema.sql](supabase/schema.sql).
3. Run it.

### Schema summary

- users
  - id uuid PK -> auth.users(id)
  - email text unique
  - full_name text
  - phone text
  - address text
  - role text (user/admin)
  - avatar_url text
  - created_at, updated_at timestamptz

- products
  - id bigserial PK
  - name, description, category
  - price numeric
  - stock int
  - image_url text
  - is_active bool
  - created_at, updated_at

- carts
  - id bigserial PK
  - user_id uuid unique FK -> users(id)
  - created_at, updated_at

- cart_items
  - id bigserial PK
  - cart_id FK -> carts(id)
  - product_id FK -> products(id)
  - quantity int
  - unit_price numeric
  - unique(cart_id, product_id)
  - created_at, updated_at

- coupons
  - id bigserial PK
  - code unique
  - discount_type (percent/fixed)
  - discount_value numeric
  - min_order_amount numeric
  - max_discount numeric nullable
  - start_at, end_at
  - is_active bool
  - usage_limit int nullable
  - used_count int
  - created_by FK -> users(id)
  - created_at

- orders
  - id bigserial PK
  - user_id FK -> users(id)
  - coupon_id FK -> coupons(id)
  - status (pending/paid/shipped/completed/cancelled)
  - payment_method
  - subtotal, discount_amount, shipping_fee, total_amount
  - shipping_address
  - created_at, updated_at

- order_items
  - id bigserial PK
  - order_id FK -> orders(id)
  - product_id FK -> products(id)
  - quantity
  - unit_price
  - line_total
  - created_at

## 5. Seed demo data

1. Open SQL Editor.
2. Copy all SQL from [supabase/seed.sql](supabase/seed.sql).
3. Run it.

This inserts users/profile roles, products, a cart/cart item, coupons, and one sample order.

## 6. Create storage bucket for product images

1. Go to Storage.
2. Click New bucket.
3. Bucket name: product-images
4. Set bucket as Public (recommended for simple demo app).
5. Save.

## 7. Add storage policies

In SQL Editor, run:

```sql
create policy "product_images_public_read"
on storage.objects
for select
using (bucket_id = 'product-images');

create policy "product_images_admin_insert"
on storage.objects
for insert
with check (
  bucket_id = 'product-images'
  and public.is_admin(auth.uid())
);

create policy "product_images_admin_update"
on storage.objects
for update
using (
  bucket_id = 'product-images'
  and public.is_admin(auth.uid())
)
with check (
  bucket_id = 'product-images'
  and public.is_admin(auth.uid())
);

create policy "product_images_admin_delete"
on storage.objects
for delete
using (
  bucket_id = 'product-images'
  and public.is_admin(auth.uid())
);
```

## 8. Get Supabase URL and anon key

1. In dashboard, open Project Settings > API.
2. Copy:
   - Project URL
   - anon public key

## 9. Configure Flutter project

Dependencies are already added in pubspec.yaml:
- provider
- supabase_flutter
- image_picker

Install packages:

```bash
flutter pub get
```

## 10. Run Flutter app with Supabase config

Run from project root:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 11. Where Supabase is initialized

- Main initialization: [lib/main.dart](lib/main.dart)
- Supabase getter and env variables: [lib/supabase_client.dart](lib/supabase_client.dart)

## 12. Data flow in app

UI -> Provider -> Service -> Supabase

Examples:
- Product list
  - UI: Home screen asks ProductProvider to load products
  - Provider: manages loading/error/filter/search state
  - Service: runs Supabase select query on products table
  - Supabase: returns rows

- Checkout
  - UI: Checkout screen calls OrderProvider.checkout
  - Provider: validates and forwards cart/coupon/address
  - Service: inserts orders + order_items, updates coupon usage
  - Supabase: stores final order data

## 13. Admin features in app

Admin user role is controlled by users.role = 'admin'.

Admin screen includes:
- Product CRUD
- Product image upload to storage bucket
- Coupon create/enable/disable/delete
- Order status updates

## 14. Important notes for beginners

1. Always create auth users first, then seed script.
2. If login succeeds but profile missing, run schema.sql again (trigger creates profile row on auth signup).
3. If image upload fails, check storage bucket name and policies.
4. If queries fail with RLS errors, make sure you are logged in and policy SQL ran successfully.
