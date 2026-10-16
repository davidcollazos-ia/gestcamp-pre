-- Keep the production schema aligned with the simplified kitchen catalog.
-- This migration is intentionally idempotent so it can repair environments
-- where the core kitchen tables were not applied.

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

create table if not exists public.kitchen_recipes (
  id uuid primary key default gen_random_uuid(),
  owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null,
  description text,
  ingredients_text text,
  meal_type text not null default 'comida',
  servings integer not null default 4,
  prep_minutes integer,
  difficulty text not null default 'media',
  instructions text,
  equipment text,
  storage_instructions text,
  allergens text[] not null default '{}',
  dietary_tags text[] not null default '{}',
  visibility text not null default 'private',
  status text not null default 'draft',
  version integer not null default 1,
  source_recipe_id uuid references public.kitchen_recipes(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists kitchen_recipes_owner_idx
  on public.kitchen_recipes(owner_organization_id);

alter table public.kitchen_allergens enable row level security;
alter table public.kitchen_recipes enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'kitchen_allergens'
      and policyname = 'kitchen_allergens_scope'
  ) then
    create policy kitchen_allergens_scope on public.kitchen_allergens
      for all to authenticated
      using (public.is_platform_admin() or public.is_org_member(owner_organization_id))
      with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'kitchen_recipes'
      and policyname = 'kitchen_recipes_scope'
  ) then
    create policy kitchen_recipes_scope on public.kitchen_recipes
      for all to authenticated
      using (public.is_platform_admin() or public.is_org_member(owner_organization_id))
      with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
  end if;
end $$;

notify pgrst, 'reload schema';
