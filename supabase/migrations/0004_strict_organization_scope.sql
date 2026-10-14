-- Gestcamp: strict organization scope. Hierarchy never inherits data access.

create or replace function public.is_org_member(target_org uuid) returns boolean language sql security definer set search_path=public stable as $$ select exists (select 1 from public.organization_members m where m.organization_id=target_org and m.user_id=auth.uid() and m.status='active'); $$;

create or replace function public.can_access_org(target_org uuid) returns boolean language sql security definer set search_path=public stable as $$ select public.is_platform_admin() or public.is_org_member(target_org); $$;

create or replace function public.is_org_admin(target_org uuid) returns boolean language sql security definer set search_path=public stable as $$ select public.is_platform_admin() or exists (select 1 from public.organization_members m join public.roles r on r.id=m.role_id where m.organization_id=target_org and m.user_id=auth.uid() and m.status='active' and (r.name='organization_admin' or r.permissions ? 'organizations:admin')); $$;

create or replace function public.has_org_permission(target_org uuid, permission_key text) returns boolean language sql security definer set search_path=public stable as $$ select public.is_platform_admin() or exists (select 1 from public.organization_members m join public.roles r on r.id=m.role_id where m.organization_id=target_org and m.user_id=auth.uid() and m.status='active' and (r.name='organization_admin' or r.permissions ? permission_key)); $$;

drop policy if exists platform_admins_select_self_or_platform_admin on public.platform_admins;
drop policy if exists platform_admins_select_self on public.platform_admins;
create policy platform_admins_select_self on public.platform_admins for select to authenticated using (user_id=auth.uid());

drop policy if exists organizations_select_member_or_descendant on public.organizations;
drop policy if exists organizations_insert_authenticated on public.organizations;
drop policy if exists organizations_update_admin on public.organizations;
drop policy if exists organizations_delete_admin on public.organizations;
create policy organizations_select_exact_scope on public.organizations for select to authenticated using (public.can_access_org(id));
create policy organizations_update_exact_admin on public.organizations for update to authenticated using (public.is_org_admin(id)) with check (public.is_org_admin(id));
create policy organizations_delete_exact_admin on public.organizations for delete to authenticated using (public.is_org_admin(id));

drop policy if exists organization_members_select_self_or_admin on public.organization_members;
drop policy if exists organization_members_manage_admin on public.organization_members;
create policy organization_members_select_exact_scope on public.organization_members for select to authenticated using (user_id=auth.uid() or public.is_org_admin(organization_id));
create policy organization_members_manage_exact_admin on public.organization_members for all to authenticated using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

drop policy if exists roles_select_member on public.roles;
drop policy if exists roles_manage_admin on public.roles;
create policy roles_select_exact_scope on public.roles for select to authenticated using (organization_id is null or public.can_access_org(organization_id));
create policy roles_manage_exact_admin on public.roles for all to authenticated using (organization_id is not null and public.is_org_admin(organization_id)) with check (organization_id is not null and public.is_org_admin(organization_id));

drop policy if exists organization_relationships_select_member on public.organization_relationships;
drop policy if exists organization_relationships_manage_source_admin on public.organization_relationships;
create policy organization_relationships_select_exact_scope on public.organization_relationships for select to authenticated using (public.can_access_org(source_organization_id) or public.can_access_org(target_organization_id));
create policy organization_relationships_manage_source_admin on public.organization_relationships for all to authenticated using (public.is_org_admin(source_organization_id)) with check (public.is_org_admin(source_organization_id));
