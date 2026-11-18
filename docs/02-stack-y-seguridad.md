# Stack técnico y seguridad (propuesto)

## Restricciones
- Preferencia por herramientas gratuitas durante el desarrollo; los costos se discuten después, si hacen falta.
- Conocimientos actuales: Flutter/Dart en Android Studio (en curso), MySQL y SQL Server Management Studio.
- Objetivo de aprendizaje: recorrer el ciclo de vida completo del software y fortalecer el portafolio.

## Stack propuesto
- **App:** Flutter y Dart (Android e iOS con un solo código).
- **Base de datos y backend:** Supabase (PostgreSQL relacional, autenticación, almacenamiento, tiempo real, reglas de acceso por fila).
- **Notificaciones push:** Firebase Cloud Messaging (gratuito).
- **Código y gestión:** GitHub (repositorio, Projects, Issues).
- **Diseño:** Figma.
- **Asistente de desarrollo en paralelo:** Antigravity.

## Por qué no PWA como primera opción
Las notificaciones push en iPhone solo funcionan si la PWA se instala en la pantalla de inicio. Con Flutter las notificaciones son nativas en ambos sistemas. Alternativa descartada por ahora: Firebase completo (Firestore es NoSQL y encaja peor con filtros y relaciones).

## Eventos de notificación (el usuario puede elegir cuáles recibir)
Mensaje nuevo sin leer, recordatorio de fecha límite (7 días y 1 día antes), cambio de estado de la solicitud, selección del estudiante.

## Seguridad (lidera el compañero de ciberseguridad)
- Modelo de amenazas en el Sprint 0.
- Contraseñas protegidas, sesiones seguras, verificación de correo.
- Aprobación manual de cuentas institucionales.
- Reglas de acceso por fila: cada usuario solo ve sus datos.
- Mínimo de datos personales; claves fuera del repositorio.
- Revisión de seguridad cada sprint y prueba de vulnerabilidades (guía OWASP/MASVS) antes del lanzamiento.
