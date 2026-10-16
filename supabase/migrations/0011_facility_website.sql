alter table public.camping_facilities
  add column if not exists website text;

alter table public.camping_facilities
  drop constraint if exists camping_facilities_website_valid;

alter table public.camping_facilities
  add constraint camping_facilities_website_valid check (
    website is null or website ~* '^https?://[^[:space:]]+$'
  );
