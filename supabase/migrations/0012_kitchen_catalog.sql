-- Catálogo de cocina: ingredientes, recetas, menús y necesidades alimentarias.
create table public.kitchen_ingredients (
  id uuid primary key default gen_random_uuid(), owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null, category text, unit text not null default 'unidad', description text, allergens text[] not null default '{}', substitute text,
  estimated_unit_price numeric(10,2), storage_instructions text, visibility public.catalog_visibility not null default 'private', status text not null default 'active',
  created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint kitchen_ingredients_name_valid check (length(trim(name)) > 0), constraint kitchen_ingredients_price_valid check (estimated_unit_price is null or estimated_unit_price >= 0)
);
create index kitchen_ingredients_owner_idx on public.kitchen_ingredients(owner_organization_id);

create table public.kitchen_recipes (
  id uuid primary key default gen_random_uuid(), owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null, description text, meal_type text not null default 'comida', servings integer not null default 4, prep_minutes integer,
  difficulty text not null default 'media', instructions text, equipment text, storage_instructions text, allergens text[] not null default '{}',
  dietary_tags text[] not null default '{}', visibility public.catalog_visibility not null default 'private', status text not null default 'draft',
  version integer not null default 1, source_recipe_id uuid references public.kitchen_recipes(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint kitchen_recipes_name_valid check (length(trim(name)) > 0), constraint kitchen_recipes_servings_valid check (servings > 0)
);
create index kitchen_recipes_owner_idx on public.kitchen_recipes(owner_organization_id);

create table public.kitchen_recipe_ingredients (
  id uuid primary key default gen_random_uuid(), recipe_id uuid not null references public.kitchen_recipes(id) on delete cascade,
  ingredient_id uuid not null references public.kitchen_ingredients(id) on delete restrict, quantity numeric(10,3) not null, unit text not null, notes text,
  unique(recipe_id, ingredient_id), constraint kitchen_recipe_ingredients_quantity_valid check (quantity > 0)
);

create table public.kitchen_dietary_requirements (
  id uuid primary key default gen_random_uuid(), owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null, description text, severity text not null default 'preference', status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.kitchen_menus (
  id uuid primary key default gen_random_uuid(), owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null, description text, starts_on date, ends_on date, people_count integer not null default 1,
  visibility public.catalog_visibility not null default 'private', status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint kitchen_menus_name_valid check (length(trim(name)) > 0), constraint kitchen_menus_people_valid check (people_count > 0), constraint kitchen_menus_dates_valid check (ends_on is null or starts_on is null or ends_on >= starts_on)
);
create table public.kitchen_menu_items (
  id uuid primary key default gen_random_uuid(), menu_id uuid not null references public.kitchen_menus(id) on delete cascade,
  recipe_id uuid not null references public.kitchen_recipes(id) on delete restrict, meal_date date, meal_type text not null default 'comida', servings integer not null default 1, notes text,
  constraint kitchen_menu_items_servings_valid check (servings > 0)
);

create table public.kitchen_shopping_items (
  id uuid primary key default gen_random_uuid(), menu_id uuid not null references public.kitchen_menus(id) on delete cascade,
  ingredient_id uuid references public.kitchen_ingredients(id) on delete restrict, name text not null, quantity numeric(10,3) not null, unit text not null,
  status text not null default 'pending', estimated_cost numeric(10,2), actual_cost numeric(10,2), notes text, constraint kitchen_shopping_quantity_valid check (quantity > 0)
);

alter table public.kitchen_ingredients enable row level security; alter table public.kitchen_recipes enable row level security; alter table public.kitchen_recipe_ingredients enable row level security; alter table public.kitchen_dietary_requirements enable row level security; alter table public.kitchen_menus enable row level security; alter table public.kitchen_menu_items enable row level security; alter table public.kitchen_shopping_items enable row level security;
create policy kitchen_ingredients_scope on public.kitchen_ingredients for all to authenticated using (public.is_platform_admin() or public.is_org_member(owner_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
create policy kitchen_recipes_scope on public.kitchen_recipes for all to authenticated using (public.is_platform_admin() or public.is_org_member(owner_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
create policy kitchen_recipe_ingredients_scope on public.kitchen_recipe_ingredients for all to authenticated using (exists(select 1 from public.kitchen_recipes r where r.id=recipe_id and (public.is_platform_admin() or public.is_org_member(r.owner_organization_id)))) with check (exists(select 1 from public.kitchen_recipes r where r.id=recipe_id and (public.is_platform_admin() or public.is_org_admin(r.owner_organization_id))));
create policy kitchen_dietary_scope on public.kitchen_dietary_requirements for all to authenticated using (public.is_platform_admin() or public.is_org_member(owner_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
create policy kitchen_menus_scope on public.kitchen_menus for all to authenticated using (public.is_platform_admin() or public.is_org_member(owner_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
create policy kitchen_menu_items_scope on public.kitchen_menu_items for all to authenticated using (exists(select 1 from public.kitchen_menus m where m.id=menu_id and (public.is_platform_admin() or public.is_org_member(m.owner_organization_id)))) with check (exists(select 1 from public.kitchen_menus m where m.id=menu_id and (public.is_platform_admin() or public.is_org_admin(m.owner_organization_id))));
create policy kitchen_shopping_scope on public.kitchen_shopping_items for all to authenticated using (exists(select 1 from public.kitchen_menus m where m.id=menu_id and (public.is_platform_admin() or public.is_org_member(m.owner_organization_id)))) with check (exists(select 1 from public.kitchen_menus m where m.id=menu_id and (public.is_platform_admin() or public.is_org_admin(m.owner_organization_id))));
