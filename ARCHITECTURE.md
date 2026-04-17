# App Architecture

## Data flow

UI -> Provider -> Service -> Supabase

- UI layer
  - Screens/widgets render data and dispatch user actions.
- Provider layer
  - Holds state (loading, error, current data), notifies listeners.
- Service layer
  - Executes Supabase operations (select, insert, update, delete).
- Supabase layer
  - Auth + PostgreSQL + Storage as backend.

## Main providers

- AuthProvider
  - Register/login/logout
  - Load/update user profile

- ProductProvider
  - Product listing
  - Search by keyword
  - Filter by category
  - Admin create/update/delete products

- CartProvider
  - Add/update/remove cart items
  - Calculate subtotal and item count

- OrderProvider
  - Apply coupon
  - Checkout and create order
  - Load current user order history

- AdminProvider
  - Manage all orders status
  - Manage coupons
