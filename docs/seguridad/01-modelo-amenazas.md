# Modelo de Amenazas y Controles de Seguridad (Sprint 0)
**Proyecto:** **Becify** — Plataforma Móvil Centralizada de Becas y Oportunidades Académicas  

| Metadato | Detalle |
| :--- | :--- |
| **Código de Documento** | `SEC-01-THREAT-MODEL` |
| **Nombre del Producto** | **Becify** |
| **Versión** | `1.0.0` (Alineada al MVP) |
| **Estado** | Aprobado — Baseline Sprint 0 |
| **Autores** | **Deurys Mercedes Batista** (Líder de Ciberseguridad, Base de Datos & Backend)<br>**Diana Estephan Ferreras Feliz** (Scrum Master & Líder de Frontend Móvil Flutter) |
| **Vinculación Ágil** | Cumplimiento del **Issue #19 (`Elaborar el modelo de amenazas`)** |

---

## 1. Propósito y Alcance Real del MVP

El presente documento identifica los **activos que se protegen**, las **amenazas potenciales** y los **controles de mitigación** diseñados específicamente para el alcance del **Producto Mínimo Viable (MVP)** de **Becify**.

### ¿Qué hace Becify en el MVP?
- Permite a estudiantes registrarse, buscar y filtrar convocatorias de becas (secundaria a doctorado).
- Permite a los estudiantes guardar becas en favoritos y marcar *"Ya apliqué"*.
- Envía recordatorios push de fecha límite (7 días y 24 horas antes del cierre).
- Permite a instituciones registrarse para publicar convocatorias, pero **requieren verificación manual previa** por parte de un administrador para poder publicar.
- La postulación no se realiza dentro de la app: Becify redirige al estudiante al `enlace_oficial` externo de la institución oferente.

### Principio de Minimización de Datos en el MVP:
En el MVP **no se procesan pagos**, **no se reciben documentos adjuntos** (ni récords de notas ni cédulas), **no hay chat interno** ni postulaciones dentro de la app. Por tanto, la seguridad se enfoca en proteger la identidad de los usuarios, la integridad de los enlaces de las convocatorias y la legitimidad de las instituciones.

---

## 2. Inventario de Activos y Datos que se Protegen

A partir del modelo relacional de 5 tablas diseñado para Becify (`perfiles`, `instituciones`, `becas`, `becas_guardadas`, `preferencias_notificacion`), se clasifican los activos que custodia el sistema:

| Activo / Dato Sensible | Ubicación en el Sistema | Nivel de Sensibilidad | ¿Por qué debe protegerse? (Impacto) |
| :--- | :--- | :---: | :--- |
| **1. Enlaces Oficiales de Becas (`enlace_oficial`)** | Tabla `becas` | **Crítico** | Si un atacante altera un enlace, puede redirigir a cientos de estudiantes a sitios de **phishing, fraude o malware**. |
| **2. Tokens de Sesión (JWT / Refresh Token)** | `flutter_secure_storage` en el móvil | **Crítico** | Si se roban del dispositivo, un atacante puede suplantar la identidad del estudiante o de la institución (*Account Takeover*). |
| **3. Estado de Verificación Institucional (`esta_verificada`, `verificado_por`)** | Tabla `instituciones` | **Alto** | Evita que una entidad no autorizada publique convocatorias falsas. El campo `verificado_por` asegura que siempre se sepa qué admin autorizó la cuenta. |
| **4. Contraseñas de Usuario** | Motor Supabase Auth (`auth.users`) | **Alto** | Resguardo de las credenciales de acceso de los usuarios mediante hashing seguro nativo de Supabase. |
| **5. Datos del Perfil del Estudiante (`correo`, `nombre_completo`)** | Tabla `perfiles` | **Medio** | Privacidad de los estudiantes registrados bajo la regla de recolectar solo lo estrictamente necesario. |
| **6. Historial de Becas Guardadas y Estado "Ya apliqué"** | Tabla `becas_guardadas` | **Medio** | Intereses académicos y postulaciones del estudiante. No debe ser visible para otros estudiantes. |
| **7. Preferencias de Notificación Push** | Tabla `preferencias_notificacion` | **Bajo** | Opciones de consentimiento del estudiante para alertas de 7 días y 24 horas. |
| **8. Catálogo Público de Becas Activas** | Tabla `becas` | **Público** | Información abierta de consulta para el feed móvil. |

---

## 3. Matriz de Amenazas y Controles Propuestos desde el Diseño

Se identifican las 6 amenazas principales que aplican directamente a la operación de Becify, junto con las medidas de mitigación que ya forman parte del diseño técnico:

### Amenaza 1: Convocatorias Falsas o Phishing Institucional
- **Escenario de Ataque:** Un usuario malintencionado se registra con rol `institucion` e intenta publicar becas falsas para engañar a los estudiantes o robarles información en sitios externos.
- **Controles desde el Diseño:**
  1. **Regla de Negocio RN-04:** Toda cuenta institucional se crea con `esta_verificada = FALSE` por defecto.
  2. **Control de Acceso (RBAC):** Las becas de una institución no verificada no se muestran en el feed móvil de los estudiantes.
  3. **Auditoría Forense:** Solo un usuario con rol `admin` puede cambiar `esta_verificada` a `TRUE`, quedando registrado de forma obligatoria quién lo aprobó (`verificado_por REFERENCES perfiles(id)`) y en qué fecha (`verificada_en`).

### Amenaza 2: Manipulación de Enlaces Oficiales Externos
- **Escenario de Ataque:** Una cuenta institucional comprometida o un atacante intenta inyectar enlaces fraudulentos (ej. `http://phishing-beca.com` o esquemas no web).
- **Controles desde el Diseño:**
  1. **Restricción CHECK en Base de Datos:** `chk_beca_enlace CHECK (enlace_oficial ~* '^https?://')` obliga a que cualquier URL comience estrictamente por HTTP o HTTPS.
  2. **Aislamiento en Móvil:** La app en Flutter utiliza el paquete `url_launcher` configurado para abrir el enlace en el navegador externo del sistema operativo, evitando incrustar vistas web inseguras (*WebViews*) dentro de la app.

### Amenaza 3: Acceso no Autorizado a Becas Guardadas de Otros Estudiantes (IDOR / BOLA)
- **Escenario de Ataque:** Un estudiante manipula el parámetro de usuario en una petición de API para espiar la lista de becas guardadas o el perfil de otro estudiante.
- **Controles desde el Diseño:**
  1. **Identificadores UUID v4:** Se utilizan UUIDs aleatorios criptográficos en lugar de enteros autoincrementales (`1, 2, 3...`), impidiendo ataques de enumeración.
  2. **Row Level Security (RLS) en PostgreSQL:** La política de lectura en `becas_guardadas` valida a nivel de motor:
     `USING (auth.uid() = perfil_id)`
     El estudiante solo puede ver y modificar sus propios registros.

### Amenaza 4: Elevación de Privilegios a Rol Administrador
- **Escenario de Ataque:** Un estudiante envía una petición modificada intentando actualizar su columna `rol` de `'estudiante'` a `'admin'` para aprobar instituciones o modificar becas ajenas.
- **Controles desde el Diseño:**
  1. **Protección de Columna vía RLS:** La política de actualización sobre `perfiles` restringe la edición únicamente a campos de presentación (`nombre_completo`), prohibiendo cambios en la columna `rol`.
  2. **Función de Seguridad `es_admin()`:** La función que valida permisos de administración se ejecuta con `SECURITY DEFINER` y comprueba directamente en base de datos si el `auth.uid()` actual posee efectivamente el rol `'admin'`.

### Amenaza 5: Almacenamiento Inseguro de Sesión en el Teléfono
- **Escenario de Ataque:** El token JWT de sesión se guarda en texto plano en el almacenamiento compartido del móvil (`SharedPreferences`), quedando expuesto en dispositivos rooteados o vulnerables.
- **Controles desde el Diseño:**
  1. **Uso de Almacenamiento Seguro:** En Flutter se utiliza exclusivamente el paquete `flutter_secure_storage`, el cual almacena los tokens cifrados utilizando **Android Keystore** en Android y **Keychain** en iOS.

### Amenaza 6: Envío Masivo o Spam de Notificaciones Push
- **Escenario de Ataque:** Fallo en la lógica de alertas que envía recordatorios repetitivos o no deseados, molestando al usuario.
- **Controles desde el Diseño:**
  1. **Consentimiento Granular:** Tabla `preferencias_notificacion` vinculada 1:1 al perfil del estudiante con banderas booleanas independientes (`notificar_7_dias`, `notificar_24_horas`).
  2. **Idempotencia:** La lógica de envío consulta estrictamente las becas guardadas cuya fecha límite coincida exactamente con los umbrales configurados y que aún no hayan sido enviadas.

---

## 4. Resumen de Controles por Capa Técnica

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. APP MÓVIL (Flutter / Dart)                                    │
│    - Almacenamiento seguro de tokens (flutter_secure_storage)     │
│    - Apertura segura de enlaces externos en navegador nativo     │
│    - Respeto a las preferencias de notificación del usuario      │
├──────────────────────────────────────────────────────────────────┤
│ 2. CANAL DE COMUNICACIÓN                                         │
│    - Tráfico 100% cifrado bajo HTTPS / TLS 1.3                   │
├──────────────────────────────────────────────────────────────────┤
│ 3. BASE DE DATOS Y BACKEND (Supabase / PostgreSQL)               │
│    - Row Level Security (RLS) por usuario (auth.uid())           │
│    - Verificación manual obligatoria de instituciones            │
│    - Auditoría forense inmutable (verificado_por, verificada_en) │
│    - Restricciones CHECK de formato (correo y enlaces web)       │
│    - Identificadores UUID v4 no enumerables                      │
├──────────────────────────────────────────────────────────────────┤
│ 4. REPOSITORIO Y CI/CD (GitHub)                                  │
│    - Cero secretos o llaves de servicio en el código (.gitignore)│
│    - Escaneo automatizado de secretos con GitHub Secret Scanning │
└──────────────────────────────────────────────────────────────────┘
```

---

## 5. Conclusión

Este modelo de amenazas demuestra que la seguridad de **Becify** no se basa en parches complejos, sino en **decisiones de diseño preventivas** aplicadas directamente sobre las 5 tablas del modelo relacional y la app móvil. Cubre exactamente los riesgos del MVP: evita becas fraudulentas, protege la privacidad del estudiante y asegura la autenticidad de los enlaces académicos.
