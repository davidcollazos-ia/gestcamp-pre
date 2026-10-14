# Promoción de PRE a PRO

Este documento recoge los cambios que deben promoverse a producción después de completar las pruebas de PRE.

## Regla de trabajo

PRE es el entorno de validación. No aplicar migraciones estructurales ni cambios de permisos en PRO hasta cerrar la batería de pruebas y revisar este inventario.

## Cambios pendientes de promover

### Base de datos y seguridad

- [ ] Aplicar `supabase/migrations/0004_strict_organization_scope.sql` en Supabase PRO.
- [ ] Verificar que las funciones `is_org_member`, `can_access_org`, `is_org_admin` y `has_org_permission` existen en PRO.
- [ ] Verificar las políticas RLS de organizaciones, miembros, roles y relaciones.
- [ ] Confirmar que el superadmin de PRO existe y conserva acceso global.

### Aplicación

- [ ] Promover el código validado en PRE mediante el repositorio principal.
- [ ] Comprobar login por correo y Google.
- [ ] Comprobar cierre de sesión y selección de cuenta Google.
- [ ] Comprobar que las rutas protegidas requieren sesión.

### Configuración

- [ ] Mantener en PRO las variables de entorno apuntando exclusivamente a Supabase PRO.
- [ ] Verificar `Site URL` y las redirecciones OAuth de PRO.
- [ ] No copiar datos de usuarios, organizaciones o participantes de PRE a PRO salvo decisión explícita.

## Batería de pruebas previa a PRO

- [ ] Superadmin puede acceder a todas las organizaciones.
- [ ] Administrador de una federación solo ve su federación.
- [ ] Administrador de una asociación solo ve su asociación.
- [ ] Administrador de un grupo solo ve su grupo.
- [ ] Ningún administrador hereda acceso por pertenecer a una organización superior.
- [ ] Las invitaciones respetan la organización destino.
- [ ] Las solicitudes de organizaciones hijas requieren aprobación del superadmin.
- [ ] Los catálogos solo son visibles según la compartición explícita.
- [ ] Un usuario sin permisos no puede acceder mediante URL directa.

## Historial de cambios PRE

- `45735e3`: primera publicación de las políticas de alcance estricto.
- Actualización posterior: migración autosuficiente incluyendo `is_org_member`.
