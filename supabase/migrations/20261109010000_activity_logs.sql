create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  actor_user_id uuid,
  actor_name text not null default 'System',
  category text not null,
  action text not null,
  description text not null,
  entity_type text not null default 'general',
  entity_id text,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists activity_logs_occurred_at_idx
  on public.activity_logs (occurred_at desc, id desc);
create index if not exists activity_logs_category_occurred_at_idx
  on public.activity_logs (category, occurred_at desc);
create index if not exists activity_logs_actor_occurred_at_idx
  on public.activity_logs (actor_name, occurred_at desc);
create index if not exists activity_logs_entity_idx
  on public.activity_logs (entity_type, entity_id, occurred_at desc);

alter table public.activity_logs enable row level security;

drop policy if exists "Authenticated users can read activity logs"
  on public.activity_logs;
create policy "Authenticated users can read activity logs"
  on public.activity_logs for select to authenticated using (true);

drop policy if exists "Users can append their own activity logs"
  on public.activity_logs;
create policy "Users can append their own activity logs"
  on public.activity_logs for insert to authenticated
  with check (actor_user_id = auth.uid());

insert into public.activity_logs (
  occurred_at,
  actor_user_id,
  actor_name,
  category,
  action,
  description,
  entity_type,
  entity_id,
  metadata
)
select
  log.occurred_at,
  profile.auth_user_id,
  coalesce(nullif(profile.full_name, ''), 'System'),
  'Inventory',
  initcap(replace(log.event_type::text, '_', ' ')),
  log.description,
  case when log.stock_movement_id is null
    then 'inventory_item' else 'inventory_movement' end,
  coalesce(log.stock_movement_id::text, log.item_id::text),
  coalesce(log.details, '{}'::jsonb) ||
    jsonb_build_object('legacy_activity_log_id', log.id::text)
from public.activity_log log
left join public.profiles profile on profile.id = log.actor_profile_id
where not exists (
  select 1
  from public.activity_logs existing
  where existing.metadata->>'legacy_activity_log_id' = log.id::text
);

comment on table public.activity_logs is
  'Extensible cross-module audit feed; category, action, entity_type and metadata are intentionally open-ended.';
