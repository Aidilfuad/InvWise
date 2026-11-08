alter type public.user_role
  add value if not exists 'Super Admin' before 'Inventory Administrator';
