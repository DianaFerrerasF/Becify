# Equipo, Scrum y GitHub

## Equipo (2 personas máximo)
- **Autora del proyecto (estudiante de ingeniería de software, INTEC):** Scrum Master durante todo el ciclo + Flutter/UI + diseño.
- **Compañero (estudiante de ciberseguridad):** seguridad, análisis forense, bases de datos relacionales y backend.
- **Product Owner:** propuesto como decisión compartida, registrada en el backlog.

## Scrum adaptado a 2 personas
- Sprints de 1 semana.
- Planning de 30-45 min según las horas reales disponibles.
- Daily escrito (qué hice, qué haré, qué me bloquea).
- Review mostrando el avance a alguien externo; retrospectiva de 15 min.
- Artefactos: Product Backlog (historias de usuario), Sprint Backlog, Incremento y Definition of Done.

## Hoja de ruta inicial
- Sprint 0: visión, historias de usuario, diseño en Figma, modelo de datos, modelo de amenazas.
- Sprint 1: registro e inicio de sesión.
- Sprint 2: publicación de oportunidades por instituciones.
- Sprint 3: feed con búsqueda y filtros.
- Sprint 4: guardar oportunidades y notificaciones básicas.

## Repositorio GitHub (preparar antes del Sprint 0)
- Idealmente dentro de una organización gratuita; ambos como miembros.
- Carpetas: `/docs` (con `/sprint-0`, `/seguridad`), `/app`, `/database`, `/.github`.
- `main` protegida: solo entra con Pull Request aprobado por la otra persona.
- Ramas por tarea: `feature/...`, `db/...`, `security/...`.
- Dependabot y escaneo de secretos activados.
- GitHub Projects: Backlog, Sprint, En progreso, En revisión, Hecho. Issues = historias, Milestones = sprints.
- Etiquetas: frontend, database, security, docs, bug.
- Commits claros (`feat: pantalla de login`) y una etiqueta al cerrar cada sprint.
- Cada sprint documenta planificación, review y retrospectiva en `/docs/sprint-N`.

## Definition of Done (borrador)
Código en GitHub vía Pull Request revisado, probado en dispositivo, sin claves en el repo, criterios de seguridad cumplidos y documentación actualizada.
