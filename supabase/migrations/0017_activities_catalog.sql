create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  owner_organization_id uuid references public.organizations(id) on delete restrict,
  name text not null,
  summary text,
  activity_type text not null default 'juego_cooperativo',
  tags text[] not null default '{}',
  age_ranges text[] not null default '{}',
  setting text not null default 'interior_exterior',
  duration_minutes integer,
  intensity text not null default 'media',
  min_participants integer,
  max_participants integer,
  best_moment text,
  objectives text,
  preparation text,
  presentation text,
  development text,
  closing text,
  variations text,
  adaptations text,
  materials text,
  safety_risks text,
  safety_measures text,
  monitor_count integer,
  evaluation text,
  visibility text not null default 'private',
  status text not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint activities_name_valid check (length(trim(name)) > 0)
);
create index if not exists activities_owner_idx on public.activities(owner_organization_id);
create index if not exists activities_type_idx on public.activities(activity_type);
alter table public.activities enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='activities' and policyname='activities_scope') then
    create policy activities_scope on public.activities for all to authenticated
      using (public.is_platform_admin() or public.is_org_member(owner_organization_id))
      with check (public.is_platform_admin() or public.is_org_admin(owner_organization_id));
  end if;
end $$;
notify pgrst, 'reload schema';
