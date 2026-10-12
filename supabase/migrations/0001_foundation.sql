-- Gestcamp: foundation for organizations, memberships and shared catalogs.
-- This migration is intentionally independent of the UI.

create extension if not exists pgcrypto;

create type public.organization_type as enum (
  'federation',
  'association',
  'scout_group',
  'club',
  'educational_entity',
  'youth_organization',
  'other'
);

create type public.organization_status as enum ('active', 'pending', 'suspended', 'archived');
create type public.membership_status as enum ('invited', 'active', 'suspended', 'removed');
create type public.catalog_visibility as enum ('private', 'children', 'all_descendants', 'selected_organizations', 'federation');
create type public.catalog_access_level as enum ('read', 'use', 'copy', 'edit', 'admin');
create type public.share_status as enum ('pending', 'active', 'rejected', 'revoked', 'expired');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  parent_organization_id uuid references public.organizations(id) on delete set null,
  name text not null,
  slug text not null unique,
  organization_type public.organization_type not null default 'other',
  tax_id text,
  status public.organization_status not null default 'active',
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organizations_name_not_blank check (length(trim(name)) > 0),
  constraint organizations_tax_id_not_blank check (tax_id is null or length(trim(tax_id)) > 0)
);

create index organizations_parent_idx on public.organizations(parent_organization_id);
create index organizations_type_idx on public.organizations(organization_type);

create table public.organization_relationships (
  id uuid primary key default gen_random_uuid(),
  source_organization_id uuid not null references public.organizations(id) on delete cascade,
  target_organization_id uuid not null references public.organizations(id) on delete cascade,
  relationship_type text not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  unique (source_organization_id, target_organization_id, relationship_type),
  constraint organization_relationships_not_self check (source_organization_id <> target_organization_id)
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  name text not null,
  description text,
  permissions jsonb not null default '[]'::jsonb,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  unique (organization_id, name)
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id uuid references public.roles(id) on delete set null,
  status public.membership_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create index organization_members_user_idx on public.organization_members(user_id);

create table public.catalogs (
  id uuid primary key default gen_random_uuid(),
  owner_organization_id uuid not null references public.organizations(id) on delete cascade,
  catalog_type text not null,
  name text not null,
  description text,
  visibility public.catalog_visibility not null default 'private',
  status text not null default 'active',
  settings jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index catalogs_owner_idx on public.catalogs(owner_organization_id);
create index catalogs_type_idx on public.catalogs(catalog_type);

create table public.catalog_items (
  id uuid primary key default gen_random_uuid(),
  catalog_id uuid not null references public.catalogs(id) on delete cascade,
  name text not null,
  description text,
  data jsonb not null default '{}'::jsonb,
  status text not null default 'active',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index catalog_items_catalog_idx on public.catalog_items(catalog_id);

create table public.catalog_shares (
  id uuid primary key default gen_random_uuid(),
  catalog_id uuid not null references public.catalogs(id) on delete cascade,
  source_organization_id uuid not null references public.organizations(id) on delete cascade,
  target_organization_id uuid not null references public.organizations(id) on delete cascade,
  access_level public.catalog_access_level not null default 'use',
  status public.share_status not null default 'active',
  requires_approval boolean not null default false,
  shared_by_user_id uuid references auth.users(id) on delete set null,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (catalog_id, target_organization_id),
  constraint catalog_shares_different_organizations check (source_organization_id <> target_organization_id)
);

create index catalog_shares_target_idx on public.catalog_shares(target_organization_id);
create index catalog_shares_source_idx on public.catalog_shares(source_organization_id);

comment on table public.organizations is 'Federated, independent or operational organizations using Gestcamp.';
comment on column public.organizations.parent_organization_id is 'Optional hierarchy parent. NULL means the organization is independent or top-level.';
comment on table public.catalog_shares is 'Explicit directional sharing between organizations, including upward and lateral sharing.';
