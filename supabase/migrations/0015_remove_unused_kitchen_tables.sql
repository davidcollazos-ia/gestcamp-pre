-- Cocina queda reducida a recetas y alérgenos.
-- Se eliminan tablas que ya no forman parte del modelo funcional actual.
drop table if exists public.kitchen_shopping_items cascade;
drop table if exists public.kitchen_menu_items cascade;
drop table if exists public.kitchen_menus cascade;
drop table if exists public.kitchen_recipe_ingredients cascade;
drop table if exists public.kitchen_ingredients cascade;
drop table if exists public.kitchen_dietary_requirements cascade;
