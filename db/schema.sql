-- ClearBot Client Portal — full schema + RLS + triggers
-- Paste into Supabase SQL Editor. Idempotent; re-running is safe.

create extension if not exists "pgcrypto";

-- ================================
-- Tables
-- ================================
create table if not exists public.profiles (
  user_id            uuid primary key references auth.users(id) on delete cascade,
  company_name       text,
  primary_domain     text,
  timezone           text,
  first_name         text,
  last_name          text,
  email              text,
  role               text,
  notif_deliverables boolean default true,
  notif_messages     boolean default true,
  notif_digest       boolean default false,
  notif_invoices     boolean default true,
  notif_slack        boolean default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create table if not exists public.projects (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  name           text not null,
  description    text,
  status         text default 'discovery',
  progress       int  default 0 check (progress between 0 and 100),
  next_milestone text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists projects_user_id_idx    on public.projects(user_id);
create index if not exists projects_updated_at_idx on public.projects(updated_at desc);

create table if not exists public.deliverables (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  project_id   uuid references public.projects(id) on delete set null,
  project_name text,
  name         text not null,
  file_type    text,
  size_label   text,
  status       text,
  version      text,
  url          text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists deliverables_user_id_idx    on public.deliverables(user_id);
create index if not exists deliverables_project_id_idx on public.deliverables(project_id);

create table if not exists public.invoices (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  project_id   uuid references public.projects(id) on delete set null,
  project_name text,
  number       text,
  amount_cents int  not null default 0,
  issued_at    timestamptz,
  due_at       timestamptz,
  paid_at      timestamptz,
  status       text default 'due',
  pdf_url      text,
  created_at   timestamptz not null default now()
);
create index if not exists invoices_user_id_idx   on public.invoices(user_id);
create index if not exists invoices_issued_at_idx on public.invoices(issued_at desc);

create table if not exists public.message_threads (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  project_id   uuid references public.projects(id) on delete set null,
  project_name text,
  title        text,
  preview      text,
  unread_count int  default 0,
  status       text default 'active',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists message_threads_user_id_idx on public.message_threads(user_id);

create table if not exists public.activity (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  project_id   uuid references public.projects(id) on delete set null,
  project_name text,
  text         text not null,
  unread       boolean default true,
  created_at   timestamptz not null default now()
);
create index if not exists activity_user_id_idx    on public.activity(user_id);
create index if not exists activity_created_at_idx on public.activity(created_at desc);

-- ================================
-- updated_at auto-touch
-- ================================
create or replace function public.tg_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists tg_profiles_touch     on public.profiles;
drop trigger if exists tg_projects_touch     on public.projects;
drop trigger if exists tg_deliverables_touch on public.deliverables;
drop trigger if exists tg_threads_touch      on public.message_threads;

create trigger tg_profiles_touch     before update on public.profiles        for each row execute function public.tg_touch_updated_at();
create trigger tg_projects_touch     before update on public.projects        for each row execute function public.tg_touch_updated_at();
create trigger tg_deliverables_touch before update on public.deliverables    for each row execute function public.tg_touch_updated_at();
create trigger tg_threads_touch      before update on public.message_threads for each row execute function public.tg_touch_updated_at();

-- ================================
-- Auto-create a profile on signup
-- ================================
create or replace function public.tg_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (user_id, email)
  values (new.id, new.email)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists tg_on_auth_user_created on auth.users;
create trigger tg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.tg_handle_new_user();

-- ================================
-- Role guard: prevent non-admin/team users from self-promoting
-- ================================
-- Even though the client portal's settings UI no longer exposes the role
-- field, RLS alone (auth.uid() = user_id) would still allow a user to
-- update their own row with role='admin' via a direct API call. This
-- trigger reverts any attempt to change the role unless the caller is
-- already a team member, or the update is coming from service_role
-- (SQL editor / server-side admin tools).
create or replace function public.tg_guard_profile_role()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  caller_role text;
begin
  -- Allow service_role / SQL editor updates to bypass the guard.
  if auth.uid() is null or auth.role() = 'service_role' then
    return new;
  end if;
  if new.role is distinct from old.role then
    select p.role into caller_role
    from public.profiles p
    where p.user_id = auth.uid();
    if coalesce(caller_role, '') not in ('admin', 'team') then
      new.role := old.role;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists tg_profiles_guard_role on public.profiles;
create trigger tg_profiles_guard_role
  before update on public.profiles
  for each row execute function public.tg_guard_profile_role();

-- ================================
-- Row-Level Security
-- ================================
alter table public.profiles        enable row level security;
alter table public.projects        enable row level security;
alter table public.deliverables    enable row level security;
alter table public.invoices        enable row level security;
alter table public.message_threads enable row level security;
alter table public.activity        enable row level security;

drop policy if exists "profiles_self"     on public.profiles;
drop policy if exists "projects_self"     on public.projects;
drop policy if exists "deliverables_self" on public.deliverables;
drop policy if exists "invoices_self"     on public.invoices;
drop policy if exists "threads_self"      on public.message_threads;
drop policy if exists "activity_self"     on public.activity;

create policy "profiles_self"     on public.profiles        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "projects_self"     on public.projects        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "deliverables_self" on public.deliverables    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "invoices_self"     on public.invoices        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "threads_self"      on public.message_threads for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "activity_self"     on public.activity        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
