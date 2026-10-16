create table if not exists public.kitchen_allergens (
  id uuid primary key default gen_random_uuid(),
  owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null,
  description text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_organization_id, name)
);
alter table public.kitchen_allergens enable row level security;
drop policy if exists kitchen_allergens_scope on public.kitchen_allergens;
create policy kitchen_allergens_scope on public.kitchen_allergens for all to authenticated using (public.is_platform_admin() or public.is_org_member(owner_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
