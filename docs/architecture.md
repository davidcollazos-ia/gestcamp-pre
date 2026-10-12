# Campamento Scout

Plataforma SaaS multitenant para la gestión de grupos scout, asociaciones,
campamentos, participantes, actividades y catálogos.

## Arquitectura prevista

- **Next.js + TypeScript**: aplicación web y lógica de servidor ligera.
- **Supabase**: autenticación, PostgreSQL, Row Level Security y Storage.
- **Git**: control de versiones y revisión de cambios.
- **Vercel**: despliegue de la aplicación web.

## Entornos

| Entorno | Aplicación | Base de datos | Propósito |
|---|---|---|---|
| Local | Next.js local | Supabase local o proyecto de desarrollo | Desarrollo diario |
| Preview | Vercel Preview | Supabase desarrollo | Pull requests y pruebas |
| Producción | Vercel Production | Supabase producción | Usuarios reales |

Nunca se deben compartir las bases de datos de desarrollo y producción.

## Flujo de trabajo

1. Crear una rama `feature/nombre-del-cambio`.
2. Desarrollar y probar localmente.
3. Crear un Pull Request.
4. Vercel genera un despliegue Preview.
5. Ejecutar comprobaciones automáticas y revisar la Preview.
6. Fusionar a `main` para desplegar producción.

## Principios multitenant

- Todas las entidades de negocio deben estar asociadas a una organización.
- Las tablas principales usarán `organization_id`.
- El aislamiento entre organizaciones se aplicará con RLS en Supabase.
- Los permisos se comprobarán también en las operaciones de servidor.
- Las credenciales y secretos vivirán únicamente en variables de entorno.

## Organizaciones federadas y jerarquía

Gestcamp debe soportar estructuras organizativas de varios niveles, pero la
jerarquía será opcional. También podrán existir asociaciones independientes
sin organización superior ni organizaciones dependientes:

```text
Federación nacional (ej. ASDE)
└── Asociación autonómica (con CIF propio)
    └── Grupo scout (sin CIF propio, dependiente de la autonómica)
```

Ejemplo independiente:

```text
Asociación Cultural Independiente
```

No se debe modelar el CIF como obligatorio para todas las organizaciones.
Una organización puede ser una entidad legal con CIF o una unidad operativa
dependiente de otra organización.

La tabla `organizations` deberá incluir, como mínimo:

```text
id
parent_organization_id       # opcional; puede ser NULL
name
organization_type       # configurable: federation, association, scout_group...
tax_id                  # opcional; CIF/NIF de la entidad legal
status
slug
settings
```

Los grupos scouts federados podrán tener una asociación autonómica como
organización padre, pero dispondrán de usuarios, secciones, participantes,
actividades y datos propios. Una asociación independiente tendrá
`parent_organization_id = NULL` y funcionará como un tenant autónomo.

Si en el futuro una organización necesitara pertenecer a varias estructuras
simultáneamente, se podrá añadir una tabla `organization_relationships` sin
romper el modelo inicial:

```text
organization_relationships
- source_organization_id
- target_organization_id
- relationship_type
- status
```

El acceso debe distinguir entre:

- **Ámbito propio**: datos de la organización actual.
- **Ámbito descendiente**: datos de organizaciones hijas autorizadas.
- **Ámbito federativo**: datos agregados o informes de toda la federación.

La relación de pertenencia de usuarios se gestionará mediante
`organization_members`, permitiendo que una persona tenga roles diferentes en
varios niveles de la jerarquía.

## Catálogos y recursos compartidos

Los catálogos pueden existir en cualquier nivel de la jerarquía: federación,
asociación autonómica o grupo scout. La organización propietaria decide si un
catálogo permanece privado o se comparte.

Ejemplos de catálogos:

- Actividades.
- Secciones.
- Menús.
- Rutas.
- Monitores.
- Horarios.
- Instalaciones.
- Lugares de acampada.

La compartición será explícita y configurable al crear o editar un catálogo o
un recurso. Las opciones iniciales serán:

```text
private                 # solo la organización propietaria
children                # organizaciones descendientes autorizadas
all_descendants         # toda la rama inferior
selected_organizations  # organizaciones concretas seleccionadas
federation              # toda la estructura federativa autorizada
```

El propietario podrá elegir además el nivel de acceso:

```text
read                    # consultar y utilizar
copy                    # usar como base, sin modificar el original
edit                    # modificar el recurso compartido
admin                   # gestionar también la compartición
```

Se recomienda no modificar directamente un catálogo ajeno. Cuando una
organización necesite adaptarlo, podrá crear una copia propia manteniendo la
referencia al catálogo original.

Tablas previstas:

```text
catalogs
- id
- owner_organization_id
- catalog_type
- name
- visibility
- status

catalog_items
- id
- catalog_id
- name
- data
- status

catalog_shares
- id
- catalog_id
- target_organization_id
- access_level
- shared_by_user_id
- expires_at
```

El mismo patrón se podrá reutilizar para fotografías, instalaciones,
documentos, rutas, plantillas y otros recursos. La interfaz deberá mostrar
siempre quién es el propietario, con quién se comparte y qué permisos tiene
cada destinatario.

## Control de creación y aprobación

La plataforma tendrá un superadministrador global, independiente de las
organizaciones federativas. El superadministrador conservará el control sobre
la creación, aprobación, suspensión y relación jerárquica de organizaciones.

### Creación por el superadministrador

El superadministrador podrá crear directamente una organización y asignar a
su primer administrador.

### Solicitud de una organización hija

Un administrador de una organización existente podrá solicitar la creación de
una organización dependiente. La solicitud quedará pendiente hasta que el
superadministrador la apruebe o rechace.

### Invitación directa

El superadministrador o un administrador autorizado podrá iniciar una
invitación a un responsable. La organización no se activará hasta que la
invitación sea aceptada y, cuando corresponda, aprobada por el
superadministrador.

Al aprobarse una organización:

1. Se crea la organización con su `parent_organization_id`.
2. Se crea la membresía del usuario solicitante o invitado.
3. Se asigna el rol `organization_admin`.
4. Se registra quién aprobó la operación y cuándo.
5. Se envía una notificación de activación.

Tablas previstas:

```text
organization_requests
- id
- requested_by_user_id
- requested_parent_organization_id
- proposed_name
- proposed_type
- proposed_tax_id
- status
- reviewed_by_user_id
- reviewed_at
- review_notes

organization_invitations
- id
- organization_id
- email
- role_id
- invited_by_user_id
- status
- token_hash
- expires_at
- accepted_at
```

La creación directa de organizaciones desde el cliente permanecerá bloqueada.
Se realizará mediante una función segura que valide el rol global de
superadministrador y cree la organización, la membresía y el rol inicial en
una única transacción.

### Compartición ascendente y lateral

La dirección de la relación federativa no limitará por sí sola la
compartición. Una organización hija podrá compartir recursos con su
organización padre, la federación nacional, organizaciones hermanas u otras
organizaciones seleccionadas, si la política de la plataforma lo permite.

Pertenecer a una organización superior no concede acceso automático a los
catálogos de sus organizaciones hijas. Del mismo modo, una organización hija
no queda limitada a compartir únicamente hacia abajo.

La relación de compartición será explícita y tendrá origen y destino:

```text
catalog_shares
- catalog_id
- source_organization_id
- target_organization_id
- access_level
- status
- requires_approval
```

Opcionalmente se podrá activar un flujo de solicitud y aprobación para que una
organización pida acceso a un catálogo sin recibirlo automáticamente.

## Primera versión funcional

1. Organizaciones, usuarios y autenticación con email/Google.
2. Roles y miembros de cada organización.
3. Secciones y participantes.
4. Campamentos y actividades.
5. Asistencia básica.

## Variables de entorno previstas

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

La clave `SUPABASE_SERVICE_ROLE_KEY` nunca debe enviarse al navegador ni
subirse al repositorio.
