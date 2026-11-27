-- ============================================================================
-- PROYECTO: BECIFY (App Móvil de Becas y Oportunidades Académicas)
-- SCRIPT DDL: 01_esquema_inicial.sql
-- AUTOR: Deurys Mercedes Batista (Líder de Base de Datos y Ciberseguridad)
-- METODOLOGÍA: Carlos Coronel & Steven Morris (Diseño Relacional en 3FN)
-- MOTOR: PostgreSQL 15+ / Supabase BaaS
-- FECHA: Noviembre 2026
-- ALINEADO CON: docs/sprint-0/01-reglas-de-negocio.md (RN-01 a RN-43)
-- ============================================================================

-- Habilitar extensiones para generar identificadores únicos UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- COMPATIBILIDAD CON ENTORNO LOCAL Y SUPABASE
-- Si se ejecuta en PostgreSQL local (donde no existe el esquema 'auth' de Supabase),
-- este bloque crea un esquema mínimo de emulación. En Supabase en la nube se omite.
-- ----------------------------------------------------------------------------
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN 
        CREATE SCHEMA auth; 
        CREATE TABLE auth.users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email VARCHAR(255)
        ); 
        CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $f$ 
            SELECT '00000000-0000-0000-0000-000000000000'::UUID; 
        $f$ LANGUAGE sql; 
    END IF; 
END $$;

-- ============================================================================
-- 1. TIPOS DE DATOS ENUMERADOS (DOMINIOS CONTROLADOS)
-- ============================================================================

-- RN-01: Tres roles con exactamente un rol por cuenta
CREATE TYPE rol_usuario_enum AS ENUM (
    'estudiante',
    'institucion',
    'admin'
);

CREATE TYPE nivel_academico_enum AS ENUM (
    'secundaria',
    'grado',
    'posgrado',
    'maestria',
    'doctorado'
);

CREATE TYPE modalidad_enum AS ENUM (
    'presencial',
    'virtual',
    'hibrida'
);

-- RN-14: Tipo de oportunidad diferenciado de la modalidad
CREATE TYPE tipo_oportunidad_enum AS ENUM (
    'beca_completa',
    'beca_parcial',
    'intercambio',
    'pasantia'
);

-- RN-17: Ciclo de estados de una oportunidad (borrador → activa → cerrada/retirada)
CREATE TYPE estado_beca_enum AS ENUM (
    'borrador',
    'activa',
    'cerrada',
    'retirada'
);

-- RN-09: Estados del ciclo de verificación institucional
CREATE TYPE estado_institucion_enum AS ENUM (
    'pendiente',
    'aprobada',
    'rechazada',
    'suspendida',
    'dada_de_baja'
);

-- RN-38: Tramos de edad para el registro (nunca se almacena fecha de nacimiento exacta)
CREATE TYPE tramo_edad_enum AS ENUM (
    'menor_13',
    'entre_13_y_17',
    '18_o_mas'
);

-- RN-38: Resolución del tutor legal para menores de 13 a 17 años
CREATE TYPE tutor_resolucion_enum AS ENUM (
    'pendiente',
    'validada',
    'no_autorizada',
    'vencida'
);

-- ============================================================================
-- 2. TABLA: perfiles (RN-01, RN-04, RN-05, RN-06, RN-07, RN-25, RN-38)
-- ============================================================================

CREATE TABLE perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    correo VARCHAR(255) NOT NULL UNIQUE,                              -- RN-06: Un correo = una cuenta
    nombre_completo VARCHAR(150) NOT NULL,                            -- RN-25: Dato mínimo de perfil
    rol rol_usuario_enum NOT NULL DEFAULT 'estudiante',               -- RN-01: Exactamente un rol

    -- RN-07: Consentimiento informado (términos + datos personales por separado)
    terminos_aceptados_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version_terminos VARCHAR(20) NOT NULL DEFAULT '1.0',              -- RN-07: Versión aceptada
    consentimiento_datos_en TIMESTAMPTZ,                              -- RN-07: Casilla independiente de datos

    -- RN-38: Tramo de edad y datos del tutor legal (solo para 13 a 17 años)
    tramo_edad tramo_edad_enum NOT NULL DEFAULT '18_o_mas',
    tutor_nombre VARCHAR(150),                                        -- RN-38: Obligatorio si entre_13_y_17
    tutor_correo VARCHAR(255),                                        -- RN-38: Obligatorio si entre_13_y_17
    tutor_aviso_enviado_en TIMESTAMPTZ,                               -- RN-38: Fecha de envío del correo al tutor
    tutor_resolucion tutor_resolucion_enum DEFAULT 'pendiente',       -- RN-38: Estado de la validación
    tutor_resuelto_en TIMESTAMPTZ,                                    -- RN-38: Fecha en que el tutor respondió

    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Restricciones de integridad
    CONSTRAINT chk_correo_formato CHECK (correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_nombre_longitud CHECK (length(trim(nombre_completo)) >= 3),

    -- RN-38: Si el tramo es entre_13_y_17, el nombre y correo del tutor son obligatorios
    CONSTRAINT chk_tutor_obligatorio CHECK (
        tramo_edad != 'entre_13_y_17'
        OR (tutor_nombre IS NOT NULL AND tutor_correo IS NOT NULL)
    ),

    -- RN-38: Formato de correo del tutor
    CONSTRAINT chk_tutor_correo_formato CHECK (
        tutor_correo IS NULL
        OR tutor_correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

COMMENT ON TABLE perfiles IS 'Perfiles de usuario vinculados a auth.users. Incluye consentimiento (RN-07), tramo de edad y datos de tutor legal para menores (RN-38).';

-- ============================================================================
-- 3. FUNCIÓN DE SEGURIDAD: es_admin() (RN-09, RN-36)
-- ============================================================================

CREATE OR REPLACE FUNCTION es_admin() 
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM perfiles 
    WHERE id = auth.uid() AND rol = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

COMMENT ON FUNCTION es_admin() IS 'Verifica si el usuario autenticado actual posee el rol de administrador (RN-36).';

-- ============================================================================
-- 4. TABLA: instituciones (RN-09, RN-10, RN-11, RN-12, RN-13, RN-36, RN-37)
-- ============================================================================

CREATE TABLE instituciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_id UUID UNIQUE REFERENCES perfiles(id) ON DELETE SET NULL, -- Cuenta de acceso (pasa a NULL si la institución se da de baja, RN-08)
    nombre VARCHAR(200) NOT NULL,
    pais VARCHAR(100) NOT NULL,
    sitio_web VARCHAR(300),                                           -- RN-10: Sitio web oficial verificable
    url_logo VARCHAR(500),
    descripcion TEXT,

    -- RN-09: Ciclo de estados de verificación institucional
    estado estado_institucion_enum NOT NULL DEFAULT 'pendiente',
    asignado_a UUID REFERENCES perfiles(id) ON DELETE SET NULL,       -- RN-09: Admin asignado para revisar
    verificada_en TIMESTAMPTZ,                                        -- RN-09: Fecha de resolución
    verificado_por UUID REFERENCES perfiles(id) ON DELETE SET NULL,   -- RN-36/RN-37: Admin que resolvió
    motivo_resolucion TEXT,                                            -- RN-09: Motivo de aprobación/rechazo/suspensión

    CONSTRAINT chk_institucion_nombre CHECK (length(trim(nombre)) >= 3),
    CONSTRAINT chk_institucion_web CHECK (sitio_web IS NULL OR sitio_web ~* '^https?://')
);

COMMENT ON TABLE instituciones IS 'Información de universidades y entidades oferentes. Estado de verificación con ciclo de vida completo (RN-09).';

-- ============================================================================
-- 5. TABLA: becas / oportunidades (RN-14, RN-15, RN-16, RN-17, RN-18, RN-19, RN-20)
-- ============================================================================

CREATE TABLE becas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institucion_id UUID NOT NULL REFERENCES instituciones(id) ON DELETE RESTRICT, -- RN-20/RN-37: protege el historial contra borrado en cascada

    -- RN-14: Campos obligatorios de una oportunidad
    titulo VARCHAR(250) NOT NULL,
    descripcion TEXT NOT NULL,
    nivel_academico nivel_academico_enum NOT NULL,
    area_estudio VARCHAR(120) NOT NULL,
    todas_las_carreras BOOLEAN NOT NULL DEFAULT FALSE,                -- RN-14/RN-15: Bandera para "Todas las carreras"
    pais VARCHAR(100) NOT NULL,                                       -- RN-14: País de estudio
    modalidad modalidad_enum NOT NULL DEFAULT 'presencial',
    tipo_oportunidad tipo_oportunidad_enum NOT NULL DEFAULT 'beca_completa', -- RN-14: Tipo diferenciado
    fecha_limite DATE NOT NULL,                                       -- RN-16: Siempre obligatoria
    enlace_oficial VARCHAR(500) NOT NULL,                             -- RN-18: Enlace externo de postulación

    -- RN-17: Ciclo de estados con auditoría de cierre y retiro
    estado estado_beca_enum NOT NULL DEFAULT 'borrador',
    motivo_cierre TEXT,                                                -- RN-17: Motivo al cerrar (vencimiento, manual, baja)
    retirada_por UUID REFERENCES perfiles(id) ON DELETE SET NULL,     -- RN-17/RN-40: Admin que retiró
    motivo_retiro TEXT,                                                -- RN-17: Motivo del retiro por moderación
    retirada_en TIMESTAMPTZ,                                          -- RN-17: Fecha del retiro

    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ,                                       -- RN-19: Registro de última modificación

    -- Restricciones de integridad
    CONSTRAINT chk_beca_titulo CHECK (length(trim(titulo)) >= 5),
    CONSTRAINT chk_beca_enlace CHECK (enlace_oficial ~* '^https?://'),

    -- RN-15: Si nivel es secundaria, todas_las_carreras debe ser TRUE
    CONSTRAINT chk_secundaria_todas CHECK (
        nivel_academico != 'secundaria' OR todas_las_carreras = TRUE
    )
);

COMMENT ON TABLE becas IS 'Convocatorias publicadas por instituciones aprobadas. Nunca se eliminan físicamente (RN-20): pasan a cerrada o retirada.';

-- ============================================================================
-- 6. TABLA: becas_guardadas (RN-21, RN-22, RN-23, RN-24)
-- ============================================================================

CREATE TABLE becas_guardadas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    beca_id UUID NOT NULL REFERENCES becas(id) ON DELETE CASCADE,
    ya_aplique BOOLEAN NOT NULL DEFAULT FALSE,
    aplicada_en TIMESTAMPTZ,                                          -- RN-22: Fecha de la marca "Ya apliqué"
    guardado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- RN-21: Un estudiante no puede guardar la misma oportunidad dos veces
    CONSTRAINT uq_perfil_beca UNIQUE (perfil_id, beca_id)
);

COMMENT ON TABLE becas_guardadas IS 'Seguimiento personal del estudiante: favoritos y marca "Ya apliqué" (RN-21 a RN-24). Privada por RLS.';

-- ============================================================================
-- 7. TABLA: preferencias_notificacion (RN-29, RN-30, RN-32, RN-33)
-- ============================================================================

CREATE TABLE preferencias_notificacion (
    perfil_id UUID PRIMARY KEY REFERENCES perfiles(id) ON DELETE CASCADE,
    notificar_7_dias BOOLEAN NOT NULL DEFAULT TRUE,                   -- RN-29: Recordatorio 7 días
    notificar_24_horas BOOLEAN NOT NULL DEFAULT TRUE,                 -- RN-29: Recordatorio 24 horas
    notificar_cambios_beca BOOLEAN NOT NULL DEFAULT TRUE              -- RN-19/RN-29: Aviso de cambios en oportunidad guardada
);

COMMENT ON TABLE preferencias_notificacion IS 'Consentimiento granular de notificaciones push (RN-30). Bandeja interna como fallback si el usuario rechaza push en el SO (RN-32).';

-- ============================================================================
-- 8. TABLA: reportes (RN-40 - Moderación de oportunidades publicadas)
-- ============================================================================

CREATE TABLE reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    beca_id UUID NOT NULL REFERENCES becas(id) ON DELETE RESTRICT, -- RN-37: protege el reporte contra borrado en cascada
    reportado_por UUID REFERENCES perfiles(id) ON DELETE SET NULL,    -- RN-37: SET NULL para preservar el reporte
    motivo TEXT NOT NULL,                                              -- RN-40: Motivo del reporte
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Resolución administrativa (RN-36)
    resuelto_por UUID REFERENCES perfiles(id) ON DELETE SET NULL,     -- RN-36: Admin que resolvió
    resolucion TEXT,                                                   -- RN-40: Decisión tomada
    resuelto_en TIMESTAMPTZ,

    CONSTRAINT chk_motivo_longitud CHECK (length(trim(motivo)) >= 5)
);

COMMENT ON TABLE reportes IS 'Reportes de estudiantes sobre oportunidades sospechosas o incorrectas. Resolución administrativa con auditoría (RN-40, RN-36).';

-- ============================================================================
-- 9. ÍNDICES DE RENDIMIENTO (OPTIMIZACIÓN DEL FEED Y BÚSQUEDA)
-- ============================================================================

-- Índices en claves foráneas para optimizar operaciones de JOIN
CREATE INDEX idx_becas_institucion_id ON becas(institucion_id);
CREATE INDEX idx_becas_guardadas_perfil_id ON becas_guardadas(perfil_id);
CREATE INDEX idx_becas_guardadas_beca_id ON becas_guardadas(beca_id);
CREATE INDEX idx_instituciones_verificado_por ON instituciones(verificado_por);
CREATE INDEX idx_reportes_beca_id ON reportes(beca_id);

-- Índice compuesto para el feed principal móvil (RNF-03: respuestas < 500 ms)
CREATE INDEX idx_becas_feed_filtros ON becas(estado, nivel_academico, modalidad, tipo_oportunidad, pais, fecha_limite);
CREATE INDEX idx_becas_area_estudio ON becas(area_estudio);

-- Índice para filtrar instituciones por estado de verificación (RN-09, RN-12)
CREATE INDEX idx_instituciones_estado ON instituciones(estado);
