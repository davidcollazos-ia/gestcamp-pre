-- La propiedad de una instalación se transfiere al compartirla con la organización madre.
-- La organización de origen conserva únicamente la relación de compartición; no puede editar
-- ni borrar la instalación una vez transferida.

create or replace function public.transfer_facility_ownership_on_share()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  source_parent uuid;
begin
  if new.status = 'active'
     and new.direction = 'up'
     and new.source_organization_id <> new.target_organization_id then
    select parent_organization_id
      into source_parent
      from public.organizations
     where id = new.source_organization_id;

    if source_parent is distinct from new.target_organization_id then
      raise exception 'La organización destino debe ser la organización madre directa';
    end if;

    update public.camping_facilities
       set owner_organization_id = new.target_organization_id,
           manager_organization_id = null,
           visibility = 'private',
           updated_at = now()
     where id = new.facility_id;
  end if;
  return new;
end;
$$;

drop trigger if exists facility_share_transfers_ownership on public.facility_shares;
create trigger facility_share_transfers_ownership
after insert or update of status, direction, target_organization_id
on public.facility_shares
for each row execute function public.transfer_facility_ownership_on_share();

drop policy if exists camping_facilities_update_manager on public.camping_facilities;
create policy camping_facilities_update_owner on public.camping_facilities
for update to authenticated
using (public.is_platform_admin() or public.is_org_admin(owner_organization_id))
with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));

drop policy if exists camping_facilities_delete_owner on public.camping_facilities;
create policy camping_facilities_delete_owner on public.camping_facilities
for delete to authenticated
using (public.is_platform_admin() or public.is_org_admin(owner_organization_id));

create or replace function public.share_facility_up(
  p_facility_id uuid,
  p_target_organization_id uuid
)
returns public.camping_facilities
language plpgsql
security definer
set search_path = public
as $$
declare
  f public.camping_facilities;
  source_parent uuid;
  next_version integer;
  v public.facility_versions;
begin
  select * into f from public.camping_facilities where id = p_facility_id for update;
  if f.id is null then raise exception 'La instalación no existe'; end if;
  if not public.is_platform_admin() and not public.is_org_admin(f.owner_organization_id) then
    raise exception 'Solo el propietario puede compartir la instalación';
  end if;
  select parent_organization_id into source_parent from public.organizations where id = f.owner_organization_id;
  if source_parent is distinct from p_target_organization_id then
    raise exception 'Solo se puede compartir con la organización madre directa';
  end if;
  select coalesce(max(version_number), 0) + 1 into next_version from public.facility_versions where facility_id = f.id;
  insert into public.facility_versions(facility_id, version_number, source_organization_id, status, snapshot, published_at, published_by)
  values(f.id, next_version, f.owner_organization_id, 'published', to_jsonb(f), now(), auth.uid()) returning * into v;
  insert into public.facility_shares(facility_id, version_id, source_organization_id, target_organization_id, direction, status, created_by)
  values(f.id, v.id, f.owner_organization_id, p_target_organization_id, 'up', 'active', auth.uid());
  select * into f from public.camping_facilities where id = p_facility_id;
  return f;
end;
$$;
