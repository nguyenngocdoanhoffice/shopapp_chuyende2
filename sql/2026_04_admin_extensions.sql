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
