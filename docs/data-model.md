# Modelo de datos inicial

## Decisiones

- `organizations` representa federaciones, asociaciones, grupos scout y otras entidades.
- `parent_organization_id` es opcional; no todas las organizaciones tienen jerarquía.
- `organization_members` permite que una persona tenga membresías y roles distintos en varias organizaciones.
- Los catálogos pertenecen a una organización propietaria.
- `catalog_shares` representa comparticiones explícitas y direccionales, también ascendentes o laterales.
- `auth.users` pertenece a Supabase Auth; los datos de la aplicación referencian su `id`.

## Primeros catálogos

El campo `catalog_type` permitirá empezar con:

```text
activities
sections
menus
routes
monitors
schedules
facilities
camping_places
```

Se mantiene como texto para poder añadir nuevos tipos sin modificar un enum de
base de datos en cada ampliación.

## Siguiente migración

La siguiente migración añadirá las políticas RLS. No se deben activar permisos
de producción hasta validar los casos de acceso propio, descendiente,
ascendente y lateral.

## Acceso inicial

La aplicación utilizará Supabase Auth para email/contraseña y Google. El
primer panel protegido será `/admin`, que comprueba la pertenencia del usuario
a `platform_admins` antes de mostrar funciones de administración.
