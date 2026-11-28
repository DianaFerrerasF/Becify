# Guía de Identidad Visual y Sistema de Temas — Becify

| Metadato | Detalle |
| :--- | :--- |
| **Dirección visual** | Premium Academic Tech |
| **Versión** | `1.2` |
| **Eslogan oficial** | *Tu talento. Más oportunidades.* |
| **Lema de marca** | *Becify: porque el talento merece oportunidades.* |
| **Issue vinculado** | [#12](https://github.com/DianaFerrerasF/Becify/issues/12) (`Definir identidad visual: logo y colores`) |
| **Autora** | **Diana Estephan Ferreras Feliz** (Líder de Frontend Móvil Flutter & Diseño UI/UX) |

---

## 1. Identidad verbal y origen del nombre

Elegimos el nombre **Becify** porque representa nuestra misión: acercar las oportunidades educativas a quienes tienen el talento, la dedicación y la determinación de alcanzar sus metas.

Su nombre nace de la unión de dos conceptos:
- **«Beca»**: refleja el propósito central de nuestra plataforma.
- **«-ify»**: sufijo que transmite transformación, innovación y acción.

Buscábamos un nombre corto, moderno, fácil de recordar y con personalidad tecnológica, pero con un significado directamente ligado a lo que queremos impulsar: el desarrollo académico y profesional de las personas.

**Becify es más que encontrar una beca; es convertir el esfuerzo y el talento en oportunidades para construir un mejor futuro.**  
*Becify: porque el talento merece oportunidades.*

---

## 2. Activos oficiales de marca (`docs/identidad-visual/`)

| Archivo | Descripción | Uso principal |
| :--- | :--- | :--- |
| [Guia_Identidad_Visual_Becify.pdf](./Guia_Identidad_Visual_Becify.pdf) | Guía oficial de identidad visual, verbal y sistema de temas | Documento maestro de referencia visual y tokens |
| [Becify_App_Icon_1024.png](./Becify_App_Icon_1024.png) | **App Icon** (símbolo dentro de contenedor redondeado) | Icono de launcher iOS/Android, favicon y avatar de aplicación |
| [becify_icon_1x.png](./becify_icon_1x.png) | **Isotipo** / símbolo aislado sin wordmark (fondo transparente) | Emblemas, marcadores, avatares internos y usos sin texto |
| [Becify_wordmark.png](./Becify_wordmark.png) | **Logotipo horizontal principal** (símbolo + nombre + eslogan) | Splash/portada en Light Mode, encabezados y presentaciones claras |
| [becify_logo_dark.png](./becify_logo_dark.png) | **Logotipo horizontal negativo** (en Blanco cálido `#FFFCFA`) | Encabezados, splash y superficies en Dark Mode (`#18191D` / `#25272D`) |

### Reglas de uso de logotipos
- No confundir el **App Icon** con el **logo horizontal** ni añadir el wordmark dentro del icono cuadrado.
- No estirar, inclinar, recolorear ni aplicar sombras pesadas sobre los logotipos.
- Para fondos oscuros, utilizar siempre la variante negativa aprobada ([becify_logo_dark.png](./becify_logo_dark.png)) en lugar de aplicar filtros de inversión automática (`invert()`), preservando intactos el Dorado (`#D4A23A`) y el Carmesí (`#E63946`).

---

## 3. Paleta oficial de marca

La paleta institucional permanece constante en ambos temas; las superficies de interfaz se adaptan alrededor de ella.

| Token | HEX | Función principal |
| :--- | :---: | :--- |
| **Borgoña profundo** | `#7A0F1F` | Color primario institucional, botones principales (CTA) y chips activos |
| **Carmesí** | `#E63946` | Acentos, estados de enfoque, interacción y detalles de marca |
| **Dorado** | `#D4A23A` | Mérito, reconocimientos académicos y destellos puntuales |
| **Blanco cálido** | `#FFFCFA` | Trazos negativos del símbolo y fondos cálidos de presentación |

---

## 4. Sistema de temas y validación de contraste (WCAG 2.1)

### 4.1 Light Mode (Diseño base aprobado)

| Token | HEX | Contraste sobre fondo | Uso en interfaz |
| :--- | :---: | :---: | :--- |
| `Background` | `#FFFFFF` | — | Fondo general de pantalla |
| `Surface / Card` | `#F9FAFB` | — | Tarjetas de becas y contenedores |
| `Primary text` | `#0B0B0F` | **`19.64:1` (AAA)** | Títulos y texto principal de lectura |
| `Secondary text` | `#4B5563` | **`7.23:1` (AAA)** | Metadatos, fechas y texto secundario |
| `Border` | `#E5E7EB` | — | Divisores y bordes sutiles de tarjetas |
| `Primary action` | `#7A0F1F` | **`10.96:1` (AAA con texto `#FFFFFF`)** | Botones CTA y filtros activos |
| `Accent` | `#E63946` | **`4.17:1` (AA Large / UI)** | Acentos, bordes activos e iconos destacados |

> **Regla de contraste en Light Mode:** El Dorado (`#D4A23A`) sobre blanco tiene una relación de `2.33:1`; en Light Mode debe usarse exclusivamente para **iconos, estrellas, bordes o insignias**, nunca para texto pequeño sobre fondo blanco.

### 4.2 Dark Mode — Carbón neutro

Construido sin negro puro (`#000000`) ni grises azulados, diferenciando la profundidad mediante 3 niveles tonales (`Background → Surface/Card → Elevated surface`) sin sombras pesadas:

| Token | HEX | Contraste sobre superficie | Uso en interfaz |
| :--- | :---: | :---: | :--- |
| `Background` | `#18191D` | — | Fondo general de la aplicación |
| `Surface / Card` | `#25272D` | — | Tarjetas y contenedores principales |
| `Elevated surface` | `#30333A` | — | Controles internos, inputs y elementos elevados |
| `Border` | `#3B3E46` | — | Bordes y separadores sutiles |
| `Primary text` | `#F5F5F5` | **`13.69:1` (AAA sobre `#25272D`)** | Títulos y texto principal |
| `Secondary text` | `#C4C6CC` | **`7.41:1` a `8.74:1` (AAA)** | Descripciones y metadatos |
| `Primary action` | `#7A0F1F` | **`10.96:1` (AAA con texto `#FFFFFF`)** | Relleno de botones CTA y filtros activos |
| `Accent` | `#E63946` | **`3.58:1` (AA Large / UI)** | Acentos, iconos y bordes de selección |
| `Merit` | `#D4A23A` | **`6.42:1` (AA sobre `#25272D`)** | Reconocimientos e indicadores de mérito |

> **Regla de contraste en Dark Mode:** El Borgoña profundo (`#7A0F1F`) sobre `#25272D` tiene una relación de `1.36:1`; en Dark Mode `#7A0F1F` debe utilizarse únicamente como **superficie de relleno para botones/chips con texto blanco (`#FFFFFF`)**, nunca como color de fuente suelta sobre fondo oscuro. Para enlaces o textos destacados sobre superficies oscuras se utiliza Blanco cálido (`#FFFCFA`), Carmesí (`#E63946`) o Dorado (`#D4A23A`).

### 4.3 Colores semánticos

Los estados deben combinar siempre **color + icono + etiqueta de texto** (no depender únicamente del color):

| Estado | HEX | Uso en Becify |
| :--- | :---: | :--- |
| **Institución verificada** | `#16A34A` | Insignia de confianza institucional (aprobada por admin) |
| **Recordatorio · 7 días** | `#F59E0B` | Aviso preventivo de fecha límite próxima |
| **Alerta · 24 horas** | `#DC2626` | Vencimiento urgente de convocatoria o error de validación |
| **Ya apliqué** | `#EC4899` | Indicador de seguimiento personal en becas guardadas |
| **Aplicación confirmada** | `#16A34A` | Confirmación de estado (aplicaciones internas en Fase 2) |

---

## 5. Tipografía, componentes y estructura en Flutter

- **Marca y encabezados:** `Manrope` (`Bold 700` / `SemiBold 600`).
- **Lectura y contenido:** `Inter` (`Regular 400` / `Medium 500`).
- **Organización recomendada en el proyecto Flutter (`app/`):**

```text
lib/core/theme/
  app_colors.dart
  app_theme.dart
  app_typography.dart
  app_semantics.dart

assets/branding/
  becify_app_icon.png
  becify_icon_1x.png
  becify_logo_horizontal.png
  becify_logo_dark.png
```
