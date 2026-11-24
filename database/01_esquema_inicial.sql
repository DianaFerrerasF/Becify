-- ============================================================================
-- PROYECTO: BECIFY (App Móvil de Becas y Oportunidades Académicas)
-- SCRIPT DDL: 01_esquema_inicial.sql
-- AUTOR: Deurys Mercedes Batista (Líder de Base de Datos y Ciberseguridad)
-- METODOLOGÍA: Carlos Coronel & Steven Morris (Diseño Relacional en 3FN)
-- MOTOR: PostgreSQL 15+ / Supabase BaaS
-- FECHA: Noviembre 2026
-- ============================================================================

-- Habilitar extensiones criptográficas para identificadores UUID v4
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

-- ----------------------------------------------------------------------------
-- 1. TIPOS DE DATOS ENUMERADOS (DOMINIOS CONTROLADOS)
-- ----------------------------------------------------------------------------

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

CREATE TYPE estado_beca_enum AS ENUM (
    'borrador',
    'activa',
    'cerrada'
);

-- ----------------------------------------------------------------------------
-- 2. TABLA: perfiles (Entidad Fuerte - Identidad del usuario en la app)
-- ----------------------------------------------------------------------------

CREATE TABLE perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    correo VARCHAR(255) NOT NULL UNIQUE,
    nombre_completo VARCHAR(150) NOT NULL,
    rol rol_usuario_enum NOT NULL DEFAULT 'estudiante',
    terminos_aceptados_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_correo_formato CHECK (correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_nombre_longitud CHECK (length(trim(nombre_completo)) >= 3)
);

COMMENT ON TABLE perfiles IS 'Perfiles de usuario en la app vinculados al motor de autenticación auth.users de Supabase.';

-- ----------------------------------------------------------------------------
-- 3. FUNCIÓN DE SEGURIDAD: es_admin() (Control de Acceso Basado en Roles - RBAC)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION es_admin() 
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM perfiles 
    WHERE id = auth.uid() AND rol = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

COMMENT ON FUNCTION es_admin() IS 'Verifica si el usuario autenticado actual posee el rol de administrador.';

-- ----------------------------------------------------------------------------
-- 4. TABLA: instituciones (Especialización 1:1 de perfiles)
-- ----------------------------------------------------------------------------

CREATE TABLE instituciones (
    id UUID PRIMARY KEY REFERENCES perfiles(id) ON DELETE CASCADE,
    nombre VARCHAR(200) NOT NULL,
    pais VARCHAR(100) NOT NULL,
    sitio_web VARCHAR(300),
    url_logo VARCHAR(500),
    esta_verificada BOOLEAN NOT NULL DEFAULT FALSE,
    descripcion TEXT,
    verificada_en TIMESTAMPTZ,
    verificado_por UUID REFERENCES perfiles(id) ON DELETE SET NULL, -- Auditoría forense: admin que aprobó
    
    CONSTRAINT chk_institucion_nombre CHECK (length(trim(nombre)) >= 3),
    CONSTRAINT chk_institucion_web CHECK (sitio_web IS NULL OR sitio_web ~* '^https?://')
);

COMMENT ON TABLE instituciones IS 'Información corporativa de universidades y entidades oferentes de becas.';

-- ----------------------------------------------------------------------------
-- 5. TABLA: becas (Entidad Dependiente 1:N con instituciones)
-- ----------------------------------------------------------------------------

CREATE TABLE becas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institucion_id UUID NOT NULL REFERENCES instituciones(id) ON DELETE CASCADE,
    titulo VARCHAR(250) NOT NULL,
    descripcion TEXT NOT NULL,
    nivel_academico nivel_academico_enum NOT NULL,
    area_estudio VARCHAR(120) NOT NULL,
    pais VARCHAR(100) NOT NULL,
    modalidad modalidad_enum NOT NULL DEFAULT 'presencial',
    fecha_limite DATE NOT NULL,
    enlace_oficial VARCHAR(500) NOT NULL,
    estado estado_beca_enum NOT NULL DEFAULT 'activa',
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_beca_titulo CHECK (length(trim(titulo)) >= 5),
    CONSTRAINT chk_beca_enlace CHECK (enlace_oficial ~* '^https?://')
);

COMMENT ON TABLE becas IS 'Convocatorias de becas publicadas por instituciones verificadas.';

-- ----------------------------------------------------------------------------
-- 6. TABLA: becas_guardadas (Entidad Asociativa M:N)
-- ----------------------------------------------------------------------------

CREATE TABLE becas_guardadas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    beca_id UUID NOT NULL REFERENCES becas(id) ON DELETE CASCADE,
    ya_aplique BOOLEAN NOT NULL DEFAULT FALSE,
    guardado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Regla de Negocio: Un perfil no puede duplicar una misma beca guardada
    CONSTRAINT uq_perfil_beca UNIQUE (perfil_id, beca_id)
);

COMMENT ON TABLE becas_guardadas IS 'Tabla asociativa que gestiona el seguimiento y guardado de becas por parte de los estudiantes.';

-- ----------------------------------------------------------------------------
-- 7. TABLA: preferencias_notificacion (Especialización 1:1 de perfiles)
-- ----------------------------------------------------------------------------

CREATE TABLE preferencias_notificacion (
    perfil_id UUID PRIMARY KEY REFERENCES perfiles(id) ON DELETE CASCADE,
    notificar_7_dias BOOLEAN NOT NULL DEFAULT TRUE,
    notificar_24_horas BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE preferencias_notificacion IS 'Ajustes granulares y consentimiento de notificaciones push de vencimiento.';

-- ----------------------------------------------------------------------------
-- 8. ÍNDICES DE RENDIMIENTO (OPTIMIZACIÓN DEL FEED Y BÚSQUEDA)
-- ----------------------------------------------------------------------------

-- Índices en claves foráneas para optimizar operaciones de JOIN
CREATE INDEX idx_becas_institucion_id ON becas(institucion_id);
CREATE INDEX idx_becas_guardadas_perfil_id ON becas_guardadas(perfil_id);
CREATE INDEX idx_becas_guardadas_beca_id ON becas_guardadas(beca_id);
CREATE INDEX idx_instituciones_verificado_por ON instituciones(verificado_por);

-- Índice compuesto para el feed principal móvil (RNF-03: respuestas < 500 ms)
CREATE INDEX idx_becas_feed_filtros ON becas(estado, nivel_academico, modalidad, pais, fecha_limite);
CREATE INDEX idx_becas_area_estudio ON becas(area_estudio);
