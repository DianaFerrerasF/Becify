-- ============================================================================
-- PRUEBAS ALINEADAS A REGLAS DE NEGOCIO (RN-01 a RN-43)
-- ============================================================================

-- 0. LIMPIEZA PREVIA (Orden inverso de dependencias)
DELETE FROM reportes;
DELETE FROM becas_guardadas;
DELETE FROM preferencias_notificacion;
DELETE FROM becas;
DELETE FROM instituciones;
DELETE FROM perfiles;
DELETE FROM auth.users;

-- 1. IDENTIDADES AUTH
INSERT INTO auth.users (id, email) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin@becify.app'),
('a0000000-0000-0000-0000-000000000002', 'becas@intec.edu.do'),
('a0000000-0000-0000-0000-000000000003', 'carlos@intec.edu.do'),
('a0000000-0000-0000-0000-000000000004', 'menor@test.com');

-- 2. PERFILES (RN-01, RN-07, RN-38)
INSERT INTO perfiles (id, correo, nombre_completo, rol, tramo_edad, version_terminos, consentimiento_datos_en) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin@becify.app', 'Deurys Batista (Admin)', 'admin', '18_o_mas', '1.0', NOW()),
('a0000000-0000-0000-0000-000000000002', 'becas@intec.edu.do', 'Instituto Tecnologico de Santo Domingo', 'institucion', '18_o_mas', '1.0', NOW()),
('a0000000-0000-0000-0000-000000000003', 'carlos@intec.edu.do', 'Carlos Santana Mendez', 'estudiante', '18_o_mas', '1.0', NOW());

-- RN-38: Estudiante menor (13-17) con datos de tutor obligatorios
INSERT INTO perfiles (id, correo, nombre_completo, rol, tramo_edad, tutor_nombre, tutor_correo, tutor_resolucion, version_terminos, consentimiento_datos_en) VALUES
('a0000000-0000-0000-0000-000000000004', 'menor@test.com', 'Ana Garcia Lopez', 'estudiante', 'entre_13_y_17', 'Maria Lopez', 'maria.lopez@gmail.com', 'pendiente', '1.0', NOW());

-- 3. INSTITUCION en estado pendiente (RN-09)
INSERT INTO instituciones (id, nombre, pais, sitio_web, url_logo, descripcion, estado) VALUES
('a0000000-0000-0000-0000-000000000002', 'INTEC - Instituto Tecnologico de Santo Domingo', 'Republica Dominicana', 'https://www.intec.edu.do', 'https://www.intec.edu.do/images/logo.png', 'Universidad lider en ingenieria en RD.', 'pendiente');

-- 4. APROBAR institucion (RN-09, RN-36)
UPDATE instituciones SET
    estado = 'aprobada',
    verificada_en = NOW(),
    verificado_por = 'a0000000-0000-0000-0000-000000000001',
    asignado_a = 'a0000000-0000-0000-0000-000000000001',
    motivo_resolucion = 'Dominio oficial intec.edu.do verificado y sitio web activo'
WHERE id = 'a0000000-0000-0000-0000-000000000002';

-- 5. PREFERENCIAS (RN-30)
INSERT INTO preferencias_notificacion (perfil_id, notificar_7_dias, notificar_24_horas, notificar_cambios_beca) VALUES
('a0000000-0000-0000-0000-000000000003', TRUE, TRUE, TRUE);

-- 6. BECAS con tipo_oportunidad y todas_las_carreras (RN-14, RN-15, RN-16)
INSERT INTO becas (id, institucion_id, titulo, descripcion, nivel_academico, area_estudio, todas_las_carreras, pais, modalidad, tipo_oportunidad, fecha_limite, enlace_oficial, estado) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Programa PIES - Beca de Excelencia Academica', 'Beca total para bachilleres sobresalientes.', 'grado', 'Ingenieria y Tecnologia', FALSE, 'Republica Dominicana', 'presencial', 'beca_completa', '2026-12-15', 'https://www.intec.edu.do/admisiones/becas-pies', 'activa'),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'Intercambio Academico INTEC-MIT', 'Intercambio de un semestre para posgrado.', 'posgrado', 'Ciberseguridad y Redes', FALSE, 'Estados Unidos', 'presencial', 'intercambio', '2026-12-30', 'https://www.intec.edu.do/posgrado/intercambios', 'activa'),
('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'Beca de Secundaria - Programa Futuro', 'Beca parcial para secundaria.', 'secundaria', 'General', TRUE, 'Republica Dominicana', 'presencial', 'beca_parcial', '2027-01-15', 'https://www.intec.edu.do/secundaria/futuro', 'activa');

-- 7. BECA GUARDADA con marca "Ya aplique" (RN-21, RN-22)
INSERT INTO becas_guardadas (perfil_id, beca_id, ya_aplique, aplicada_en) VALUES
('a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', TRUE, NOW());

-- 8. REPORTE de estudiante (RN-40)
INSERT INTO reportes (beca_id, reportado_por, motivo) VALUES
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'El enlace redirige a un sitio diferente al de INTEC');

-- ============================================================================
-- CONSULTAS DE VALIDACION
-- ============================================================================

-- Feed de becas activas solo de instituciones aprobadas (RN-02, RN-09, RN-14)
SELECT b.titulo, b.tipo_oportunidad, b.nivel_academico, b.modalidad, b.pais, b.fecha_limite,
       i.nombre AS institucion, i.estado AS estado_institucion
FROM becas b
JOIN instituciones i ON b.institucion_id = i.id
WHERE b.estado = 'activa' AND i.estado = 'aprobada'
ORDER BY b.fecha_limite ASC;

-- Verificar menor con tutor (RN-38)
SELECT nombre_completo, tramo_edad, tutor_nombre, tutor_correo, tutor_resolucion
FROM perfiles WHERE tramo_edad = 'entre_13_y_17';

-- Auditoria de verificacion institucional (RN-09, RN-36)
SELECT i.nombre, i.estado, i.verificada_en, i.motivo_resolucion,
       p.nombre_completo AS aprobado_por
FROM instituciones i
JOIN perfiles p ON i.verificado_por = p.id;

-- Reportes pendientes de resolucion (RN-40)
SELECT r.motivo, r.creado_en, b.titulo AS beca_reportada,
       p.nombre_completo AS reportado_por
FROM reportes r
JOIN becas b ON r.beca_id = b.id
JOIN perfiles p ON r.reportado_por = p.id
WHERE r.resuelto_en IS NULL;
