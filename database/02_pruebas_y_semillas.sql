-- ============================================================================
-- PROYECTO: BECIFY (App Móvil de Becas y Oportunidades Académicas)
-- SCRIPT DE PRUEBAS Y DATOS SEMILLA (SEED DATA): 02_pruebas_y_semillas.sql
-- AUTOR: Deurys Mercedes Batista (Líder de Base de Datos y Ciberseguridad)
-- OBJETIVO: Verificar restricciones, integridad referencial y consultas clave
-- MOTOR: PostgreSQL 15+ / Supabase BaaS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PARTE 1: LIMPIEZA DE DATOS PREVIOS (ORDEN INVERSO DE INTEGRIDAD REFERENCIAL)
-- ----------------------------------------------------------------------------
DELETE FROM becas_guardadas;
DELETE FROM preferencias_notificacion;
DELETE FROM becas;
DELETE FROM instituciones;
DELETE FROM perfiles;
DELETE FROM auth.users;

-- ----------------------------------------------------------------------------
-- PARTE 2: INSERCIÓN DE IDENTIDADES EN MOTOR AUTH
-- ----------------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin@becify.app'),
('a0000000-0000-0000-0000-000000000002', 'becas@intec.edu.do'),
('a0000000-0000-0000-0000-000000000003', 'estudiante.demo@intec.edu.do');

-- ----------------------------------------------------------------------------
-- PARTE 3: INSERCIÓN DE PERFILES (ESTUDIANTE, INSTITUCIÓN Y ADMIN)
-- ----------------------------------------------------------------------------
INSERT INTO perfiles (id, correo, nombre_completo, rol) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin@becify.app', 'Deurys Batista (Admin)', 'admin'),
('a0000000-0000-0000-0000-000000000002', 'becas@intec.edu.do', 'Instituto Tecnológico de Santo Domingo', 'institucion'),
('a0000000-0000-0000-0000-000000000003', 'estudiante.demo@intec.edu.do', 'Carlos Santana Méndez', 'estudiante');

-- ----------------------------------------------------------------------------
-- PARTE 4: INSERCIÓN DE INSTITUCIÓN (AUDITADA Y VERIFICADA POR ADMIN)
-- ----------------------------------------------------------------------------
INSERT INTO instituciones (id, nombre, pais, sitio_web, url_logo, esta_verificada, descripcion, verificada_en, verificado_por) VALUES
('a0000000-0000-0000-0000-000000000002', 'INTEC - Instituto Tecnológico de Santo Domingo', 'República Dominicana', 'https://www.intec.edu.do', 'https://www.intec.edu.do/images/logo.png', TRUE, 'Universidad líder en ingenierías, ciencias y tecnologías en RD.', NOW(), 'a0000000-0000-0000-0000-000000000001');

-- ----------------------------------------------------------------------------
-- PARTE 5: INSERCIÓN DE PREFERENCIAS DE NOTIFICACIÓN PUSH
-- ----------------------------------------------------------------------------
INSERT INTO preferencias_notificacion (perfil_id, notificar_7_dias, notificar_24_horas) VALUES
('a0000000-0000-0000-0000-000000000003', TRUE, TRUE);

-- ----------------------------------------------------------------------------
-- PARTE 6: INSERCIÓN DE CONVOCATORIAS DE BECAS REALES
-- ----------------------------------------------------------------------------
INSERT INTO becas (id, institucion_id, titulo, descripcion, nivel_academico, area_estudio, pais, modalidad, fecha_limite, enlace_oficial, estado) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Programa PIES - Beca de Excelencia Académica', 'Beca de cobertura total o parcial para bachilleres sobresalientes en carreras de ingeniería y ciencias.', 'grado', 'Ingeniería y Tecnología', 'República Dominicana', 'presencial', '2026-12-15', 'https://www.intec.edu.do/admisiones/becas-pies', 'activa'),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'Beca de Posgrado en Ciberseguridad y Forense Digital', 'Programa de maestría financiado para graduados con mérito académico en ciencias de la computación.', 'posgrado', 'Ciberseguridad y Redes', 'República Dominicana', 'hibrida', '2026-12-30', 'https://www.intec.edu.do/posgrado/ciberseguridad', 'activa');

-- ----------------------------------------------------------------------------
-- PARTE 7: INSERCIÓN DE BECA GUARDADA (SEGUIMIENTO DE ESTUDIANTE)
-- ----------------------------------------------------------------------------
INSERT INTO becas_guardadas (perfil_id, beca_id, ya_aplique) VALUES
('a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', FALSE);

-- ============================================================================
-- PARTE 8: CONSULTAS DE VALIDACIÓN DE NEGOCIO (QUERIES DE PRUEBA)
-- ============================================================================

-- Consulta 1: Feed Principal Móvil (Filtro por becas activas + JOIN con institución)
SELECT 
    b.id AS beca_id,
    b.titulo,
    b.nivel_academico,
    b.modalidad,
    b.fecha_limite,
    i.nombre AS institucion_nombre,
    i.url_logo AS institucion_logo,
    i.esta_verificada
FROM becas b
JOIN instituciones i ON b.institucion_id = i.id
WHERE b.estado = 'activa'
ORDER BY b.fecha_limite ASC;

-- Consulta 2: Pestaña "Mis Becas Guardadas" de un estudiante
SELECT 
    p.nombre_completo AS estudiante,
    b.titulo AS beca,
    i.nombre AS institucion,
    bg.ya_aplique,
    bg.guardado_en
FROM becas_guardadas bg
JOIN perfiles p ON bg.perfil_id = p.id
JOIN becas b ON bg.beca_id = b.id
JOIN instituciones i ON b.institucion_id = i.id
WHERE bg.perfil_id = 'a0000000-0000-0000-0000-000000000003';

-- Consulta 3: Auditoría Forense y Seguridad (Verificación institucional por Admin)
SELECT 
    i.nombre AS institucion,
    i.esta_verificada,
    i.verificada_en,
    admin_p.nombre_completo AS aprobado_por,
    admin_p.correo AS correo_auditor
FROM instituciones i
JOIN perfiles admin_p ON i.verificado_por = admin_p.id;

-- ============================================================================
-- PARTE 9: PRUEBAS DE CIBERSEGURIDAD Y RESTRICCIONES (NEGATIVE TESTING)
-- NOTA: Estas consultas DEBEN FALLAR para comprobar que el motor protege los datos
-- ============================================================================

-- Prueba Negativa 1: Intentar insertar un correo inválido (Debe violar chk_correo_formato)
-- INSERT INTO perfiles (id, correo, nombre_completo) VALUES (gen_random_uuid(), 'correo_invalido', 'Test Error');

-- Prueba Negativa 2: Intentar guardar la misma beca dos veces (Debe violar uq_perfil_beca)
-- INSERT INTO becas_guardadas (perfil_id, beca_id) VALUES ('a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001');

-- Prueba Negativa 3: Intentar insertar enlace web no HTTP/HTTPS (Debe violar chk_beca_enlace)
-- INSERT INTO becas (institucion_id, titulo, descripcion, nivel_academico, area_estudio, pais, fecha_limite, enlace_oficial)
-- VALUES ('a0000000-0000-0000-0000-000000000002', 'Beca Insegura', 'Desc', 'grado', 'TIC', 'RD', '2026-12-31', 'ftp://enlace-no-seguro.com');
