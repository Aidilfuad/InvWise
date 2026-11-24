alter table public.user_settings
  add column if not exists currency_code text not null default 'MYR';

alter table public.user_settings
  drop constraint if exists user_settings_currency_code_check;

alter table public.user_settings
  add constraint user_settings_currency_code_check
  check (currency_code in ('MYR', 'USD'));

create table if not exists public.app_settings (
  id text primary key,
  exchange_rate_usd_myr numeric not null,
  updated_at timestamptz not null default now(),
  constraint app_settings_exchange_rate_positive
    check (exchange_rate_usd_myr > 0)
);

insert into public.app_settings (id, exchange_rate_usd_myr)
values ('exchange_rate_usd_myr', 4.25)
on conflict (id) do nothing;

alter table public.app_settings enable row level security;

grant select on public.app_settings to authenticated;
grant update (exchange_rate_usd_myr, updated_at)
  on public.app_settings to authenticated;
revoke insert, delete on public.app_settings from anon, authenticated;

drop policy if exists "Authenticated users can read app settings"
  on public.app_settings;
create policy "Authenticated users can read app currency settings"
  on public.app_settings for select
  to authenticated
  using (true);

drop policy if exists "Super Admins can update app currency settings"
  on public.app_settings;
create policy "Super Admins can update app currency settings"
  on public.app_settings for update
  to authenticated
  using (
    exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.role::text = 'Super Admin'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.role::text = 'Super Admin'
    )
  );
