-- Gestcamp: platform governance and organization approval workflow.

create table public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete set null
);

create or replace function public.is_platform_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (select 1 from public.platform_admins where user_id = auth.uid());
$$;

create table public.organization_requests (
  id uuid primary key default gen_random_uuid(),
  requested_by_user_id uuid not null references auth.users(id) on delete cascade,
  requested_parent_organization_id uuid references public.organizations(id) on delete set null,
  proposed_name text not null,
  proposed_type public.organization_type not null default 'other',
  proposed_tax_id text,
  status text not null default 'pending',
  reviewed_by_user_id uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_notes text,
  created_at timestamptz not null default now()
);

create table public.organization_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  email text not null,
  role_id uuid references public.roles(id) on delete set null,
  invited_by_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending',
  token_hash text,
  expires_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

-- Replace the initial permissive organization creation rule.
drop policy if exists organizations_insert_authenticated on public.organizations;
create policy organizations_insert_platform_admin
on public.organizations for insert to authenticated
with check (public.is_platform_admin());

alter table public.platform_admins enable row level security;
alter table public.organization_requests enable row level security;
alter table public.organization_invitations enable row level security;

create policy platform_admins_select_self_or_platform_admin
on public.platform_admins for select to authenticated
using (user_id = auth.uid() or public.is_platform_admin());

create policy organization_requests_select_requester_or_platform_admin
on public.organization_requests for select to authenticated
using (requested_by_user_id = auth.uid() or public.is_platform_admin());

create policy organization_requests_insert_authenticated
on public.organization_requests for insert to authenticated
with check (requested_by_user_id = auth.uid());

create policy organization_requests_update_platform_admin
on public.organization_requests for update to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy organization_invitations_select_invited_or_admin
on public.organization_invitations for select to authenticated
using (public.is_platform_admin() or invited_by_user_id = auth.uid());

create policy organization_invitations_insert_platform_or_org_admin
on public.organization_invitations for insert to authenticated
with check (public.is_platform_admin() or public.is_org_admin(organization_id));

create policy organization_invitations_update_platform_or_org_admin
on public.organization_invitations for update to authenticated
using (public.is_platform_admin() or public.is_org_admin(organization_id))
with check (public.is_platform_admin() or public.is_org_admin(organization_id));

-- Seed the supplied owner account if it already exists in Supabase Auth.
insert into public.platform_admins (user_id)
select id from auth.users
where lower(email) = lower('gestcamp370@gmail.com')
on conflict (user_id) do nothing;
