-- Las recetas usan ingredientes en texto libre; no son un catálogo independiente.
alter table public.kitchen_recipes
  add column if not exists ingredients_text text;
