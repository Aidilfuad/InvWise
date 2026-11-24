alter table public.inventory_items
  add column if not exists barcode text;

alter table public.stock_levels
  add column if not exists bin_location text;

comment on column public.inventory_items.barcode is
  'Optional barcode used by the InvWise inventory workspace.';

comment on column public.stock_levels.bin_location is
  'Optional bin or zone within the warehouse location.';
