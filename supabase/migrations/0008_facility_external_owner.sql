-- Permite que el propietario físico sea una entidad externa a Gestcamp.
alter table public.camping_facilities alter column owner_organization_id drop not null;
alter table public.camping_facilities add column if not exists owner_type text not null default 'organization';
alter table public.camping_facilities add column if not exists owner_name text;
alter table public.camping_facilities add column if not exists owner_contact_name text;
alter table public.camping_facilities add column if not exists owner_contact_email text;
alter table public.camping_facilities add column if not exists owner_contact_phone text;
alter table public.camping_facilities drop constraint if exists camping_facilities_owner_valid;
alter table public.camping_facilities add constraint camping_facilities_owner_valid check (owner_organization_id is not null or (owner_type <> 'organization' and length(trim(coalesce(owner_name,''))) > 0));
