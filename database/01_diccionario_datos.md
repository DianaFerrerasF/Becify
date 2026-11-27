# Diccionario de Datos — Becify
**Proyecto:** **Becify** — Plataforma Móvil Centralizada de Becas  
**Documento:** `DB-DIC-01` — Diccionario de Datos Relacional  
**Versión:** `1.1.0` (Alineada con Reglas de Negocio `RN-01` a `RN-43`)  
**Autor:** Deurys Mercedes Batista (Líder de Base de Datos y Ciberseguridad)  
**Metodología:** Carlos Coronel & Steven Morris (*Bases de datos: Diseño, implementación y administración*)  
**Motor:** PostgreSQL 15+ / Supabase BaaS  

---

## 1. Resumen de Tablas y Cardinalidades

| Nombre de Tabla | Tipo de Entidad | Cardinalidad / Conexión | Descripción del Negocio |
| :--- | :--- | :--- | :--- |
| **`perfiles`** | Fuerte (Independiente) | 1:1 con `auth.users` | Identidad del usuario, consentimientos (`RN-07`), tramo de edad y tutor legal (`RN-38`). |
| **`instituciones`** | Débil (Especialización) | 1:0..1 con `perfiles` | Datos de entidades oferentes y ciclo de verificación institucional (`RN-09`). |
| **`becas`** | Dependiente (1:N) | N:1 con `instituciones` | Convocatorias publicadas. Nunca se eliminan físicamente (`RN-20`). |
| **`becas_guardadas`** | Asociativa (M:N) | N:1 con `perfiles`, N:1 con `becas` | Seguimiento personal, favoritos y marca *"Ya apliqué"* (`RN-21` a `RN-24`). |
| **`preferencias_notificacion`** | Débil (Especialización) | 1:1 con `perfiles` | Consentimiento granular de alertas de vencimiento y cambios (`RN-30`). |
| **`reportes`** | Dependiente (N:1) | N:1 con `becas`, N:1 con `perfiles` | Moderación posterior: reportes de oportunidades sospechosas (`RN-40`). |

---

## 2. Tipos de Datos Enumerados (Dominios Controlados)

* **`rol_usuario_enum`:** `'estudiante'`, `'institucion'`, `'admin'` (`RN-01`)
* **`nivel_academico_enum`:** `'secundaria'`, `'grado'`, `'posgrado'`, `'maestria'`, `'doctorado'` (`RN-15`)
* **`modalidad_enum`:** `'presencial'`, `'virtual'`, `'hibrida'` (`RN-14`)
* **`tipo_oportunidad_enum`:** `'beca_completa'`, `'beca_parcial'`, `'intercambio'`, `'pasantia'` (`RN-14`)
* **`estado_beca_enum`:** `'borrador'`, `'activa'`, `'cerrada'`, `'retirada'` (`RN-17`)
* **`estado_institucion_enum`:** `'pendiente'`, `'aprobada'`, `'rechazada'`, `'suspendida'`, `'dada_de_baja'` (`RN-09`)
* **`tramo_edad_enum`:** `'menor_13'`, `'entre_13_y_17'`, `'18_o_mas'` (`RN-38`)
* **`tutor_resolucion_enum`:** `'pendiente'`, `'validada'`, `'no_autorizada'`, `'vencida'` (`RN-38`)

---

## 3. Catálogo Detallado de Tablas

### Tabla 1: `perfiles`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK, FK** | NO | `auth.uid()` | Llave primaria vinculada a `auth.users(id)` con eliminación en cascada (`RN-08`). |
| `correo` | `VARCHAR(255)` | **UK** | NO | Ninguno | Correo electrónico único (`RN-06`). Validación regex de formato. |
| `nombre_completo` | `VARCHAR(150)` | --- | NO | Ninguno | Nombre o alias de perfil (`RN-25`). Mínimo 3 caracteres. |
| `rol` | `rol_usuario_enum` | --- | NO | `'estudiante'` | Rol único en la plataforma (`RN-01`). |
| `terminos_aceptados_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Marca temporal de aceptación de términos (`RN-07`). |
| `version_terminos` | `VARCHAR(20)` | --- | NO | `'1.0'` | Versión de términos aceptada (`RN-07`). |
| `consentimiento_datos_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Marca temporal de casilla independiente de consentimiento de datos (`RN-07`). |
| `tramo_edad` | `tramo_edad_enum` | --- | NO | `'18_o_mas'` | Tramo de edad seleccionado al registrarse; nunca fecha exacta (`RN-38`). |
| `tutor_nombre` | `VARCHAR(150)` | --- | SÍ | `NULL` | Nombre del tutor legal. Obligatorio si `tramo_edad = 'entre_13_y_17'` (`RN-38`). |
| `tutor_correo` | `VARCHAR(255)` | --- | SÍ | `NULL` | Correo del tutor legal. Obligatorio si `tramo_edad = 'entre_13_y_17'` (`RN-38`). |
| `tutor_aviso_enviado_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Fecha de envío del correo de confirmación al tutor (`RN-38`). |
| `tutor_resolucion` | `tutor_resolucion_enum` | --- | SÍ | `'pendiente'` | Estado de autorización del tutor: `'pendiente'`, `'validada'`, `'no_autorizada'`, `'vencida'`. |
| `tutor_resuelto_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Fecha en que el tutor respondió o venció el plazo (`RN-38`). |
| `creado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Fecha y hora de creación de la cuenta. |

---

### Tabla 2: `instituciones`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK** | NO | `gen_random_uuid()` | Identificador único propio de la institución. |
| `perfil_id` | `UUID` | **FK, UK** | SÍ | `NULL` | Cuenta de acceso en `perfiles(id)` con `ON DELETE SET NULL` (si se da de baja la cuenta, el historial de la institución no se borra, `RN-08`). |
| `nombre` | `VARCHAR(200)` | --- | NO | Ninguno | Nombre oficial o razón social de la entidad (mínimo 3 caracteres). |
| `pais` | `VARCHAR(100)` | --- | NO | Ninguno | País de origen o sede principal. |
| `sitio_web` | `VARCHAR(300)` | --- | SÍ | `NULL` | Portal web oficial verificable (`^https?://`, `RN-10`). |
| `url_logo` | `VARCHAR(500)` | --- | SÍ | `NULL` | URL del logotipo en Supabase Storage. |
| `descripcion` | `TEXT` | --- | SÍ | `NULL` | Reseña institucional y acreditaciones. |
| `estado` | `estado_institucion_enum` | --- | NO | `'pendiente'` | Estado del ciclo de verificación: `'pendiente'`, `'aprobada'`, `'rechazada'`, `'suspendida'`, `'dada_de_baja'` (`RN-09`). |
| `asignado_a` | `UUID` | **FK** | SÍ | `NULL` | Administrador asignado para revisar la solicitud (`RN-09`). |
| `verificada_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Fecha y hora en que fue resuelta por un administrador (`RN-09`). |
| `verificado_por` | `UUID` | **FK** | SÍ | `NULL` | Registro de control: admin en `perfiles(id)` que aprobó o resolvió la cuenta, con `ON DELETE SET NULL` (`RN-36`, `RN-37`). |
| `motivo_resolucion` | `TEXT` | --- | SÍ | `NULL` | Motivo de aprobación, rechazo o suspensión (`RN-09`). |

---

### Tabla 3: `becas`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK** | NO | `gen_random_uuid()` | Identificador único de la oportunidad. |
| `institucion_id` | `UUID` | **FK** | NO | Ninguno | Llave foránea hacia `instituciones(id)` con `ON DELETE RESTRICT` (evita borrado en cascada, `RN-20`). |
| `titulo` | `VARCHAR(250)` | --- | NO | Ninguno | Título descriptivo de la oportunidad (mínimo 5 caracteres). |
| `descripcion` | `TEXT` | --- | NO | Ninguno | Bases completas, beneficios y requisitos del programa. |
| `nivel_academico` | `nivel_academico_enum` | --- | NO | Ninguno | `'secundaria'`, `'grado'`, `'posgrado'`, `'maestria'`, `'doctorado'` (`RN-15`). |
| `area_estudio` | `VARCHAR(120)` | --- | NO | Ninguno | Campo disciplinar o carrera cubierta (`RN-14`). |
| `todas_las_carreras` | `BOOLEAN` | --- | NO | `FALSE` | Bandera para *"Todas las carreras"*. Obligatoria `TRUE` si nivel es `'secundaria'` (`RN-15`). |
| `pais` | `VARCHAR(100)` | --- | NO | Ninguno | País donde se cursa el estudio (o sede si es virtual, `RN-14`). |
| `modalidad` | `modalidad_enum` | --- | NO | `'presencial'` | `'presencial'`, `'virtual'`, `'hibrida'` (`RN-14`). |
| `tipo_oportunidad` | `tipo_oportunidad_enum` | --- | NO | `'beca_completa'` | `'beca_completa'`, `'beca_parcial'`, `'intercambio'`, `'pasantia'` (`RN-14`). |
| `fecha_limite` | `DATE` | --- | NO | Ninguno | Fecha de cierre siempre obligatoria (`RN-16`). |
| `enlace_oficial` | `VARCHAR(500)` | --- | NO | Ninguno | URL oficial externa para postularse (`^https?://`, `RN-18`). |
| `estado` | `estado_beca_enum` | --- | NO | `'borrador'` | `'borrador'`, `'activa'`, `'cerrada'`, `'retirada'` (`RN-17`). |
| `motivo_cierre` | `TEXT` | --- | SÍ | `NULL` | Motivo de cierre (`vencimiento`, `manual`, `baja_institucion`, `RN-17`). |
| `retirada_por` | `UUID` | **FK** | SÍ | `NULL` | Admin que retiró por moderación con `ON DELETE SET NULL` (`RN-17`, `RN-40`). |
| `motivo_retiro` | `TEXT` | --- | SÍ | `NULL` | Motivo del retiro por incumplimiento de normas (`RN-17`). |
| `retirada_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Marca temporal del retiro por moderación (`RN-17`). |
| `creado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Marca temporal de auditoría de creación. |
| `actualizado_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Fecha de última modificación relevante (`RN-19`). |

---

### Tabla 4: `becas_guardadas`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK** | NO | `gen_random_uuid()` | Identificador único del registro de seguimiento. |
| `perfil_id` | `UUID` | **FK, UK** | NO | Ninguno | FK hacia `perfiles(id)`. Parte de clave única compuesta (`RN-21`). |
| `beca_id` | `UUID` | **FK, UK** | NO | Ninguno | FK hacia `becas(id)`. Parte de clave única compuesta (`RN-21`). |
| `ya_aplique` | `BOOLEAN` | --- | NO | `FALSE` | Bandera de seguimiento: `TRUE` si el estudiante marcó *"Ya apliqué"* (`RN-22`). |
| `aplicada_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Fecha en que marcó *"Ya apliqué"*; se conserva aunque cierre la beca (`RN-22`). |
| `guardado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Fecha y hora en que se guardó en la lista personal. |

---

### Tabla 5: `preferencias_notificacion`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `perfil_id` | `UUID` | **PK, FK** | NO | Ninguno | Llave primaria referenciada a `perfiles(id)` (1 a 1). |
| `notificar_7_dias` | `BOOLEAN` | --- | NO | `TRUE` | Recordatorio preventivo 7 días antes del cierre (`RN-29`). |
| `notificar_24_horas` | `BOOLEAN` | --- | NO | `TRUE` | Recordatorio urgente 24 horas antes del cierre (`RN-29`). |
| `notificar_cambios_beca` | `BOOLEAN` | --- | NO | `TRUE` | Aviso por modificación relevante en oportunidad guardada (`RN-19`, `RN-29`). |

---

### Tabla 6: `reportes`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK** | NO | `gen_random_uuid()` | Identificador único del reporte (`RN-40`). |
| `beca_id` | `UUID` | **FK** | NO | Ninguno | Oportunidad reportada (`becas(id)`) con `ON DELETE RESTRICT` (evita borrar reportes en cascada, `RN-37`). |
| `reportado_por` | `UUID` | **FK** | SÍ | `NULL` | Estudiante que reportó con `ON DELETE SET NULL` (`RN-37`). |
| `motivo` | `TEXT` | --- | NO | Ninguno | Motivo del reporte (posible fraude, datos falsos, vencida, etc., `RN-40`). |
| `creado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Fecha y hora del reporte. |
| `resuelto_por` | `UUID` | **FK** | SÍ | `NULL` | Administrador resolutor con `ON DELETE SET NULL` (`RN-36`, `RN-37`). |
| `resolucion` | `TEXT` | --- | SÍ | `NULL` | Decisión tomada tras la revisión administrativa (`RN-40`). |
| `resuelto_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Marca temporal de la resolución (`RN-40`). |
