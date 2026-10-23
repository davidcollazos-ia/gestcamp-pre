-- Catálogos operativos de secciones, monitores y miembros.
-- Los datos personales quedan aislados por organización mediante RLS.

create table if not exists public.sections (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  alias text,
  age_min integer,
  age_max integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sections_name_not_blank check (length(trim(name)) > 0),
  constraint sections_age_range_valid check (age_min is null or age_max is null or (age_min >= 0 and age_max >= age_min))
);

create unique index if not exists sections_organization_name_idx on public.sections (organization_id, lower(name));
create index if not exists sections_organization_idx on public.sections (organization_id);
alter table public.sections add constraint sections_id_organization_key unique (id, organization_id);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  first_name text not null,
  last_name text not null,
  national_id text,
  phone text,
  email text,
  birth_date date,
  parent1_first_name text,
  parent1_last_name text,
  parent1_national_id text,
  parent1_phone text,
  parent1_email text,
  parent1_address text,
  parent2_first_name text,
  parent2_last_name text,
  parent2_national_id text,
  parent2_phone text,
  parent2_email text,
  parent2_address text,
  observations text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint members_first_name_not_blank check (length(trim(first_name)) > 0),
  constraint members_last_name_not_blank check (length(trim(last_name)) > 0)
);

create index if not exists members_user_idx on public.members (user_id);
create index if not exists members_national_id_idx on public.members (national_id);

create table if not exists public.member_organizations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  role_id uuid references public.roles(id) on delete set null,
  role text,
  is_monitor boolean not null default false,
  monitor_alias text,
  monitor_responsibility text,
  status text not null default 'active' check (status in ('active','inactive','pending')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, member_id)
);

create table if not exists public.member_sections (
  member_organization_id uuid not null references public.member_organizations(id) on delete cascade,
  section_id uuid not null references public.sections(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (member_organization_id, section_id)
);

create index if not exists member_organizations_organization_idx on public.member_organizations (organization_id);
create index if not exists member_organizations_member_idx on public.member_organizations (member_id);
create index if not exists member_sections_section_idx on public.member_sections (section_id);

create table if not exists public.monitors (
  id uuid primary key default gen_random_uuid(),
  member_organization_id uuid not null references public.member_organizations(id) on delete cascade,
  alias text,
  responsibility text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists monitors_member_organization_idx on public.monitors (member_organization_id);

alter table public.sections enable row level security;
alter table public.members enable row level security;
alter table public.member_organizations enable row level security;
alter table public.member_sections enable row level security;
alter table public.monitors enable row level security;

drop policy if exists sections_scope on public.sections;
create policy sections_scope on public.sections for all to authenticated
  using (public.is_platform_admin() or public.is_org_member(organization_id))
  with check (public.is_platform_admin() or public.is_org_admin(organization_id));

drop policy if exists members_scope on public.members;
create policy members_scope on public.members for select to authenticated
  using (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.member_id=id and public.is_org_member(mo.organization_id)));

drop policy if exists member_organizations_scope on public.member_organizations;
create policy member_organizations_scope on public.member_organizations for all to authenticated
  using (public.is_platform_admin() or public.is_org_member(organization_id))
  with check (public.is_platform_admin() or public.is_org_admin(organization_id));

drop policy if exists member_sections_scope on public.member_sections;
create policy member_sections_scope on public.member_sections for all to authenticated
  using (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.id=member_organization_id and public.is_org_member(mo.organization_id)))
  with check (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.id=member_organization_id and public.is_org_admin(mo.organization_id)));

drop policy if exists monitors_scope on public.monitors;
create policy monitors_scope on public.monitors for all to authenticated
  using (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.id=member_organization_id and public.is_org_member(mo.organization_id)))
  with check (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.id=member_organization_id and public.is_org_admin(mo.organization_id)));

notify pgrst, 'reload schema';
