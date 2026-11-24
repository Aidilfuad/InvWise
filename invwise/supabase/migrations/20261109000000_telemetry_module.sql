create table if not exists public.telemetry_settings (
  id text primary key default 'default' check (id = 'default'),
  voltage_warning_threshold numeric not null default 250
    check (voltage_warning_threshold > 0),
  current_warning_threshold numeric not null default 10
    check (current_warning_threshold > 0),
  offline_timeout_minutes integer not null default 5
    check (offline_timeout_minutes between 2 and 60),
  realtime_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.telemetry_settings (id)
values ('default')
on conflict (id) do nothing;

create table if not exists public.sensor_alerts (
  id uuid primary key default gen_random_uuid(),
  sensor_id uuid not null references public.sensors(id) on delete cascade,
  alert_type text not null
    check (alert_type in ('high_voltage', 'high_current', 'sensor_offline')),
  severity text not null check (severity in ('warning', 'critical')),
  status text not null default 'active'
    check (status in ('active', 'resolved', 'acknowledged')),
  message text not null,
  detected_at timestamptz not null default now(),
  resolved_at timestamptz,
  dedupe_key text not null unique,
  created_at timestamptz not null default now()
);

create index if not exists energy_readings_sensor_recorded_idx
  on public.energy_readings (sensor_id, recorded_at desc);
create index if not exists switch_events_sensor_recorded_idx
  on public.switch_events (sensor_id, recorded_at desc);
create index if not exists sensor_history_sensor_recorded_idx
  on public.sensor_history (sensor_id, recorded_at desc);
create index if not exists sensor_alerts_active_detected_idx
  on public.sensor_alerts (detected_at desc)
  where status = 'active';
create index if not exists sensor_alerts_sensor_detected_idx
  on public.sensor_alerts (sensor_id, detected_at desc);

alter table public.telemetry_settings enable row level security;
alter table public.sensor_alerts enable row level security;

drop policy if exists "Authenticated users can read telemetry settings"
  on public.telemetry_settings;
create policy "Authenticated users can read telemetry settings"
  on public.telemetry_settings for select to authenticated using (true);

drop policy if exists "Authenticated users can manage telemetry settings"
  on public.telemetry_settings;
create policy "Authenticated users can manage telemetry settings"
  on public.telemetry_settings for all to authenticated
  using (true) with check (true);

drop policy if exists "Authenticated users can read telemetry alerts"
  on public.sensor_alerts;
create policy "Authenticated users can read telemetry alerts"
  on public.sensor_alerts for select to authenticated using (true);

drop policy if exists "Authenticated users can manage telemetry alerts"
  on public.sensor_alerts;
create policy "Authenticated users can manage telemetry alerts"
  on public.sensor_alerts for all to authenticated
  using (true) with check (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'sensor_status'
  ) then
    alter publication supabase_realtime add table public.sensor_status;
  end if;
end
$$;

create or replace function public.prune_telemetry_history(
  retention_period interval default interval '90 days'
)
returns bigint
language plpgsql
security invoker
set search_path = public
as $$
declare
  deleted_count bigint;
  deleted_rows bigint;
begin
  if retention_period < interval '30 days' then
    raise exception 'Telemetry retention cannot be shorter than 30 days';
  end if;

  delete from public.energy_readings
  where recorded_at < now() - retention_period;
  get diagnostics deleted_count = row_count;

  delete from public.switch_events
  where recorded_at < now() - retention_period;
  get diagnostics deleted_rows = row_count;
  deleted_count := deleted_count + deleted_rows;

  delete from public.sensor_history
  where recorded_at < now() - retention_period;
  get diagnostics deleted_rows = row_count;
  return deleted_count + deleted_rows;
end;
$$;

revoke all on function public.prune_telemetry_history(interval) from public;
grant execute on function public.prune_telemetry_history(interval) to service_role;

comment on function public.prune_telemetry_history(interval) is
  'Optional maintenance task; retain at least 30 days and defaults to 90 days.';
