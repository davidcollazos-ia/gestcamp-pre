-- Completa los permisos CRUD de miembros y protege la relación organizativa.
drop policy if exists members_scope on public.members;
create policy members_select_scope on public.members for select to authenticated
  using (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.member_id=id and public.is_org_member(mo.organization_id)));
-- La inserción debe hacerse mediante una función protegida que valide la
-- organización y cree también member_organizations en la misma operación.
-- No se concede INSERT directo sobre members.
create policy members_update_scope on public.members for update to authenticated
  using (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.member_id=id and public.is_org_admin(mo.organization_id)))
  with check (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.member_id=id and public.is_org_admin(mo.organization_id)));
create policy members_delete_scope on public.members for delete to authenticated
  using (public.is_platform_admin() or exists (select 1 from public.member_organizations mo where mo.member_id=id and public.is_org_admin(mo.organization_id)));

notify pgrst, 'reload schema';
