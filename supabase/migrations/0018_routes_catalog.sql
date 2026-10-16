create table if not exists public.routes (
  id uuid primary key default gen_random_uuid(),
  owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null,
  summary text,
  route_type text not null default 'senderismo',
  age_ranges text[] not null default '{}',
  difficulty text not null default 'moderada',
  setting text not null default 'natural',
  distance_km numeric(8,2),
  duration_minutes integer,
  elevation_gain_m integer,
  circular boolean not null default false,
  recommended_season text,
  start_name text,
  end_name text,
  track_geojson jsonb,
  waypoints jsonb not null default '[]'::jsonb,
  original_file_name text,
  original_file_type text,
  original_file_content text,
  objectives text,
  preparation text,
  development text,
  variations text,
  accessibility text,
  safety_risks text,
  safety_measures text,
  emergency_access text,
  mobile_coverage text,
  recommended_materials text,
  visibility text not null default 'private' check (visibility in ('private','down','up','global')),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists routes_owner_idx on public.routes(owner_organization_id);
create index if not exists routes_type_idx on public.routes(route_type);
alter table public.routes enable row level security;
drop policy if exists routes_select_scope on public.routes;
create policy routes_select_scope on public.routes for select using (
  public.is_platform_admin() or public.is_org_member(owner_organization_id)
);
drop policy if exists routes_insert_scope on public.routes;
create policy routes_insert_scope on public.routes for insert with check (
  public.is_platform_admin() or public.is_org_admin(owner_organization_id)
);
drop policy if exists routes_update_scope on public.routes;
create policy routes_update_scope on public.routes for update using (
  public.is_platform_admin() or public.is_org_admin(owner_organization_id)
);
drop policy if exists routes_delete_scope on public.routes;
create policy routes_delete_scope on public.routes for delete using (
  public.is_platform_admin() or public.is_org_admin(owner_organization_id)
);
notify pgrst, 'reload schema';
