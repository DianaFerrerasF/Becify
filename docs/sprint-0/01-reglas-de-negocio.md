# Reglas de Negocio — Becify

| Metadato | Detalle |
| :--- | :--- |
| **Versión** | `1.0` |
| **Estado** | Aprobado para revisión — Baseline Sprint 0 |
| **Sprint** | Sprint 0 |
| **Issue** | [#16](https://github.com/DianaFerrerasF/Becify/issues/16) (`Definir reglas de negocio`) |
| **Autores** | **Diana Estephan Ferreras Feliz** · **Deurys Mercedes Batista** |

---

## 1. Guía de referencia y glosario

### Convenciones de las tablas
- **Fase:** `MVP` (primera versión operativa) o `F2` (Fase 2).
- **Validar:**
  - `⚑`: regla sujeta a confirmación o ajuste con los resultados de la encuesta de requerimientos (`E` = formulario de estudiantes, `I` = formulario de instituciones).
  - `⚖`: regla con valor **provisional** sujeta a validación legal con un abogado (ver sección 4).

> **Nota legal:** Las referencias a la Ley 172-13 (Protección de Datos Personales) y a la Ley 136-03 (Código para el Sistema de Protección y los Derechos Fundamentales de Niños, Niñas y Adolescentes) constituyen lineamientos de diseño preventivo del equipo y no sustituyen asesoría jurídica profesional.

### Glosario del dominio
- **Oportunidad:** beca, programa académico, intercambio, pasantía o convocatoria publicada por una institución.
- **Rol:** tipo de cuenta dentro del sistema (`estudiante`, `institucion`, `admin`).
- **RLS (Row Level Security):** políticas declarativas de PostgreSQL/Supabase que restringen qué filas puede consultar o modificar cada usuario autenticado.
- **Titular de los datos:** persona física a quien pertenecen los datos personales (el usuario).
- **Responsable del tratamiento:** quien decide sobre la finalidad y el tratamiento de los datos (Ley 172-13, Art. 6.18 y 6.43).
- **Encargado del tratamiento:** proveedor o servicio que procesa datos por cuenta del responsable (Art. 6.12).
- **Disociación:** tratamiento de un dato para que no pueda asociarse a una persona determinada o determinable (Art. 6.17).
- **Borrado lógico:** cambio de estado del registro para que deje de mostrarse públicamente sin eliminar la fila física de la base de datos.

---

## 2. Catálogo de reglas de negocio

### 2.1 Cuentas y roles

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-01** | Existen tres roles: `estudiante`, `institucion` y `admin`. Cada cuenta tiene exactamente un rol. | Evita mezclar permisos. En la BD: columna `rol` con dominio controlado (`rol_usuario_enum`). | MVP | |
| **RN-02** | Cualquier persona puede ver el listado y el detalle de las oportunidades publicadas sin iniciar sesión. | Reduce la fricción de entrada. En la BD: lectura pública únicamente de oportunidades publicadas y sin exponer datos de usuarios. | MVP | |
| **RN-03** | Para guardar oportunidades, marcar "ya apliqué", recibir avisos o publicar es obligatorio iniciar sesión. | Toda acción personalizada queda asociada a una cuenta autenticada y protegida por RLS. | MVP | |
| **RN-04** | Se puede crear cuenta con correo y contraseña o con Google. El acceso con Apple se incorpora al publicar la versión para iOS. | Facilita el registro rápido manteniendo compatibilidad con los requisitos de publicación en iOS. | MVP / F2 | ⚑ teléfono (E8) |
| **RN-05** | El correo electrónico debe verificarse antes de ejecutar acciones que requieren cuenta. | Reduce cuentas automatizadas o falsas y errores de digitación en el correo. | MVP | |
| **RN-06** | Un correo electrónico corresponde a una sola cuenta. | Restricción `UNIQUE` sobre el correo en el motor de autenticación y en `perfiles`. | MVP | |
| **RN-07** | Al registrarse se aceptan los términos y la política de privacidad, registrando fecha y versión aceptada. **El consentimiento para tratar datos personales se recoge en una casilla independiente de los términos**, informando: finalidad, destinatarios, identidad y contacto del responsable, derechos de acceso, rectificación y supresión, y almacenamiento en servidores que pueden ubicarse fuera de República Dominicana. Si el usuario es menor de edad (13 a 17 años), se informa además que se enviará un correo de confirmación a su tutor legal (RN-38). | Evidencia auditable de consentimiento (`terminos_aceptados_en`, `version_terminos`, `consentimiento_datos_en`). Cumple el requisito de consentimiento libre, expreso, informado y destacado (Ley 172-13, Art. 5.3, 5.4 y 80). | MVP | ⚖ |
| **RN-08** | El usuario puede eliminar su cuenta desde la app. **Estudiante:** se eliminan de inmediato su perfil, oportunidades guardadas, marcas "ya apliqué" y preferencias (borrado en cascada exclusivo de sus datos; referencia legal de hasta 10 días hábiles en Art. 8). Si la cuenta pertenecía a un menor, se eliminan también los datos del tutor (nombre y correo). **Institución:** se revoca su acceso, sus oportunidades pasan a estado *cerrada* con motivo `baja_institucion` (RN-17) y los registros de auditoría se conservan según RN-37. La baja elimina también la identidad en Supabase Auth. | Cumplimiento del derecho de supresión y de las políticas de Google Play y App Store para aplicaciones con creación de cuentas. Los reportes y la auditoría no se borran en cascada (RN-37). | MVP | ⚖ |
| **RN-38** | **Edad mínima de 13 años y confirmación del tutor.** Al registrarse se selecciona un tramo de edad: `"18 años o más"`, `"entre 13 y 17 años"` o `"menos de 13"`. Quienes tengan menos de 13 años no pueden registrarse en el MVP. Si se indica `"entre 13 y 17 años"`, el formulario solicita tres campos **obligatorios** sobre el tutor legal: (1) **nombre**, (2) **correo electrónico** y (3) una **casilla de compromiso** donde declara que la creación de la cuenta fue consultada con su tutor legal. El documento de identidad del tutor **no se solicita en el MVP** (sujeto a criterio legal en `L-1` y `L-15`). El sistema envía un **correo de confirmación al tutor** informando quién se registró y la finalidad de los datos, con dos opciones: **validar el registro** o **no autorizar**. La cuenta del menor nace en estado *pendiente de tutor*: puede explorar el listado público (RN-02), pero no guardar, marcar "ya apliqué" ni recibir avisos (RN-03) hasta que el tutor valide. Si el tutor **no autoriza** o no responde dentro del plazo definido (provisional: **7 días**), la cuenta y los datos del tutor se eliminan. La casilla se registra con fecha y versión de los términos. | En la BD se almacena solo el tramo (`tramo_edad`), nunca la fecha de nacimiento exacta; para menores se registran `tutor_nombre`, `tutor_correo`, `tutor_aviso_enviado_en`, `tutor_resolucion` (`validada`, `no_autorizada`, `vencida`) y `tutor_resuelto_en`. El tutor no necesita crear cuenta: el enlace de confirmación es de un solo uso, caduca en el plazo definido y su token se guarda con hash (no en texto claro). La Ley 136-03 define adolescente de 13 a 18 años (Principio II) y presume menor ante la duda (Principio III). No se solicita cédula del tutor en el MVP para evitar custodiar documentos de alto riesgo (RN-26). **Datos del tutor (tercero):** se informan en RN-07, se usan exclusivamente para esta validación y se borran con la cuenta o ante rechazo/vencimiento (RN-08). **Prevención de abuso:** se limita la tasa de envíos por dirección y dispositivo, incluyendo en el correo la opción de `"no conozco a esta persona / no autorizar"`. | MVP | ⚖ |
| **RN-39** | **Cuenta de tutor (padre, madre o tutor legal).** Un tutor podrá crear una cuenta para buscar y dar seguimiento a oportunidades en nombre de un menor, manteniendo el control de sus datos (incluyendo menores de 13 años). | Requiere modelo de vínculo tutor-estudiante y flujo de consentimiento verificable. Se define en Fase 2. | F2 | ⚖ |

### 2.2 Instituciones

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-09** | Toda cuenta de institución nace en estado **pendiente** y no puede publicar hasta que un administrador la **apruebe**. Estados posibles: `pendiente`, `aprobada`, `rechazada`, `suspendida` y `dada_de_baja`. Cada solicitud registra el administrador asignado (`asignado_a`), quién la resolvió (`verificado_por` / `resuelto_por`), la fecha (`verificada_en` / `resuelto_en`) y el motivo. | Control preventivo contra convocatorias fraudulentas. En la BD: política RLS que restringe la creación de oportunidades exclusivamente a instituciones aprobadas. | MVP | ⚑ confianza para publicar (I8) |
| **RN-10** | **Criterio provisional de aprobación:** (1) correo con dominio oficial de la institución, (2) sitio web oficial verificable y (3) revisión manual del administrador asignado. | Garantiza legitimidad institucional y promueve el uso de datos de contacto corporativos en lugar de personales (ver RN-41). | MVP | ⚑ (I8) · ⚖ |
| **RN-11** | Una institución solo puede consultar y editar sus propias oportunidades. | Aislamiento por fila (RLS) validando que `institucion_id = auth.uid()`. | MVP | |
| **RN-12** | Si una institución pasa a estado `suspendida`, sus oportunidades dejan de mostrarse en el feed público de inmediato. | Respuesta rápida de contención ante reportes o incumplimientos. | MVP | |
| **RN-13** | En el MVP existe una única cuenta administradora por institución. | Simplifica el modelo de permisos inicial; la gestión multiusuario por institución se evalúa para Fase 2. | MVP | ⚑ (I5, entrevistas) |

### 2.3 Oportunidades

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-14** | Toda oportunidad publicada contiene como mínimo: título, nivel académico, requisitos/descripción, fecha límite, enlace oficial, **país o países de estudio**, **modalidad de estudio**, **tipo de oportunidad** y **carreras o áreas cubiertas (una o más carreras específicas, o la opción "Todas las carreras")**. | Permite búsquedas y filtros precisos. **Carreras:** relación con catálogo de áreas/carreras más bandera `todas_las_carreras`; quien filtra por su carrera ve tanto las específicas como las marcadas para todas. **Países:** país donde se cursa el estudio (o país sede si es virtual). **Modalidad y tipo:** campos diferenciados (`modalidad` = presencial, virtual, híbrida; `tipo_oportunidad` = beca completa, beca parcial, intercambio, pasantía). | MVP | ⚑ datos que publican (I6) |
| **RN-15** | Una oportunidad puede dirigirse a uno o varios niveles académicos: `secundaria`, `grado`, `posgrado`, `maestria`, `doctorado`. **Cuando el nivel es secundaria, el alcance de carreras se marca siempre como "Todas las carreras"** en el MVP. | Evita complejidad de catálogos de especialidades técnicas de nivel medio en el MVP, las cuales se evalúan en Fase 2. | MVP | ⚑ (I2) |
| **RN-16** | **La fecha límite es siempre obligatoria** y no puede estar en el pasado al momento de publicar. En programas de admisión continua, la institución registra la fecha de cierre del ciclo vigente; al vencer, la oportunidad se cierra automáticamente y puede republicarse para el siguiente ciclo. | Evita convocatorias perpetuas o desactualizadas y permite disparar los recordatorios de vencimiento (7 días y 24 horas). Se valida mediante función/trigger al publicar. | MVP | |
| **RN-17** | Ciclo de estados de una oportunidad: **borrador → publicada (`activa`) → cerrada** o **retirada**. **Cerrada:** venció la fecha límite, la institución la cerró manualmente o la institución se dio de baja (registrando `motivo_cierre`). **Retirada:** un administrador la removió por incumplir las normas (registrando `motivo_retiro`, `retirada_por` y `retirada_en`). Solo las publicadas aparecen en el feed; las cerradas y retiradas permanecen visibles con un aviso de estado en la lista personal de quienes las guardaron. | Mantiene el feed limpio y distingue ante el estudiante una convocatoria cuyo plazo expiró de una retirada por moderación. | MVP | |
| **RN-18** | En el MVP la postulación se realiza en el **sitio web oficial** de la institución mediante el enlace externo (`enlace_oficial`). Becify no recibe documentos de postulación. | Minimiza riesgos de seguridad y almacenamiento de documentos sensibles en la primera fase. | MVP | ⚑ formularios propios (E6, I7) y perfil (E9) |
| **RN-19** | Los cambios relevantes en una oportunidad publicada (fecha límite, requisitos) quedan registrados con fecha y autor, y generan un aviso a los estudiantes que la tienen guardada. | Trazabilidad y transparencia para los postulantes. | MVP | |
| **RN-20** | Una oportunidad publicada nunca se elimina físicamente: pasa a estado `cerrada` o `retirada` (borrado lógico). | Preserva el historial de `"guardada"` y `"ya apliqué"` de los estudiantes, evita enlaces rotos sin explicación y conserva evidencia forense en caso de reporte de fraude (RN-36, RN-37). | MVP | |
| **RN-40** | **Publicación directa por instituciones aprobadas con moderación posterior.** Una institución aprobada publica sin cola de revisión previa por cada beca. Cualquier estudiante autenticado puede **reportar** una oportunidad (motivos: posible fraude, datos falsos, vencida u otro). Un administrador revisa el reporte y, si procede, retira la oportunidad (RN-17), registrando reportante, motivo, administrador resolutor, fecha y resolución. | Agiliza la publicación para instituciones ya verificadas (RN-09) manteniendo un control reactivo auditable en una tabla de `reportes` vinculada a las normas de publicación. | MVP | ⚖ |

### 2.4 Estudiantes: guardado y seguimiento

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-21** | Un estudiante puede guardar una misma oportunidad una sola vez. | Restricción de unicidad compuesta `UNIQUE (perfil_id, beca_id)` en `becas_guardadas`. | MVP | |
| **RN-22** | Solo se puede marcar `"ya apliqué"` sobre una oportunidad **vigente** y una sola vez por oportunidad. La marca y su fecha (`aplicada_en`) se conservan aunque la oportunidad cierre posteriormente. | Evita registros duplicados y preserva la bitácora personal de postulaciones del estudiante. | MVP | |
| **RN-23** | El estudiante consulta sus listas de oportunidades guardadas y aplicadas y puede desmarcarlas en cualquier momento. | Política RLS en `becas_guardadas` (`auth.uid() = perfil_id`). | MVP | |
| **RN-24** | La institución **no** tiene acceso a la identidad de quién guardó o marcó `"ya apliqué"` en sus oportunidades durante el MVP. | Privacidad por defecto para el estudiante; la visibilidad de interesados con consentimiento se reserva para Fase 2. | MVP | ⚑ (entrevistas) |

### 2.5 Perfil y protección de datos personales

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-25** | En el MVP solo se recolectan datos mínimos: correo electrónico, nombre o alias de perfil, tramo de edad, preferencias académicas (nivel, carreras/áreas, país) y, únicamente si tiene entre 13 y 17 años, el nombre y el correo electrónico de su tutor legal. **No se solicitan datos sensibles** (salud, religión, ideología, afiliación sindical, vida sexual). **De menores de edad no se almacenan fotografías, calificaciones ni perfiles públicos.** | Principio de minimización y pertinencia de datos (Ley 172-13, Art. 5.8 y Art. 76) y protección de imagen e intimidad de menores (Ley 136-03, Art. 18 y 26). | MVP | ⚑ (E9) · ⚖ |
| **RN-26** | Calificaciones, CV y certificados no se almacenan en el MVP. En Fase 2 se habilitarán únicamente de forma opcional, bajo decisión explícita del estudiante y con posibilidad de borrado inmediato. | Reduce la superficie de exposición de archivos personales y define los requisitos de cifrado en `Supabase Storage` para Fase 2. | F2 | ⚑ (E9) |
| **RN-27** | Los datos personales del estudiante solo son visibles para el propio titular. El acceso de administración se limita a tareas de soporte y deja traza de auditoría. | Políticas RLS por titular y bitácora administrativa. | MVP | |
| **RN-28** | No se comercializan, alquilan ni ceden datos personales de los usuarios a terceros. | Compromiso expreso dentro de la política de privacidad del servicio. | MVP | ⚖ |
| **RN-41** | **Ejercicio de derechos ARCO y canal de atención.** Todo usuario puede solicitar acceso, rectificación o supresión de sus datos a través de `becifyapp@gmail.com` y de los controles de la app. Plazos internos de referencia conforme a la Ley 172-13 (Art. 8 y 10): acceso en 5 días hábiles; rectificación o supresión en 10 días hábiles, bajo procedimiento interno de verificación de identidad (Art. 13.5). El tutor legal de un menor puede solicitar acceso o eliminación de la cuenta por el mismo canal, conforme a la legitimación reconocida a los tutores en la ley (Art. 18). Los datos estrictamente corporativos de representantes institucionales (nombre, cargo, correo y teléfono institucional) se rigen por la excepción del Art. 4.4. | Formaliza el flujo operativo de atención a titulares de datos y representantes legales. | MVP | ⚖ |
| **RN-42** | **Responsable del tratamiento:** el equipo titular del proyecto Becify, con canal oficial de contacto en `becifyapp@gmail.com`. La política de privacidad, el flujo de consentimiento (RN-07) y el canal de atención (RN-41) deben estar publicados antes del registro de usuarios reales. | Cumplimiento del deber de información previa al titular (Ley 172-13, Art. 5.3). | MVP | ⚖ |

### 2.6 Notificaciones

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-29** | Eventos que disparan notificación: recordatorio de fecha límite (**7 días** y **24 horas** antes del cierre) en oportunidades guardadas, modificación de una oportunidad guardada y, en Fase 2, mensaje nuevo o cambio de estado de solicitud. | Alineado con la matriz de eventos definida en `docs/02-stack-y-seguridad.md`. | MVP / F2 | ⚑ (E7) |
| **RN-30** | El estudiante configura qué tipos de avisos desea recibir y puede desactivarlos en cualquier momento. | Previene fatiga de notificaciones. En la BD: tabla `preferencias_notificacion` vinculada 1:1 con `perfiles`. | MVP | ⚑ (E7) |
| **RN-31** | El sistema es idempotente en el envío de alertas: nunca envía dos veces el mismo aviso para el mismo evento y oportunidad. | Control de envíos mediante clave única `(perfil_id, tipo_evento, beca_id)`. | MVP | |
| **RN-32** | Si el usuario no concede permiso de notificaciones push en el sistema operativo móvil, los avisos quedan disponibles en una bandeja interna dentro de la app. | Garantiza que el estudiante no pierda avisos críticos de vencimiento aunque rechace permisos push. | MVP | ⚑ (E8) |
| **RN-33** | El contenido visible de una notificación push no incluye datos personales sensibles, ya que se muestra en la pantalla de bloqueo del dispositivo. | Privacidad en el dispositivo móvil. | MVP | |

### 2.7 Mensajería (Fase 2)

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-34** | Un canal de mensajería entre estudiante e institución solo puede ser iniciado por el estudiante. | Evita comunicaciones no solicitadas o spam hacia los estudiantes. | F2 | ⚑ (E6, I7) |
| **RN-35** | Los mensajes cuentan con opción de reporte y facultad de suspensión de cuenta por parte de un administrador. | Moderación y seguridad en la comunicación. | F2 | |

### 2.8 Administración, trazabilidad y respaldos

| ID | Regla | Por qué / impacto en diseño | Fase | Validar |
| :--- | :--- | :--- | :---: | :---: |
| **RN-36** | Toda acción administrativa (aprobar o suspender instituciones, retirar oportunidades, resolver reportes) registra el administrador autor y la marca de tiempo. | Trazabilidad y auditoría forense. | MVP | |
| **RN-37** | Los registros de auditoría y los reportes son inmutables para usuarios estándar y **no se eliminan en cascada** al darse de baja una cuenta: las claves foráneas hacia usuarios utilizan `ON DELETE SET NULL`. Tras la baja de una institución, el historial de quién la aprobó y sus reportes asociados se conservan por un plazo configurable (**valor provisional: 2 años**) antes de su purga o disociación definitiva. | Preserva la integridad de la evidencia ante incidentes de fraude sin retener datos personales de forma indefinida (Ley 172-13, Art. 15). | MVP | ⚖ |
| **RN-43** | **Política de respaldos.** Mientras se opere en el plan gratuito de Supabase (que no incluye respaldos automáticos gestionados), se realizarán exportaciones periódicas cifradas y almacenadas **fuera del repositorio**, aplicando rotación para eliminar copias antiguas. La política de privacidad informará el plazo máximo de rotación en que los datos de una cuenta eliminada desaparecen de las copias de respaldo. | Continuidad operativa frente a pérdida accidental de datos y transparencia sobre el ciclo de vida en respaldos. | MVP | ⚖ |

---

## 3. Resumen de decisiones de diseño

| # | Tema | Decisión adoptada | Estado | Reglas asociadas |
| :---: | :--- | :--- | :---: | :--- |
| 1 | Menores de edad | Edad mínima 13 años. Entre 13 y 17 años: nombre y correo del tutor y casilla de compromiso obligatorios; correo de confirmación para que el tutor valide o no autorice; cuenta en estado pendiente hasta que valide. Sin documento de identidad en el MVP. Cuenta de tutor en Fase 2. | **Provisional** ⚖ | RN-38, RN-39 |
| 2 | Verificación de instituciones | Dominio de correo oficial, sitio web verificable y aprobación manual por administrador. | **Provisional** | RN-09, RN-10 |
| 3 | Moderación de oportunidades | Publicación directa para instituciones aprobadas con sistema de reportes y retiro posterior. | **Definida** ⚖ | RN-40 |
| 4 | País de la oportunidad | Uno o varios países de destino académico; en modalidad virtual, el país sede de la institución. | **Definida** | RN-14 |
| 5 | Retención tras baja de cuenta | Estudiante: borrado inmediato (incluyendo datos del tutor si aplica). Institución: conservación de auditoría y reportes por parámetro provisional de 2 años. | **Parcial** ⚖ | RN-08, RN-37 |
| 6 | Idioma de la plataforma | MVP en español; arquitectura preparada para internacionalización (`i18n` español/inglés) en Fase 2. | **Definida** | — |
| 7 | Modalidad y tipo | Dos atributos diferenciados: `modalidad` y `tipo_oportunidad`. | **Definida** | RN-14 |
| 8 | Fecha límite de convocatorias | Siempre obligatoria; en admisión continua se registra el cierre del ciclo vigente. | **Definida** | RN-16 |
| 9 | Nivel secundaria y carreras | Se asigna siempre a `"Todas las carreras"` en el MVP; áreas técnicas en Fase 2. | **Definida (MVP)** | RN-15 |

**Puntos abiertos (no bloquean el esquema base):**
- **Plazo para respuesta del tutor (RN-38):** valor provisional de 7 días (confirmar o ajustar con validación legal).
- **Documento de identidad del tutor:** no se solicita en el MVP (confirmar con abogado en `L-1` y `L-15`).
- Límites de tasa de envío (*rate limiting*) de correos a tutores por dirección y por dispositivo.
- Confirmar los catálogos definitivos de valores para `modalidad` y `tipo_oportunidad` tras cerrar la encuesta.
- Definir el domicilio formal a informar por el responsable del tratamiento (RN-42).
- Documentar el protocolo de verificación de identidad para solicitudes ARCO (RN-41).

---

## 4. Consultas para validación legal (reglas marcadas con ⚖)

Las siguientes consultas agrupan los puntos jurídicos pendientes de confirmación con un abogado especialista en derecho digital y protección de datos en República Dominicana:

| # | Consulta legal | Justificación e impacto | Valor provisional en diseño | Reglas |
| :---: | :--- | :--- | :--- | :--- |
| **L-1** | ¿La casilla de compromiso del menor de 13 a 17 años, junto con el correo de confirmación y validación enviada al tutor legal, basta como consentimiento para el tratamiento de sus datos, o se exige otro mecanismo? | La Ley 172-13 (Art. 79) remite a la Ley 136-03 para la protección de datos de menores. | Casilla con fecha y versión de los términos, más correo de confirmación al tutor. | RN-38 |
| **L-2** | ¿Es jurídicamente válido establecer los 13 años como edad mínima de registro para un servicio digital educativo en RD? | La Ley 136-03 define la adolescencia a partir de los 13 años, sin especificar una edad digital de consentimiento. | Edad mínima: 13 años. | RN-38 |
| **L-3** | ¿Qué requisitos de verificación de vínculo y consentimiento debe cumplir la cuenta de tutor para menores de 13 años? | Determina la arquitectura del flujo de tutores planeado para la Fase 2. | Diferido a Fase 2. | RN-39 |
| **L-4** | ¿Cuál es el plazo legal recomendado para conservar registros de auditoría y reportes de fraude tras la baja de una institución? | El Art. 15 de la Ley 172-13 vincula la conservación al plazo de prescripción de responsabilidades legales. | Parámetro configurable de 2 años. | RN-37 |
| **L-5** | Al eliminar una cuenta de estudiante, ¿existe obligación de conservar algún dato desvinculado por razones legales o reportes en los que participó (Art. 8 y 15)? | Define las excepciones técnicas al borrado físico inmediato. | Borrado del perfil y `ON DELETE SET NULL` en reportes. | RN-08, RN-37 |
| **L-6** | Al operar como dos personas físicas sin sociedad comercial constituida, ¿cómo se declara la responsabilidad del tratamiento, qué domicilio se informa y aplica algún registro de banco de datos? | El Art. 5.3 exige informar identidad y domicilio del responsable del tratamiento. | Co-responsables del equipo; domicilio por definir. | RN-42 |
| **L-7** | Para alojar la base de datos en servidores cloud fuera del país (Supabase / Firebase), ¿basta el consentimiento expreso e informado del usuario (Art. 80, numerales 1 y 6)? | Regula la transferencia internacional de datos hacia la infraestructura en la nube. | Consentimiento informado en casilla independiente (RN-07). | RN-07 |
| **L-8** | Revisión formal de los textos de consentimiento, términos de servicio y política de privacidad (finalidad, destinatarios, derechos y casilla separada). | El Art. 5.3 y 5.4 exige información previa clara y consentimiento destacado. | Borradores redactados por el equipo. | RN-07, RN-28 |
| **L-9** | ¿Resultan aplicables los plazos de 5 días hábiles (acceso) y 10 días hábiles (rectificación/supresión), y qué medio de acreditación de identidad es proporcional? | Define el manual interno de atención de derechos (Art. 13.5). | Plazos de referencia de la Ley 172-13. | RN-41 |
| **L-10** | ¿Los datos de contacto corporativo de las instituciones (nombre, cargo, correo y teléfono institucional) quedan cubiertos por la excepción del Art. 4.4? | Determina el alcance de las obligaciones sobre cuentas institucionales. | Exigencia de correo con dominio institucional. | RN-10, RN-41 |
| **L-11** | En relación con las copias de respaldo, ¿cuál es el plazo aceptable de rotación para que los datos de una cuenta eliminada desaparezcan de los respaldos? | Define la política de rotación de exportaciones y su cláusula en el aviso de privacidad. | Rotación periódica documentada en la política. | RN-43 |
| **L-12** | ¿Qué cláusulas de exención de responsabilidad, normas de publicación y facultad de retiro deben incluirse en los términos aceptados por las instituciones? | Cubre la ventana entre la publicación directa y la moderación por reporte (RN-40). | Moderación posterior con facultad de retiro. | RN-40 |
| **L-13** | ¿La encuesta anónima de levantamiento de requerimientos requiere algún aviso adicional si no recolecta datos identificables (Art. 5.3 y 72)? | Verifica el cumplimiento del instrumento de investigación del Sprint 0. | Encuesta anónima; CSV resguardados fuera del repositorio. | — |
| **L-14** | ¿Existen reglamentos complementarios o modificaciones posteriores a la Ley 172-13 aplicables a plataformas móviles en República Dominicana? | Asegura que el marco normativo de referencia esté actualizado. | Ley 172-13 (texto de 2013) y Ley 136-03. | Todas ⚖ |
| **L-15** | Datos del tutor legal (nombre y correo electrónico proporcionados por el menor): ¿qué base legal ampara su tratamiento? ¿Se requiere documento de identidad del tutor? ¿Qué contenido mínimo debe incluir el correo de confirmación y cuál es el plazo de conservación si el tutor no responde o no autoriza? | El dato del tutor pertenece a un tercero que no inició el registro y se recolecta para ejecutar la verificación de RN-38. | Sin documento de identidad; uso exclusivo para verificación, borrado inmediato ante rechazo/vencimiento o baja de cuenta, y límite de envíos. | RN-38, RN-08 |

**Insumos para la sesión de consulta legal:**
1. El presente documento (`01-reglas-de-negocio.md`).
2. Inventario de datos recolectados en el MVP (`correo`, `nombre_completo`, `tramo_edad`, preferencias académicas, token de notificaciones, marcas de tiempo de aceptación y, para el tramo de 13 a 17 años, nombre y correo del tutor legal).
3. Arquitectura de almacenamiento en Supabase y Firebase (`docs/02-stack-y-seguridad.md`).
4. Flujos de registro, validación de tutor, eliminación de cuenta y reporte de oportunidades.

---

## 5. Trazabilidad hacia el modelo de datos (`database/01_esquema_inicial.sql`)

Ejemplos de cómo las reglas de negocio se traducen directamente en restricciones del esquema relacional en PostgreSQL/Supabase ([`database/01_esquema_inicial.sql`](../../database/01_esquema_inicial.sql)):

1. **RN-21 (Unicidad de oportunidades guardadas):** se garantiza a nivel de motor mediante la restricción `UNIQUE (perfil_id, beca_id)` en la tabla `becas_guardadas`:
   ```sql
   CREATE TABLE becas_guardadas (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       perfil_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
       beca_id UUID NOT NULL REFERENCES becas(id) ON DELETE CASCADE,
       ya_aplique BOOLEAN NOT NULL DEFAULT FALSE,
       guardado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
       CONSTRAINT uq_perfil_beca UNIQUE (perfil_id, beca_id)
   );
   ```

2. **RN-09 y RN-37 (Verificación institucional y preservación de auditoría ante bajas):** la tabla `instituciones` nace con `esta_verificada = FALSE` por defecto y registra al administrador que la aprobó con `ON DELETE SET NULL` para no perder la traza forense:
   ```sql
   esta_verificada BOOLEAN NOT NULL DEFAULT FALSE,
   verificada_en TIMESTAMPTZ,
   verificado_por UUID REFERENCES perfiles(id) ON DELETE SET NULL
   ```

---

## 6. Cumplimiento de criterios de aceptación (Issue #16)

- [x] Reglas redactadas y numeradas (ej. una institución debe ser aprobada antes de publicar)
- [x] Revisadas por ambos integrantes
- [x] Guardadas en `/docs/sprint-0` (`docs/sprint-0/01-reglas-de-negocio.md`)
