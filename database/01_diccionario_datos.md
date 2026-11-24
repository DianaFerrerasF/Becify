# Diccionario de Datos — Becify
**Proyecto:** **Becify** — Plataforma Móvil Centralizada de Becas  
**Documento:** `DB-DIC-01` — Diccionario de Datos Relacional  
**Versión:** `1.0.0` (Sprint 0)  
**Autor:** Deurys Mercedes Batista (Líder de Base de Datos y Ciberseguridad)  
**Metodología:** Carlos Coronel & Steven Morris (*Bases de datos: Diseño, implementación y administración*)  
**Motor:** PostgreSQL 15+ / Supabase BaaS  

---

## 1. Resumen de Tablas y Cardinalidades

| Nombre de Tabla | Tipo de Entidad | Cardinalidad / Conexión | Descripción del Negocio |
| :--- | :--- | :--- | :--- |
| **`perfiles`** | Fuerte (Independiente) | 1:1 con `auth.users` | Identidad del usuario en la app (nombre, correo, rol). |
| **`instituciones`** | Débil (Especialización) | 1:0..1 con `perfiles` | Datos de universidades/organismos oferentes verificados. |
| **`becas`** | Dependiente (1:N) | N:1 con `instituciones` | Convocatorias de becas y oportunidades de estudio. |
| **`becas_guardadas`** | Asociativa (M:N) | N:1 con `perfiles`, N:1 con `becas` | Seguimiento personal y guardado de becas por estudiantes. |
| **`preferencias_notificacion`** | Débil (Especialización) | 1:1 con `perfiles` | Configuración granular de alertas de vencimiento. |

---

## 2. Tipos de Datos Enumerados (Dominios Controlados)

* **`rol_usuario_enum`:** `'estudiante'`, `'institucion'`, `'admin'`
* **`nivel_academico_enum`:** `'secundaria'`, `'grado'`, `'posgrado'`, `'maestria'`, `'doctorado'`
* **`modalidad_enum`:** `'presencial'`, `'virtual'`, `'hibrida'`
* **`estado_beca_enum`:** `'borrador'`, `'activa'`, `'cerrada'`

---

## 3. Catálogo Detallado de Tablas

### Tabla 1: `perfiles`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK, FK** | NO | `auth.uid()` | Llave primaria vinculada a `auth.users(id)` con eliminación en cascada. |
| `correo` | `VARCHAR(255)` | **UK** | NO | Ninguno | Correo electrónico único. Validación regex: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`. |
| `nombre_completo` | `VARCHAR(150)` | --- | NO | Ninguno | Nombre y apellidos. Validación: longitud mínima de 3 caracteres. |
| `rol` | `rol_usuario_enum` | --- | NO | `'estudiante'` | Rol en la plataforma: `'estudiante'`, `'institucion'` o `'admin'`. |
| `terminos_aceptados_en`| `TIMESTAMPTZ` | --- | NO | `NOW()` | Marca temporal de consentimiento legal obligatorio. |
| `creado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Auditoría de creación de cuenta. |

---

### Tabla 2: `instituciones`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK, FK** | NO | Ninguno | Llave primaria referenciada a `perfiles(id)` con eliminación en cascada. |
| `nombre` | `VARCHAR(200)` | --- | NO | Ninguno | Nombre oficial o razón social de la entidad (mínimo 3 caracteres). |
| `pais` | `VARCHAR(100)` | --- | NO | Ninguno | País de origen o sede principal. |
| `sitio_web` | `VARCHAR(300)` | --- | SÍ | `NULL` | Enlace al portal web oficial. Debe iniciar con `http://` o `https://`. |
| `url_logo` | `VARCHAR(500)` | --- | SÍ | `NULL` | URL de la imagen del logotipo en Supabase Storage. |
| `esta_verificada` | `BOOLEAN` | --- | NO | `FALSE` | Control anti-fraude: solo si es `TRUE` puede publicar convocatorias. |
| `descripcion` | `TEXT` | --- | SÍ | `NULL` | Reseña institucional y acreditaciones. |
| `verificada_en` | `TIMESTAMPTZ` | --- | SÍ | `NULL` | Fecha y hora en que fue aprobada por un administrador. |
| `verificado_por` | `UUID` | **FK** | SÍ | `NULL` | Auditoría forense: FK hacia `perfiles(id)` del administrador que aprobó. |

---

### Tabla 3: `becas`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK** | NO | `gen_random_uuid()` | Identificador universal único de la convocatoria. |
| `institucion_id` | `UUID` | **FK** | NO | Ninguno | Llave foránea hacia `instituciones(id)` con eliminación en cascada. |
| `titulo` | `VARCHAR(250)` | --- | NO | Ninguno | Título descriptivo de la beca (mínimo 5 caracteres). |
| `descripcion` | `TEXT` | --- | NO | Ninguno | Bases completas, beneficios y requisitos del programa. |
| `nivel_academico` | `nivel_academico_enum`| --- | NO | Ninguno | Nivel: `'secundaria'`, `'grado'`, `'posgrado'`, `'maestria'`, `'doctorado'`. |
| `area_estudio` | `VARCHAR(120)` | --- | NO | Ninguno | Campo disciplinar (ej. Ingeniería, Salud, Negocios, Arte). |
| `pais` | `VARCHAR(100)` | --- | NO | Ninguno | País de destino o sede del programa de estudio. |
| `modalidad` | `modalidad_enum` | --- | NO | `'presencial'` | Modalidad: `'presencial'`, `'virtual'`, `'hibrida'`. |
| `fecha_limite` | `DATE` | --- | NO | Ninguno | Fecha de cierre de postulaciones (`CHECK (fecha_limite >= CURRENT_DATE)`). |
| `enlace_oficial` | `VARCHAR(500)` | --- | NO | Ninguno | URL oficial externa para postularse (`^https?://`). |
| `estado` | `estado_beca_enum` | --- | NO | `'activa'` | Estado: `'borrador'`, `'activa'`, `'cerrada'`. |
| `creado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Marca temporal de auditoría de publicación. |

---

### Tabla 4: `becas_guardadas`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `id` | `UUID` | **PK** | NO | `gen_random_uuid()` | Identificador único del registro de seguimiento. |
| `perfil_id` | `UUID` | **FK, UK** | NO | Ninguno | FK hacia `perfiles(id)`. Parte de clave única compuesta. |
| `beca_id` | `UUID` | **FK, UK** | NO | Ninguno | FK hacia `becas(id)`. Parte de clave única compuesta. |
| `ya_aplique` | `BOOLEAN` | --- | NO | `FALSE` | Bandera de seguimiento: `TRUE` si el estudiante ya postuló formalmente. |
| `guardado_en` | `TIMESTAMPTZ` | --- | NO | `NOW()` | Fecha y hora en que se guardó en la lista personal. |

> **Restricción de Unicidad:** `CONSTRAINT uq_perfil_beca UNIQUE (perfil_id, beca_id)` garantiza que un estudiante no duplique una beca en su lista de guardadas.

---

### Tabla 5: `preferencias_notificacion`
| Campo / Atributo | Tipo de Dato | Pk / Fk / Uk | Nulo | Valor por Defecto | Descripción y Regla de Integridad |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `perfil_id` | `UUID` | **PK, FK** | NO | Ninguno | Llave primaria referenciada a `perfiles(id)` (1 a 1). |
| `notificar_7_dias` | `BOOLEAN` | --- | NO | `TRUE` | Consentimiento de alerta preventiva 7 días antes del cierre. |
| `notificar_24_horas`| `BOOLEAN` | --- | NO | `TRUE` | Consentimiento de alerta urgente 24 horas antes del cierre. |
