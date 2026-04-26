# COLMARIA PRINT — Design Document (Android)

> Versión 1.0.0 · App Android Flutter · Última actualización: Abril 2026

---

## Visión General

**COLMARIA PRINT** es la app Android del ecosistema COLMARIA SaaS. Su única función es conectar la cuenta del dueño del colmado con su impresora térmica Bluetooth o Wi-Fi para recibir e imprimir automáticamente los pedidos que capta la IA por WhatsApp.

> La app no vende, no gestiona inventario ni crea órdenes. Solo imprime.

### Arquitectura del sistema

```
Cliente (WhatsApp) → LLM COLMARIA → COLMARIA SaaS (Convex) → COLMARIA PRINT (Android) → Impresora Térmica
```

---

## Principios de Diseño

| Pilar | Descripción |
|-------|-------------|
| **Estilo** | Moderno, limpio, enfocado en conectividad y estado |
| **Tono** | Confiable, simple y técnico |
| **Usuarios** | Dueños y empleados de colmados dominicanos |
| **Objetivo** | La impresora esté siempre conectada e imprimiendo |
| **Filosofía** | Una sola acción primaria por pantalla. Feedback visual inmediato. Sin ambigüedad de estado. |

---

## Tokens de Diseño

### Paleta de Colores

| Token | Hex | Uso |
|-------|-----|-----|
| `color-primary` | `#16AA3A` | Botón primario, chips activos, iconos de estado OK, logo |
| `color-primary-dark` | `#0F5132` | Header, Splash background, estados hover |
| `color-neutral` | `#687280` | Texto secundario, subtítulos, iconos inactivos |
| `color-bg` | `#F8FAFC` | Fondo principal de todas las pantallas |
| `color-surface` | `#FFFFFF` | Cards, modales, listas |
| `color-error` | `#EF4444` | Pantalla "Sin conexión", chip Error, estado crítico |
| `color-warning` | `#F5960B` | Chip "En cola", advertencias no críticas |
| `color-text` | `#1A1A2E` | Texto primario |
| `color-text-muted` | `#687280` | Texto secundario, metadatos |
| `color-divider` | `#E5E7EB` | Separadores entre items de lista |

### Tipografía

| Rol | Familia | Peso | Tamaño aprox. |
|-----|---------|------|----------------|
| Títulos | Inter | SemiBold (600) | 20–24sp |
| Subtítulos | Inter | Medium (500) | 14–16sp |
| Texto general | Inter | Regular (400) | 14sp |
| Labels tiny | Inter | Regular (400) | 12sp · uppercase tracked |

> **Una sola familia tipográfica: Inter.** La jerarquía se logra con peso y tamaño, no con familias distintas.

### Espaciado (Sistema 4px)

```
4dp  — gap mínimo entre elementos inline
8dp  — padding interno de chips y badges
12dp — gap entre items de lista
16dp — padding horizontal de pantallas
20dp — gap entre secciones de card
24dp — padding vertical de secciones principales
```

### Bordes y Radios

| Elemento | Radio |
|----------|-------|
| Botón primario | `12dp` (pill suave) |
| Card | `12dp` |
| Chip / Badge | `full` (pill) |
| Input | `8dp` |
| Bottom nav | `0dp` (flat) |

### Sombras

```
Card normal:  elevation 1 · shadow color rgba(0,0,0,0.06)
Card activa:  elevation 3 · shadow color rgba(0,0,0,0.10)
```

---

## Componentes del Sistema

### Botones

```
Botón Primario
  Background: #16AA3A
  Text: #FFFFFF · Inter SemiBold 15sp
  Height: 52dp
  Radius: 12dp
  States: normal / pressed (10% dark) / disabled (40% opacity)

Botón Secundario
  Background: #FFFFFF
  Border: 1.5dp · #16AA3A
  Text: #16AA3A · Inter Medium 15sp
  Height: 52dp
  Radius: 12dp
```

### Chips de Estado

```
Conectado   → background #DCFCE7 · text #16AA3A · ● verde
En cola     → background #FEF3C7 · text #D97706 · ● amarillo
Imprimiendo → background #DBEAFE · text #2563EB · ● azul (animado)
Error       → background #FEE2E2 · text #EF4444 · ● rojo
Inactivo    → background #F1F5F9 · text #687280 · ● gris
```

### Switch

```
Activado:    thumb #FFFFFF · track #16AA3A
Desactivado: thumb #FFFFFF · track #CBD5E1
Tamaño: 51×31dp (estándar Material)
```

### Cards

```
Background: #FFFFFF
Border-radius: 12dp
Padding: 16dp
Shadow: elevation 1
Border: ninguno (elevación es suficiente)
```

### Bottom Navigation Bar

```
3 tabs: Estado · Pedidos · Ajustes
Icon size: 24dp
Label: Inter Regular 11sp
Active color: #16AA3A
Inactive color: #687280
Background: #FFFFFF
Elevation: 8
```

### Lista de Pedidos (item)

```
Height: 72dp
Layout: [Order ID + cliente] | [hora] + [monto] + [chip estado]
Divider: 1dp · #E5E7EB · indent 16dp
Tap: ripple #16AA3A · 8% opacity
```

---

## Flujos de Pantallas (12 screens)

### 1. Splash

- Fondo: `#0F5132` (verde oscuro)
- Logo COLMARIA PRINT centrado (blanco)
- Tagline: *"Conectando tu impresora con COLMARIA"*
- Loading indicator circular verde debajo
- Duración: 2s → navega a Login si no hay sesión activa, o a Estado si hay sesión guardada

### 2. Login

- Fondo: `#F8FAFC`
- Header: logo pequeño + "Inicia sesión"
- Campos: Email + Contraseña (inputs con borde suave, label flotante)
- CTA: Botón primario "Iniciar sesión" full-width
- Links: "¿Olvidaste tu contraseña?" + "Contacta a tu admin"
- Footer: "Esta app es parte de COLMARIA (SaaS)"
- **Sin registro**: las cuentas las crea el admin desde el Web Admin

### 3. Seleccionar Negocio

- Lista de colmados asociados al usuario autenticado
- Item: nombre del colmado + chip de estado (Activo / Inactivo)
- Si solo hay uno → skip automático directo a pantalla Estado
- Texto auxiliar: "¿No ves tu negocio? Contacta al administrador"

### 4. Estado (pantalla principal)

- Header verde oscuro con nombre del colmado + chip "Dispositivo conectado"
- **Card Impresora**: nombre del modelo + dirección Bluetooth + chip estado conexión
- **Sección "Estado del servicio"**: 3 items con chevron:
  - Conectado a COLMARIA
  - Sincronizado
  - Última actividad (timestamp)
- **Banner "Todo listo"** (verde): *"Los pedidos de la IA se imprimirán automáticamente"*
- Estado de error: banner rojo "Sin conexión" reemplaza al verde

### 5. Pedidos en Cola (tab Pedidos)

- Dos sub-tabs: **En cola** · **Historial**
- Lista items con: ID orden, "Cliente de WhatsApp", monto, hora, chip estado
- Footer fijo: contador "Impresos hoy: N pedidos" + link "Ver historial →"
- Swipe-to-dismiss en items "En cola" (marcar como impreso manualmente)
- Empty state: icono impresora + "No hay pedidos en cola"

### 6. Historial (sub-tab)

- Misma lista pero con estado "Impreso" (chip verde tenue)
- Agrupado por fecha: "Hoy, 31 May 2024"
- Monto visible en cada item
- Infinite scroll (paginación)

### 7. Conectar Impresora

- Dos opciones grandes: **Bluetooth** · **Wi-Fi** (cards seleccionables)
- Botón "Continuar" → navega a Seleccionar impresora
- Texto auxiliar: "¿No encuentras tu impresora? Asegúrate de que esté encendida y en modo de emparejamiento."

### 8. Seleccionar Impresora

- Header: "Dispositivos Bluetooth" + spinner de búsqueda
- Lista de dispositivos disponibles: nombre + dirección MAC
- Tap → selecciona y navega a Probando impresora
- Link: "¿Tu impresora no aparece? Ver ayuda"

### 9. Probando Impresora

- Pasos animados con checkmarks:
  1. Conectando... ✓
  2. Enviando datos... ✓
  3. Imprimiendo... ✓
- Preview visual de la impresora física
- Banner de éxito: "¡Impresora lista! La página de prueba se imprimió correctamente."

### 10. Ajustes

- Sección General:
  - Nombre del dispositivo (editable)
  - Volumen de notificaciones (slider)
  - Switch: "Imprimir automáticamente al recibir pedidos de la IA"
  - Switch: "Sonido de impresión"
- Sección Información:
  - Versión de la app
  - ID del dispositivo
- Botón "Cerrar sesión" (texto rojo, sin background)

### 11. Sin Conexión (estado de error crítico)

- Fondo `#EF4444` (rojo) en header expandido
- Título: "Sin conexión" · subtítulo: "No podemos conectar con COLMARIA"
- Estado: "Intentando reconectar... · Último intento: [timestamp]"
- Botón: "Reintentar ahora"
- Nota: "Verifica tu conexión a internet y que tu negocio esté activo en COLMARIA"

### 12. Error Impresora

- Card de error con icono de impresora + badge rojo
- Mensaje: "No se puede imprimir el pedido #XXXX"
- Lista "Posibles causas":
  - Impresora apagada
  - Sin papel
  - Fuera de alcance
  - Error de conexión
- Botones: "Reintentar" (primario) + "Ver ayuda" (secundario)

---

## Navegación

```
SplashScreen
    └── LoginScreen
            └── SeleccionarNegocioScreen
                    └── MainScreen (Bottom Nav)
                            ├── EstadoTab
                            │     ├── ConectarImpresora
                            │     │     └── SeleccionarImpresora
                            │     │           └── ProbarImpresora
                            │     ├── SinConexionOverlay (estado crítico)
                            │     └── ErrorImpresoraModal
                            ├── PedidosTab
                            │     ├── EnColaSubTab
                            │     └── HistorialSubTab
                            └── AjustesTab
```

**Reglas de navegación:**
- `MainScreen` es el único destino persistente. Nunca se destruye.
- `SinConexionOverlay` se muestra sobre `EstadoTab` sin reemplazarlo.
- `LoginScreen` solo es accesible si no hay sesión. Si hay sesión guardada, Splash navega directo a `MainScreen`.
- Back button físico en `LoginScreen` → cierra la app (no hay pantalla anterior).

---

## Iconografía

Set de iconos: **Material Icons** (outlined) + íconos personalizados para impresora.

| Contexto | Ícono |
|----------|-------|
| Tab Estado | `wifi_tethering` |
| Tab Pedidos | `receipt_long` |
| Tab Ajustes | `settings` |
| Bluetooth | `bluetooth` |
| Wi-Fi | `wifi` |
| Impresora | `print` (custom SVG) |
| Notificación | `notifications` |
| Reconectar | `refresh` |
| Historial | `history` |
| Orden OK | `check_circle` |
| Error | `error_outline` |

---

## Comportamiento del Estado de Conexión

El estado de conexión con COLMARIA SaaS es el elemento más crítico de la UI.

```
CONECTADO    → Header normal verde oscuro · Banner "Todo listo" · Bottom nav visible
RECONECTANDO → Header normal + spinner inline · Banner amarillo "Reconectando..."
SIN CONEXIÓN → Header rojo expandido · Banner rojo · Botón "Reintentar" prominente
```

La app hace polling cada **30 segundos** al backend de Convex. Si falla 3 veces consecutivas → estado `SIN CONEXIÓN`.

---

## Notificaciones Push

| Evento | Tipo | Contenido |
|--------|------|-----------|
| Nuevo pedido recibido | Push + sonido | "Pedido #1250 recibido — RD$250.00" |
| Pedido impreso OK | Local silenciosa | "Pedido #1250 impreso correctamente" |
| Error de impresión | Push + vibración | "Error al imprimir pedido #1250 — Toca para ver" |
| Sin conexión >5min | Push | "COLMARIA sin conexión — Verifica tu internet" |

---

## Accesibilidad

- Touch targets mínimos: **48×48dp** en todos los elementos interactivos
- Contraste texto/fondo: cumple **WCAG AA** (4.5:1 mínimo en texto normal)
- `contentDescription` en todos los iconos sin label visible
- Soporte de tamaño de fuente del sistema (usar `sp` siempre)
- Estados de error descritos por `semanticsLabel` para lectores de pantalla

---

## Stack Técnico Recomendado

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.x |
| Estado | Riverpod 2.x |
| Backend real-time | Convex Flutter SDK |
| Bluetooth printing | `bluetooth_print` package |
| Wi-Fi printing | `esc_pos_utils` + TCP socket |
| Autenticación | Convex Auth (email/password) |
| Notificaciones | Firebase Cloud Messaging |
| Storage local | `shared_preferences` (token de sesión) |

---

## Estructura de Carpetas Flutter

```
lib/
├── main.dart
├── app/
│   ├── router.dart          # GoRouter — todas las rutas
│   └── theme.dart           # ColmariaTheme (tokens de diseño)
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── auth_provider.dart
│   ├── negocio/
│   │   └── seleccionar_negocio_screen.dart
│   ├── estado/
│   │   ├── estado_screen.dart
│   │   └── conexion_provider.dart
│   ├── pedidos/
│   │   ├── pedidos_screen.dart
│   │   ├── en_cola_tab.dart
│   │   └── historial_tab.dart
│   ├── impresora/
│   │   ├── conectar_impresora_screen.dart
│   │   ├── seleccionar_impresora_screen.dart
│   │   ├── probar_impresora_screen.dart
│   │   └── impresora_provider.dart
│   └── ajustes/
│       └── ajustes_screen.dart
├── shared/
│   ├── widgets/
│   │   ├── chip_estado.dart
│   │   ├── orden_item.dart
│   │   ├── boton_primario.dart
│   │   └── banner_estado.dart
│   └── models/
│       ├── orden.dart
│       ├── colmado.dart
│       └── impresora.dart
└── convex/
    └── convex_client.dart   # Singleton del cliente Convex
```

---

*COLMARIA PRINT · Design Document v1.0.0 · Conecta tu impresora. Imprime cada pedido. Sin complicaciones.*
