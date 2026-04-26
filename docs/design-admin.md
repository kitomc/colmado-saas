# COLMARIA — Design Document: Web Admin

> Versión 1.0.0 · Web Admin (React / FlutterFlow Web) · Última actualización: Abril 2026

---

## Visión General

El **Web Admin de COLMARIA** es el panel de control central del SaaS. Desde aquí el dueño del colmado gestiona su catálogo, configura su cuenta de WhatsApp Business (Embedded Signup), monitorea pedidos y consulta métricas de su negocio.

> El Web Admin no toma pedidos. Los pedidos los toma la IA por WhatsApp. El Web Admin los monitorea y gestiona.

### Usuarios del Web Admin

| Rol | Acceso |
|-----|--------|
| **Super Admin** (tú, el SaaS owner) | Todos los colmados, facturación, configuración global |
| **Admin Colmado** (dueño del negocio) | Solo su colmado: productos, WhatsApp, pedidos, métricas |
| **Empleado** (cajero / encargado) | Solo ver pedidos activos y marcarlos como entregados |

---

## Principios de Diseño

| Pilar | Descripción |
|-------|-------------|
| **Estilo** | Dashboard profesional, datos densos pero legibles |
| **Tono** | Confiable, directo, orientado a la acción |
| **Dispositivos** | Desktop-first (1280px+), responsive hasta tablet (768px) |
| **Filosofía** | El estado de WhatsApp y los pedidos son siempre visibles. Cero clics para ver lo más importante. |

---

## Tokens de Diseño

> Misma paleta base que la app Android. Consistencia total del sistema.

### Paleta de Colores

| Token | Hex | Uso |
|-------|-----|-----|
| `--color-primary` | `#16AA3A` | Botones CTA, links activos, badges positivos, sidebar activo |
| `--color-primary-dark` | `#0F5132` | Sidebar background, header, hover states |
| `--color-primary-light` | `#DCFCE7` | Fondos de chips "activo", row highlights |
| `--color-neutral-50` | `#F8FAFC` | Fondo de página |
| `--color-neutral-100` | `#F1F5F9` | Fondo de inputs, filas alternas de tabla |
| `--color-neutral-200` | `#E5E7EB` | Bordes, dividers |
| `--color-neutral-500` | `#687280` | Texto secundario, labels, iconos inactivos |
| `--color-neutral-900` | `#1A1A2E` | Texto principal |
| `--color-surface` | `#FFFFFF` | Cards, modales, tablas |
| `--color-error` | `#EF4444` | Alertas críticas, chips error, bordes de input inválido |
| `--color-warning` | `#F5960B` | Chips "en cola", alertas no críticas |
| `--color-info` | `#3B82F6` | Chips "imprimiendo", notificaciones informativas |
| `--color-success` | `#16AA3A` | Confirmaciones, chips "impreso", toasts de éxito |

### Tipografía

| Rol | Familia | Peso | Tamaño |
|-----|---------|------|--------|
| H1 Página | Inter | SemiBold 600 | 24px |
| H2 Sección | Inter | SemiBold 600 | 18px |
| H3 Card | Inter | Medium 500 | 16px |
| Tabla header | Inter | Medium 500 | 13px · uppercase · tracking 0.05em |
| Tabla body | Inter | Regular 400 | 14px |
| Labels / badges | Inter | Medium 500 | 12px |
| Texto general | Inter | Regular 400 | 14px |
| Monospace (IDs) | JetBrains Mono | Regular | 13px |

### Espaciado

```
4px  — gap entre icon e inline text
8px  — padding interno de badges y chips
12px — gap entre campos de formulario
16px — padding de cards y celdas de tabla
24px — gap entre cards de la misma fila
32px — padding de secciones de página
```

### Grid

```
Layout principal: sidebar 240px fijo + contenido fluid
Contenido máximo: 1400px centered
Gutters: 24px
Columnas: 12 (CSS Grid)
```

### Radios y Elevaciones

| Elemento | Radio | Sombra |
|----------|-------|--------|
| Card | `12px` | `0 1px 3px rgba(0,0,0,0.08)` |
| Modal | `16px` | `0 20px 60px rgba(0,0,0,0.15)` |
| Botón | `8px` | ninguna |
| Input | `8px` | ninguna |
| Dropdown | `8px` | `0 8px 24px rgba(0,0,0,0.12)` |
| Tabla | `12px` | `0 1px 3px rgba(0,0,0,0.06)` |
| Badge / Chip | `full (9999px)` | ninguna |
| Toast | `10px` | `0 4px 16px rgba(0,0,0,0.12)` |

---

## Layout Principal

```
┌─────────────────────────────────────────────────────────────────┐
│  SIDEBAR (240px)          │  TOPBAR (height: 64px)                  │
│  ┌────────────────┐    │  [Nombre página]  [🔔 N] [Avatar] │
│  │ COLMARIA Logo  │    │                                         │
│  └────────────────┘    ├───────────────────────────────────────────────────│
│  ──────────────────  │  CONTENT AREA (scroll vertical)         │
│  📊 Dashboard           │  │
│  📦 Productos           │  [Página actual renderizada aquí]       │
│  📋 Pedidos             │  │
│  💬 WhatsApp            │  │
│  👥 Clientes            │  │
│  📈 Métricas            │  │
│  ──────────────────  │  │
│  ⚙️ Configuración      │  │
│  🔒 WhatsApp Setup     │  │
└────────────────────────└────────────────────────────────────────┘
```

### Sidebar

```
Background: #0F5132
Ancho: 240px (desktop) · 0px oculto + overlay (mobile/tablet)
Logo: COLMARIA · blanco · top 24px
Nav items: icon 20px + label 14sp · color blanco 70% · hover: blanco 100% + bg rgba(255,255,255,0.1)
Activo: bg rgba(255,255,255,0.15) · text blanco 100% · borde izquierdo 3px #16AA3A
Divisor: rgba(255,255,255,0.12)
Bottom: nombre del colmado + avatar del usuario
```

### Topbar

```
Background: #FFFFFF
Height: 64px
Border-bottom: 1px #E5E7EB
Contenido: breadcrumb izquierda · [campana notif + avatar] derecha
```

---

## Componentes del Sistema

### Botones

```
Primario
  bg #16AA3A · text #FFF · padding 10px 20px · radius 8px · font Medium 14px
  Hover: bg #128F30 · Disabled: opacity 40%

Secundario
  bg #FFF · border 1.5px #E5E7EB · text #1A1A2E · padding 10px 20px · radius 8px
  Hover: bg #F8FAFC

Peligro
  bg #EF4444 · text #FFF · mismos métricos que primario
  Hover: bg #DC2626

Link
  bg transparent · text #16AA3A · sin borde · underline en hover
```

### Inputs y Forms

```
Input base
  height: 40px · radius 8px · border 1px #E5E7EB
  Focus: border 2px #16AA3A · shadow 0 0 0 3px rgba(22,170,58,0.15)
  Error: border 2px #EF4444 · mensaje error debajo en rojo 12px
  Placeholder: #687280

Label
  Inter Medium 13px · #1A1A2E · margin-bottom 6px

Textarea
  Misma base · min-height 80px · resize vertical

Select / Dropdown
  Misma base + icono chevron derecha

Search input
  Icono lupa izquierda · placeholder "Buscar..." · ancho fluid
```

### Chips / Badges

```
Activo     → bg #DCFCE7 · text #16AA3A · ● 8px verde
Inactivo   → bg #F1F5F9 · text #687280 · ● 8px gris
En cola    → bg #FEF3C7 · text #D97706 · ● 8px amarillo
Imprimiendo→ bg #DBEAFE · text #2563EB · ● 8px azul
Impreso    → bg #DCFCE7 · text #16AA3A (tenue)
Error      → bg #FEE2E2 · text #EF4444 · ● 8px rojo
Cancelado  → bg #F1F5F9 · text #687280 · tachado
```

### Tabla

```
Header: bg #F8FAFC · border-bottom 2px #E5E7EB · text uppercase 12px Medium #687280
Row: bg #FFF · border-bottom 1px #F1F5F9 · height 56px
Row hover: bg #F8FAFC
Row seleccionada: bg #DCFCE7
Paginación: [Anterior] [1][2][3] [Siguiente] · bottom de la card
Empty state: icono centrado + texto descriptivo + CTA si aplica
```

### Cards de Métricas (KPI Cards)

```
Tamaño: ancho fluid (grid 4 columnas) · alto 120px
Contenido: [icono 32px arriba-izquierda] [valor grande 32px bold] [label 13px muted] [delta %]
Delta positivo: texto + flecha verde
Delta negativo: texto + flecha roja
Border-left: 4px del color del tema del KPI
```

### Modal

```
Overlay: rgba(0,0,0,0.5) backdrop-blur 4px
Contenedor: bg #FFF · radius 16px · max-width 560px · padding 32px
Header: título H2 + botón X cierre
Footer: botones alineados a la derecha [Cancelar] [Confirmar]
Animación: fade + scale 0.95→1 · 200ms ease
```

### Toast / Notificaciones

```
Posición: bottom-right · gap 8px entre toasts
Ancho: 360px
Duración: 4s auto-dismiss (errores: manual dismiss)
Tipos:
  Éxito:  icono ✓ · borde izquierdo #16AA3A
  Error:   icono ! · borde izquierdo #EF4444
  Info:    icono i · borde izquierdo #3B82F6
  Warning: icono ! · borde izquierdo #F5960B
```

---

## Páginas del Web Admin

### 1. Login / Onboarding

**Pantalla split:**
- Izquierda (40%): fondo `#0F5132` · logo COLMARIA grande · tagline · lista de features
- Derecha (60%): bg `#F8FAFC` · card centrada con form

**Form:**
- Campo Email + Contraseña
- Botón primario full-width "Iniciar sesión"
- Link "¿Olvidaste tu contraseña?"
- Footer: "COLMARIA © 2026"

---

### 2. Dashboard

**Header de página:** nombre del colmado + fecha actual + chip estado WhatsApp

**Fila 1 — KPI Cards (4 columnas):**

| Card | Ícono | Métrica | Color borde |
|------|-------|---------|-------------|
| Pedidos hoy | `receipt_long` | N órdenes | `#16AA3A` |
| Ventas hoy | `payments` | RD$ XXXXX | `#3B82F6` |
| Clientes activos | `people` | N únicos hoy | `#8B5CF6` |
| Bot activo | `smart_toy` | Ültima actividad | `#F5960B` |

**Fila 2:**
- Izquierda (65%): **Gráfico de ventas** — line chart últimos 7 días (RD$ por día)
- Derecha (35%): **Pedidos recientes** — lista de las últimas 5 órdenes con chip estado

**Fila 3:**
- Izquierda (50%): **Top productos** — bar chart horizontal top 5
- Derecha (50%): **Estado del sistema** — lista de checks:
  - ✅ WhatsApp conectado
  - ✅ Bot activo
  - ✅ Impresora conectada
  - ⚠️ Órdenes pendientes de imprimir: N

---

### 3. Productos

**Header:** "Productos" + botón "+Nuevo producto" (primario)

**Toolbar:**
- Search input full-width
- Filtro por categoría (select)
- Toggle "Solo disponibles"

**Tabla de productos:**

| Columna | Contenido |
|---------|----------|
| Imagen | thumbnail 40×40 · radius 8px |
| Nombre | texto bold |
| Categoría | chip tenue |
| Precio | `RD$ X,XXX.00` |
| Stock | número o "Sin límite" |
| Disponible | toggle switch inline |
| Acciones | `Editar` link · `Eliminar` rojo |

**Modal Crear/Editar Producto:**
- Campos: Nombre, Descripción (textarea), Categoría (select), Precio, Stock (opcional), Disponible (switch), Imagen (upload)
- Validaciones inline
- Botón "Guardar producto"

**Categorías por defecto del catálogo:**
```
Bebidas · Comida · Snacks · Lácteos · Limpieza · Cigarrillos · Otros
```

---

### 4. Pedidos

**Header:** "Pedidos" + filtro de fecha (date range picker)

**Sub-tabs:** `En cola (N)` · `Imprimiendo` · `Impresos` · `Todos`

**Tabla de pedidos:**

| Columna | Contenido |
|---------|----------|
| # | ID orden `#1250` |
| Cliente | teléfono WhatsApp |
| Productos | resumen "Pan x2, Leche x1..." |
| Total | `RD$ XXX.00` |
| Dirección | texto truncado con tooltip |
| Pago | Método de pago |
| Estado | chip de estado |
| Hora | timestamp relativo |
| Acciones | `Ver detalle` · `Reimprimir` |

**Modal Ver Detalle de Orden:**
- Header: `#1250 · Cliente de WhatsApp` + chip estado
- Lista de productos con cant, precio unitario y subtotal
- Total en bold
- Información: dirección, método de pago, hora
- Botón "Reimprimir orden"
- Botón "Cancelar orden" (rojo, solo si estado = en cola)

---

### 5. WhatsApp (Conectar / Estado)

> Página central del Embedded Signup. Estado siempre visible.

**Cuando NO está conectado:**

```
┌─────────────────────────────────────────────┐
│   📱 Conecta tu WhatsApp Business               │
│                                               │
│   Para que la IA pueda atender a tus          │
│   clientes, necesitas conectar tu número      │
│   de WhatsApp Business.                       │
│                                               │
│   [  🟢 Conectar con WhatsApp Business  ]       │
│        (botón oficial de Meta, verde)         │
│                                               │
│   ℹ️ El proceso toma menos de 2 minutos.       │
└─────────────────────────────────────────────┘
```

**Cuando SÍ está conectado:**

```
Card verde ──────────────────────────────
✅ WhatsApp Business conectado
📱 Número: +1 (809) XXX-XXXX
🏪 Cuenta: Colmado Los Amigos
Conectado el: 26 de abril de 2026
[Desconectar] (link rojo pequeño)

Estado del bot ──────────────────────────
✅ Bot activo ─ respondiendo mensajes
🗨️ Mensajes hoy: 47
📋 Órdenes generadas hoy: 12
⏰ Última actividad: hace 3 min

Configuración del bot ───────────────────
[Switch] Bot activo / pausado
[Editar prompt del bot] → textarea editable
[Horario de atención] → (próximamente)
```

**Flujo del botón Embedded Signup:**
1. Admin hace clic en "Conectar con WhatsApp Business"
2. Popup oficial de Meta se abre (Facebook Login)
3. Admin selecciona/crea su WABA y número de teléfono
4. Meta retorna el `code` al popup
5. El popup llama a `POST /embedded-signup` con `{ code, colmadoId }`
6. Convex intercambia el code por token, guarda en BD
7. La página se actualiza en tiempo real mostrando "Conectado"

---

### 6. Clientes

**Header:** "Clientes" + contador total

**Tabla:**

| Columna | Contenido |
|---------|----------|
| Teléfono | número WhatsApp |
| Nombre | nombre detectado por el bot |
| Total órdenes | número |
| Total gastado | `RD$ X,XXX.00` |
| Última orden | timestamp relativo |
| Acciones | `Ver historial` |

**Modal Historial de Cliente:**
- Header: teléfono + nombre
- KPIs: total órdenes, total gastado, primera orden
- Lista de todas sus órdenes con link a detalle

---

### 7. Métricas

**Header:** "Métricas" + selector de rango de fechas

**Fila 1 — KPIs del período:**
- Ventas totales (RD$)
- Total órdenes
- Ticket promedio
- Clientes únicos

**Fila 2:**
- Gráfico ventas por día (line chart, 30 días)
- Gráfico órdenes por hora del día (bar chart, pico de demanda)

**Fila 3:**
- Top 10 productos más vendidos (tabla + bar mini)
- Distribución por método de pago (donut chart)

**Fila 4:**
- Mensajes de WhatsApp procesados vs órdenes generadas (conversión)
- Tasa de error del bot (mensajes sin orden generada)

---

### 8. Configuración

**Secciones con scroll lateral (tabs):**

#### 8a. Perfil del Colmado
- Nombre del negocio (editable)
- Dirección
- Teléfono de contacto
- Logo (upload)
- Botón "Guardar cambios"

#### 8b. Usuarios y Acceso
- Tabla de usuarios con roles (Admin / Empleado)
- Invitar nuevo usuario (email + rol)
- Revocar acceso

#### 8c. Impresora
- Lista de apps COLMARIA PRINT vinculadas
- Estado de cada app (conectada / desconectada)
- Última actividad
- Botón "Desvincular" app

#### 8d. Suscripción
- Plan actual (Free / Starter / Pro)
- Fecha de renovación
- Uso del mes: N mensajes / límite
- Botón "Cambiar plan"

---

## Flujo de Primera Vez (Onboarding)

Cuando un nuevo colmado inicia sesión por primera vez, se muestra un **wizard de 4 pasos** antes de ver el dashboard:

```
Paso 1: Perfil del negocio
  → Nombre, dirección, logo

Paso 2: Agregar primeros productos
  → Formulario rápido: nombre + precio (bulk add)

Paso 3: Conectar WhatsApp Business
  → Botón Embedded Signup de Meta

Paso 4: Descargar COLMARIA PRINT
  → QR code + link directo a Play Store
  → Botón "Ir al dashboard"
```

Barra de progreso visible en todos los pasos. Se puede saltar al paso siguiente pero queda marcado como pendiente.

---

## Navegación y Rutas

```
/login                       → Login
/dashboard                   → Dashboard principal
/productos                   → Lista de productos
/productos/nuevo             → Crear producto
/productos/:id/editar        → Editar producto
/pedidos                     → Lista de pedidos
/pedidos/:id                 → Detalle de orden
/whatsapp                    → Conectar / Estado WhatsApp
/clientes                    → Lista de clientes
/clientes/:id                → Historial de cliente
/metricas                    → Reportes y gráficos
/configuracion               → Ajustes del colmado
/configuracion/usuarios      → Gestión de usuarios
/configuracion/impresoras    → Apps vinculadas
/configuracion/suscripcion   → Plan y facturación
/onboarding                  → Wizard primera vez
```

---

## Estados Globales de la UI

### Indicador de conexión WhatsApp (siempre visible)

En el topbar, junto a las notificaciones, hay un indicador permanente:

```
● verde  = WhatsApp conectado y bot activo
● amarillo = WhatsApp conectado pero bot pausado
● rojo    = WhatsApp desconectado (clic → ir a página WhatsApp)
```

### Loading States

```
Tabla cargando   → skeleton rows (3 filas) · color #F1F5F9 · animación pulse
Card KPI         → skeleton rect proporcional
Gráfico          → spinner centrado en el área del chart
Modal            → overlay interno con spinner · no bloquea el modal completo
Botones          → spinner inline reemplaza el label · disabled durante la acción
```

### Empty States

```
Sin productos    → icono caja · "Aún no tienes productos" · botón "+Agregar producto"
Sin pedidos      → icono recibo · "No hay pedidos todavía" · texto informativo
Sin clientes     → icono personas · "Tus clientes aparecerán aquí"
Sin conexión WA → icono WhatsApp gris · CTA "Conectar ahora"
```

---

## Responsive (Tablet 768px–1024px)

- Sidebar colapsa a 60px (solo iconos) · hover muestra tooltip con label
- Grid KPI: 2 columnas en lugar de 4
- Tablas: columnas secundarias ocultas · botón "Ver más" para expandir fila
- Gráficos: altura reducida a 200px

---

## Accesibilidad

- Todos los botones tienen `aria-label` descriptivo
- Tablas con `<caption>` y headers `scope="col"`
- Modales manejan focus trap y `aria-modal="true"`
- Colores de estado nunca son el único indicador (siempre acompañados de texto o icono)
- Contraste mínimo WCAG AA en todo el texto sobre fondos coloreados
- Navegación completa por teclado (Tab / Shift+Tab / Enter / Escape)

---

## Stack Técnico Recomendado

| Capa | Tecnología |
|------|-----------|
| Framework | React 18 + TypeScript |
| Routing | React Router v6 |
| Estado UI | Zustand |
| Backend real-time | Convex React SDK (`useQuery`, `useMutation`) |
| Componentes base | shadcn/ui (Radix UI + Tailwind) |
| Gráficos | Recharts |
| Tablas | TanStack Table v8 |
| Forms | React Hook Form + Zod |
| Autenticación | Convex Auth |
| Deploy | Cloudflare Pages |

---

## Estructura de Carpetas

```
src/
├── main.tsx
├── app/
│   ├── App.tsx              # Router principal
│   └── Layout.tsx           # Sidebar + Topbar wrapper
├── pages/
│   ├── LoginPage.tsx
│   ├── OnboardingPage.tsx
│   ├── DashboardPage.tsx
│   ├── ProductosPage.tsx
│   ├── PedidosPage.tsx
│   ├── WhatsAppPage.tsx     # Embedded Signup + estado del bot
│   ├── ClientesPage.tsx
│   ├── MetricasPage.tsx
│   └── ConfiguracionPage.tsx
├── components/
│   ├── layout/
│   │   ├── Sidebar.tsx
│   │   └── Topbar.tsx
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Badge.tsx
│   │   ├── Card.tsx
│   │   ├── DataTable.tsx
│   │   ├── Modal.tsx
│   │   ├── Toast.tsx
│   │   ├── KpiCard.tsx
│   │   └── EmptyState.tsx
│   ├── whatsapp/
│   │   ├── EmbeddedSignupButton.tsx   # Botón oficial Meta
│   │   ├── WhatsAppStatusCard.tsx
│   │   └── BotConfigCard.tsx
│   ├── productos/
│   │   ├── ProductoModal.tsx
│   │   └── ProductoRow.tsx
│   ├── pedidos/
│   │   ├── OrdenModal.tsx
│   │   └── OrdenRow.tsx
│   └── charts/
│       ├── VentasDiariasChart.tsx
│       ├── HorarioDemandaChart.tsx
│       └── TopProductosChart.tsx
├── hooks/
│   ├── useColmado.ts
│   ├── usePedidos.ts
│   └── useMetricas.ts
└── lib/
    ├── convex.ts            # Cliente Convex singleton
    ├── utils.ts             # formatCurrency, formatDate...
    └── constants.ts         # Categorias, estados de orden, etc.
```

---

*COLMARIA Web Admin · Design Document v1.0.0 · Gestiona tu colmado. La IA vende por ti.*
