-- Datos operativos resumidos de la instalación.
alter table public.camping_facilities
  add column if not exists total_capacity integer,
  add column if not exists sleeping_places integer,
  add column if not exists bathroom_count integer,
  add column if not exists shower_count integer,
  add column if not exists wifi_available boolean not null default false,
  add column if not exists accessible boolean not null default false,
  add column if not exists kitchen_available boolean not null default false,
  add column if not exists dining_available boolean not null default false,
  add column if not exists heating_available boolean not null default false,
  add column if not exists electricity_available boolean not null default false,
  add column if not exists drinking_water_available boolean not null default false,
  add column if not exists parking_available boolean not null default false,
  add column if not exists fire_area_available boolean not null default false,
  add column if not exists pets_allowed boolean not null default false,
  add column if not exists operational_notes text;

alter table public.camping_facilities drop constraint if exists camping_facilities_capacity_valid;
alter table public.camping_facilities add constraint camping_facilities_capacity_valid check (
  (total_capacity is null or total_capacity >= 0) and
  (sleeping_places is null or sleeping_places >= 0) and
  (bathroom_count is null or bathroom_count >= 0) and
  (shower_count is null or shower_count >= 0)
);
