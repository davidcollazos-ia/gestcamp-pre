-- Catálogo de instalaciones de acampada y alojamiento.
-- Mantiene la instalación separada de sus ubicaciones, espacios y condiciones.

create type public.facility_type as enum ('albergue','polideportivo','camping','zona_acampada','refugio','otro');
create type public.facility_status as enum ('draft','published','archived','retired');
create type public.location_method as enum ('map','administrative','both');
create type public.location_accuracy as enum ('exact','approximate','administrative');
create type public.facility_space_type as enum ('dormitorio','parcela','pabellon','sala','comedor','zona_bano','otro');
create type public.facility_visibility as enum ('private','up','down','global');

create table public.camping_facilities (
  id uuid primary key default gen_random_uuid(),
  owner_organization_id uuid references public.organizations(id) on delete restrict,
  owner_type text not null default 'organization',
  owner_name text,
  owner_contact_name text,
  owner_contact_email text,
  owner_contact_phone text,
  name text not null,
  facility_type public.facility_type not null,
  description text,
  status public.facility_status not null default 'draft',
  visibility public.facility_visibility not null default 'private',
  manager_organization_id uuid references public.organizations(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint camping_facilities_name_not_blank check (length(trim(name)) > 0)
  ,constraint camping_facilities_owner_valid check (owner_organization_id is not null or (owner_type <> 'organization' and length(trim(coalesce(owner_name,''))) > 0))
);
create index camping_facilities_owner_idx on public.camping_facilities(owner_organization_id);
create index camping_facilities_type_idx on public.camping_facilities(facility_type);

create table public.facility_locations (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null unique references public.camping_facilities(id) on delete cascade,
  location_method public.location_method not null default 'administrative',
  country_code text not null default 'ES',
  country_name text not null default 'España',
  region_code text,
  region_name text,
  province_code text,
  province_name text,
  municipality_code text,
  municipality_name text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  accuracy public.location_accuracy not null default 'administrative',
  address text,
  postal_code text,
  notes text,
  constraint facility_locations_latitude_valid check (latitude is null or latitude between -90 and 90),
  constraint facility_locations_longitude_valid check (longitude is null or longitude between -180 and 180),
  constraint facility_locations_map_complete check (location_method = 'administrative' or (latitude is not null and longitude is not null)),
  constraint facility_locations_admin_complete check (location_method = 'map' or (country_name is not null and (municipality_name is not null or province_name is not null)))
);

create table public.facility_spaces (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.camping_facilities(id) on delete cascade,
  name text not null,
  space_type public.facility_space_type not null,
  capacity integer,
  capacity_unit text not null default 'personas',
  description text,
  is_accessible boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  constraint facility_spaces_capacity_positive check (capacity is null or capacity > 0)
);
create index facility_spaces_facility_idx on public.facility_spaces(facility_id);

create table public.facility_features (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.camping_facilities(id) on delete cascade,
  space_id uuid references public.facility_spaces(id) on delete cascade,
  feature_code text not null,
  value_boolean boolean,
  value_text text,
  value_number numeric,
  unique (facility_id, space_id, feature_code)
);

create table public.facility_rules (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.camping_facilities(id) on delete cascade,
  rule_type text not null,
  description text not null,
  is_mandatory boolean not null default true
);

create table public.facility_availability (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.camping_facilities(id) on delete cascade,
  availability_type text not null default 'by_request',
  available_from date,
  available_to date,
  minimum_nights integer,
  requires_reservation boolean not null default true,
  notes text,
  constraint facility_availability_dates_valid check (available_to is null or available_from is null or available_to >= available_from)
);

create table public.facility_versions (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.camping_facilities(id) on delete cascade,
  version_number integer not null,
  source_organization_id uuid not null references public.organizations(id) on delete restrict,
  manager_organization_id uuid references public.organizations(id) on delete set null,
  status public.facility_status not null default 'draft',
  snapshot jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  published_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (facility_id, version_number)
);

create table public.facility_shares (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.camping_facilities(id) on delete cascade,
  version_id uuid not null references public.facility_versions(id) on delete cascade,
  source_organization_id uuid not null references public.organizations(id) on delete restrict,
  target_organization_id uuid not null references public.organizations(id) on delete restrict,
  direction public.facility_visibility not null,
  status public.share_status not null default 'pending',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  constraint facility_shares_no_self check (source_organization_id <> target_organization_id)
);
create unique index facility_shares_active_unique on public.facility_shares(facility_id, target_organization_id) where status in ('pending','active');

alter table public.camping_facilities enable row level security;
alter table public.facility_locations enable row level security;
alter table public.facility_spaces enable row level security;
alter table public.facility_features enable row level security;
alter table public.facility_rules enable row level security;
alter table public.facility_availability enable row level security;
alter table public.facility_versions enable row level security;
alter table public.facility_shares enable row level security;

create policy camping_facilities_select_scope on public.camping_facilities for select to authenticated using (public.is_platform_admin() or public.is_org_member(owner_organization_id) or public.is_org_member(manager_organization_id));
create policy camping_facilities_insert_admin on public.camping_facilities for insert to authenticated with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
create policy camping_facilities_update_manager on public.camping_facilities for update to authenticated using (public.is_platform_admin() or public.is_org_admin(coalesce(manager_organization_id, owner_organization_id))) with check (public.is_platform_admin() or public.is_org_admin(coalesce(manager_organization_id, owner_organization_id)));
create policy camping_facilities_delete_owner on public.camping_facilities for delete to authenticated using (public.is_platform_admin() or public.is_org_admin(owner_organization_id));

create policy facility_locations_scope on public.facility_locations for all to authenticated using (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_member(f.owner_organization_id) or public.is_org_member(f.manager_organization_id)))) with check (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_admin(coalesce(f.manager_organization_id,f.owner_organization_id)))));
create policy facility_spaces_scope on public.facility_spaces for all to authenticated using (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_member(f.owner_organization_id) or public.is_org_member(f.manager_organization_id)))) with check (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_admin(coalesce(f.manager_organization_id,f.owner_organization_id)))));
create policy facility_features_scope on public.facility_features for all to authenticated using (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_member(f.owner_organization_id) or public.is_org_member(f.manager_organization_id)))) with check (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_admin(coalesce(f.manager_organization_id,f.owner_organization_id)))));
create policy facility_rules_scope on public.facility_rules for all to authenticated using (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_member(f.owner_organization_id) or public.is_org_member(f.manager_organization_id)))) with check (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_admin(coalesce(f.manager_organization_id,f.owner_organization_id)))));
create policy facility_availability_scope on public.facility_availability for all to authenticated using (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_member(f.owner_organization_id) or public.is_org_member(f.manager_organization_id)))) with check (exists (select 1 from public.camping_facilities f where f.id=facility_id and (public.is_platform_admin() or public.is_org_admin(coalesce(f.manager_organization_id,f.owner_organization_id)))));
create policy facility_versions_scope on public.facility_versions for all to authenticated using (public.is_platform_admin() or public.is_org_member(source_organization_id) or public.is_org_member(manager_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(coalesce(manager_organization_id,source_organization_id)));
create policy facility_shares_scope on public.facility_shares for all to authenticated using (public.is_platform_admin() or public.is_org_member(source_organization_id) or public.is_org_member(target_organization_id)) with check (public.is_platform_admin() or public.is_org_admin(source_organization_id));

create trigger camping_facilities_touch_updated_at before update on public.camping_facilities for each row execute function public.touch_updated_at();
