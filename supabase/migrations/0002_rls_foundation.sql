-- Gestcamp: initial Row Level Security policies.
-- The security-definer helpers avoid recursive policy evaluation.

create or replace function public.is_org_member(target_org uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = target_org
      and m.user_id = auth.uid()
      and m.status = 'active'
  );
$$;

create or replace function public.is_org_admin(target_org uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.organization_members m
    join public.roles r on r.id = m.role_id
    where m.organization_id = target_org
      and m.user_id = auth.uid()
      and m.status = 'active'
      and (r.name in ('platform_admin', 'organization_admin') or r.permissions ? 'organizations:admin')
  );
$$;

create or replace function public.can_access_org(target_org uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  with recursive descendants as (
    select o.id from public.organizations o where o.id = target_org
    union all
    select child.id
    from public.organizations child
    join descendants d on child.parent_organization_id = d.id
  )
  select exists (
    select 1
    from public.organization_members m
    where m.user_id = auth.uid()
      and m.status = 'active'
      and m.organization_id in (select id from descendants)
  );
$$;

create or replace function public.can_use_catalog(target_catalog uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.catalogs c
    where c.id = target_catalog
      and (
        public.is_org_member(c.owner_organization_id)
        or exists (
          select 1
          from public.catalog_shares s
          where s.catalog_id = c.id
            and s.target_organization_id in (
              select m.organization_id
              from public.organization_members m
              where m.user_id = auth.uid() and m.status = 'active'
            )
            and s.status = 'active'
            and (s.expires_at is null or s.expires_at > now())
        )
      )
  );
$$;

-- Organizations
create policy organizations_select_member_or_descendant
on public.organizations for select to authenticated
using (public.is_org_member(id) or public.can_access_org(id));

create policy organizations_insert_authenticated
on public.organizations for insert to authenticated
with check (auth.uid() is not null);

create policy organizations_update_admin
on public.organizations for update to authenticated
using (public.is_org_admin(id))
with check (public.is_org_admin(id));

create policy organizations_delete_admin
on public.organizations for delete to authenticated
using (public.is_org_admin(id));

-- Memberships and roles
create policy organization_members_select_self_or_admin
on public.organization_members for select to authenticated
using (user_id = auth.uid() or public.is_org_admin(organization_id));

create policy organization_members_manage_admin
on public.organization_members for all to authenticated
using (public.is_org_admin(organization_id))
with check (public.is_org_admin(organization_id));

create policy roles_select_member
on public.roles for select to authenticated
using (public.is_org_member(organization_id) or organization_id is null);

create policy roles_manage_admin
on public.roles for all to authenticated
using (organization_id is not null and public.is_org_admin(organization_id))
with check (organization_id is not null and public.is_org_admin(organization_id));

-- Organization relationships
create policy organization_relationships_select_member
on public.organization_relationships for select to authenticated
using (public.is_org_member(source_organization_id) or public.is_org_member(target_organization_id));

create policy organization_relationships_manage_source_admin
on public.organization_relationships for all to authenticated
using (public.is_org_admin(source_organization_id))
with check (public.is_org_admin(source_organization_id));

-- Catalogs
create policy catalogs_select_member_or_shared
on public.catalogs for select to authenticated
using (public.can_use_catalog(id));

create policy catalogs_insert_member
on public.catalogs for insert to authenticated
with check (public.is_org_member(owner_organization_id) and (created_by = auth.uid() or created_by is null));

create policy catalogs_update_owner_admin
on public.catalogs for update to authenticated
using (public.is_org_admin(owner_organization_id))
with check (public.is_org_admin(owner_organization_id));

create policy catalogs_delete_owner_admin
on public.catalogs for delete to authenticated
using (public.is_org_admin(owner_organization_id));

-- Catalog items
create policy catalog_items_select_allowed
on public.catalog_items for select to authenticated
using (public.can_use_catalog(catalog_id));

create policy catalog_items_insert_owner_admin
on public.catalog_items for insert to authenticated
with check (exists (select 1 from public.catalogs c where c.id = catalog_id and public.is_org_admin(c.owner_organization_id)));

create policy catalog_items_update_owner_admin
on public.catalog_items for update to authenticated
using (exists (select 1 from public.catalogs c where c.id = catalog_id and public.is_org_admin(c.owner_organization_id)))
with check (exists (select 1 from public.catalogs c where c.id = catalog_id and public.is_org_admin(c.owner_organization_id)));

create policy catalog_items_delete_owner_admin
on public.catalog_items for delete to authenticated
using (exists (select 1 from public.catalogs c where c.id = catalog_id and public.is_org_admin(c.owner_organization_id)));

-- Explicit sharing. The source organization controls its shares.
create policy catalog_shares_select_source_or_target
on public.catalog_shares for select to authenticated
using (public.is_org_member(source_organization_id) or public.is_org_member(target_organization_id));

create policy catalog_shares_insert_source_admin
on public.catalog_shares for insert to authenticated
with check (public.is_org_admin(source_organization_id));

create policy catalog_shares_update_source_admin
on public.catalog_shares for update to authenticated
using (public.is_org_admin(source_organization_id))
with check (public.is_org_admin(source_organization_id));

create policy catalog_shares_delete_source_admin
on public.catalog_shares for delete to authenticated
using (public.is_org_admin(source_organization_id));
