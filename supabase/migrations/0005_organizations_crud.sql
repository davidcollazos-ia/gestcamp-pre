-- Persistencia del CRUD de organizaciones.
alter table public.organizations
  add column if not exists display_name text,
  add column if not exists description text,
  add column if not exists address text,
  add column if not exists postal_code text,
  add column if not exists city text,
  add column if not exists region text,
  add column if not exists country text not null default 'España',
  add column if not exists contact_name text,
  add column if not exists contact_role text,
  add column if not exists contact_email text,
  add column if not exists phone text,
  add column if not exists website text;

update public.organizations set display_name = name where display_name is null;
alter table public.organizations alter column display_name set default '';

create unique index if not exists organizations_slug_lower_idx on public.organizations (lower(slug));

create or replace function public.organizations_prevent_parent_cycle()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.parent_organization_id is null then return new; end if;
  if new.parent_organization_id = new.id then
    raise exception 'Una organización no puede ser superior de sí misma';
  end if;
  if exists (
    with recursive parents(id) as (
      select parent_organization_id from organizations where id = new.parent_organization_id
      union all select o.parent_organization_id from organizations o join parents p on o.id=p.id where o.parent_organization_id is not null
    ) select 1 from parents where id = new.id
  ) then raise exception 'La organización superior crearía un ciclo jerárquico'; end if;
  return new;
end $$;

drop trigger if exists organizations_parent_cycle on public.organizations;
create trigger organizations_parent_cycle before insert or update of parent_organization_id on public.organizations
for each row execute function public.organizations_prevent_parent_cycle();

create or replace function public.touch_organizations_updated_at()
returns trigger language plpgsql set search_path = public as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists organizations_updated_at on public.organizations;
create trigger organizations_updated_at before update on public.organizations
for each row execute function public.touch_organizations_updated_at();

comment on column public.organizations.tax_id is 'CIF/NIF opcional; algunas organizaciones no disponen de identificador fiscal.';
comment on table public.organizations is 'Entidad raíz del tenant. Borrar una organización elimina sus membresías, roles, catálogos y relaciones dependientes mediante FK cascade.';
