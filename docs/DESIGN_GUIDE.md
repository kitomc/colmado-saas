# DESIGN_GUIDE.md — COLMARIA SaaS
> Guía de diseño oficial para el Panel Web Admin y la App Android COLMARIA PRINT.
> Este archivo debe ser leído por OpenCode al implementar cualquier pantalla de UI.
> **Nunca uses colores, fuentes o tamaños que no estén definidos aquí.**

---

## 🎯 Principios de diseño

1. **Limpio y enfocado en datos** — El admin no necesita chatear, solo ver resultados.
2. **Verde = crecimiento, ventas, éxito** — El color verde es el único acento de marca.
3. **La IA trabaja por WhatsApp, el admin solo supervisa** — La UI es de consulta, no de operación.
4. **Confiable, simple y técnico** — Tono profesional, sin adornos innecesarios.
5. **El diseño es funcional primero** — Cada elemento tiene un propósito claro.

---

## 🌐 WEB ADMIN PANEL — COLMARIA Dashboard

### Paleta de colores

```
┌────────────────────────────────────────────────┐
│  Token            Hex        Uso                             │
├────────────────────────────────────────────────┤
│  Verde oscuro     #14532D    Sidebar, header, fondo logo     │
│  Verde principal  #22C55E    Botón primario, badges, charts  │
│  Verde claro      #DCFCE7    Chips activo, highlights        │
│  Blanco/Fondo     #F8FAF5    Background general              │
│  Gris neutro      #64748B    Texto secundario, iconos        │
│  Blanco puro      #FFFFFF    Cards, superficies              │
│  Borde sutil      #E2E8F0    Bordes de cards y tablas        │
└────────────────────────────────────────────────┘
```

### Tipografía

- **Fuente única:** `Inter` (Google Fonts)
- Nunca usar otra fuente en el panel web.

| Nivel | Tamaño / Peso | Uso |
|-------|--------------|-----|
| Título 1 | 28px / 700 | Título de página principal |
| Título 2 | 20px / 600 | Subtemas, secciones |
| Título 3 | 16px / 600 | Encabezados de card, tabla |
| Texto | 14px / 400 | Cuerpo general |
| Texto pequeño | 12px / 400 | Badges, labels, metadata |

### Botones

| Tipo | Estilo | Uso |
|------|--------|-----|
| Primario | Fondo `#22C55E`, texto blanco, border-radius 8px | Acción principal por pantalla |
| Secundario | Borde `#22C55E`, texto `#22C55E`, fondo transparente | Acciones secundarias |
| Terciario | Sin borde, texto `#64748B` | Acciones de bajo peso |

### Layout del Dashboard

```
┌───────────────┐ ┌────────────────────────────────────────────┐
│  SIDEBAR       │ │  HEADER (Topbar)                            │
│  #14532D       │ ├────────────────────────────────────────────┤
│               │ │  KPI Cards (4 columnas)                     │
│  Logo          │ ├────────────────────────────────────────────┤
│  Resumen       │ │  Gráfica barras (izq)  |  Donut canal (der) │
│  Ventas        │ ├────────────────────────────────────────────┤
│  Pedidos       │ │  Top productos (izq)  |  Métricas LLM (der) │
│  Productos     │ ├────────────────────────────────────────────┤
│  IA (LLM)      │ │  Inventario bajo (alertas)                  │
│  Clientes      │ ├────────────────────────────────────────────┤
│  Reportes      │ │  Pedidos recientes (tabla)                  │
│  Configuración │ │                                            │
│               │ │                                            │
│  ● IA Activa   │ │                                            │
│  [Ver WA]      │ │                                            │
└───────────────┘ └────────────────────────────────────────────┘
```

### Componentes del Dashboard

#### KPI Cards (4 unidades en fila)
Cada card muestra:
- Label pequeño (texto 12px, gris)
- Valor grande (28px, negro, bold)
- Variación vs período anterior en verde (`+X.X%`)
- Sparkline mini en verde al pie

**KPIs requeridos:**
1. Ventas totales (`$125,680.00`)
2. Pedidos realizados (`1,248`)
3. Ticket promedio (`$100.72`)
4. Productos vendidos (`2,342`)

#### Gráfica Ventas por Día
- Tipo: barras verticales
- Color: `#22C55E`
- Selector: Diario / Semanal / Mensual
- Eje Y: valores en miles (`$5k`, `$10k`, `$15k`, `$20k`)
- Eje X: fechas del mes

#### Gráfica Ventas por Canal
- Tipo: donut
- Segmento único inicial: WhatsApp (IA) 100%
- Color: `#22C55E`
- Centro: porcentaje grande + monto

#### Tabla: Lo que más vende la IA
- Columnas: Producto | Ventas ($) | Unidades
- Imagen miniatura del producto (32x32px)
- Link “Ver todos los productos” en verde

#### Métricas IA (LLM)
- Layout: lista con label izquierda + valor derecha
- Métricas: Conversaciones atendidas, Pedidos tomados, Tasa de conversión, Tiempo promedio de respuesta, Ventas atribuidas a la IA
- Link “Ver detalles de la IA” en verde

#### Inventario Bajo (alertas)
- Cards horizontales con imagen del producto
- Stock en rojo (`Stock: 2`)
- Link “Ver inventario completo” en verde

#### Tabla Pedidos Recientes
- Columnas: # Pedido | Cliente | Total | Estado | Fecha | Canal
- Estado: badge verde “Entregado”
- Canal: ícono de WhatsApp
- Link “Ver todos los pedidos” en verde

### Sidebar
- Fondo: `#14532D`
- Logo COLMARIA en blanco/verde claro
- Ítem activo: fondo `#22C55E` con texto blanco
- Ítem inactivo: texto blanco con opacidad 70%
- Iconos: estilo outline, 20px
- Footer del sidebar: indicador ● IA Activa + botón “Ver en WhatsApp”

### Iconografía Web
- Estilo: outline / line icons
- Tamaño: 20px en sidebar, 18px en contenido
- Biblioteca recomendada: Lucide Icons o Heroicons
- Iconos por sección:
  - Resumen → 🏠 home
  - Ventas → 📊 bar-chart
  - Pedidos → 📦 package
  - Productos/Inventario → 🛒 shopping-bag
  - IA (LLM) → 🤖 bot / cpu
  - Clientes → 👥 users
  - Reportes → 📈 trending-up
  - Configuración → ⚙️ settings

---

## 📱 ANDROID APP — COLMARIA PRINT

### Propósito
> Esta app **no vende**. Solo conecta la impresora térmica Bluetooth a la cuenta COLMARIA
> para recibir e imprimir automáticamente los pedidos que toma la IA por WhatsApp.

### Paleta de colores

```
┌────────────────────────────────────────────────┐
│  Token               Hex        Uso                     │
├────────────────────────────────────────────────┤
│  Verde principal     #16A34A    Botones, activos, CTA   │
│  Verde oscuro        #0F5132    Splash screen, header   │
│  Gris neutro         #687280    Texto secundario        │
│  Fondo claro         #F8FAFC    Background pantallas    │
│  Rojo error          #EF4444    Error, sin conexión     │
│  Amarillo advertencia #F59E0B   Stock bajo, advertencia │
│  Blanco              #FFFFFF    Cards, superficies      │
└────────────────────────────────────────────────┘
```

### Tipografía Android

- **Fuente única:** `Inter` (igual que la web)
- Títulos: Semibold
- Subtítulos: Medium
- Texto: Regular (`#687280`)

### Componentes Android

| Componente | Especificación |
|---|---|
| Botón primario | Fondo `#16A34A`, texto blanco, border-radius 12px, height 48px |
| Botón secundario | Borde `#16A34A`, texto `#16A34A`, fondo transparente |
| Switch activado | Color `#16A34A` |
| Chip “Conectado” | Fondo verde claro, texto verde oscuro |
| Chip “En cola” | Fondo amarillo claro, texto amarillo oscuro |
| Chip “Error” | Fondo rojo claro, texto rojo |
| Bottom Navigation | 3 tabs: Estado • Pedidos • Ajustes |

### Iconografía Android
- Estilo: outline / Material Icons
- Tamaño: 24px en navegación, 20px en contenido
- Iconos clave: wifi, bluetooth, printer, refresh, bell, list, settings, check-circle, x-circle

### Las 12 Pantallas — Especificación

#### 1. Splash
- Fondo: `#0F5132` (verde oscuro)
- Logo COLMARIA PRINT centrado en blanco
- Tagline: “Conectando tu impresora con COLMARIA”
- Indicador de carga circular en verde claro

#### 2. Login
- Fondo: `#F8FAFC`
- Card centrada con: email + contraseña + botón “Iniciar sesión”
- Link: “¿Olvidaste tu contraseña?”
- Footer: “¿No tienes cuenta? Contacta a tu admin”
- Badge inferior: “Esta app es parte de COLMARIA (SaaS)”

#### 3. Seleccionar Negocio
- Lista de colmados vinculados a la cuenta
- Cada fila: nombre del colmado + chip de estado (Activo / Inactivo)
- Footer: “¿No ves tu negocio? Contacta al administrador”

#### 4. Estado del Dispositivo
- Header: nombre del colmado seleccionado
- Card impresora: nombre del modelo + método conexión + estado
- Sección “Estado del servicio”:
  - Conectado a COLMARIA (check)
  - Sincronizado (check)
  - Última actividad: timestamp
- Banner verde: “Todo listo — Los pedidos de la IA se imprimirán automáticamente”
- Bottom Nav: Estado • Pedidos • Ajustes

#### 5. Pedidos en Cola
- Tab activo: “En cola” con badge contador
- Lista de pedidos con: # pedido, cliente, monto, estado chip, hora
- Estados: Imprimiendo... (verde), En cola (amarillo)
- Footer: “Impresos hoy: X pedidos” + link historial

#### 6. Historial
- Tab “Historial” activo con badge
- Agrupado por fecha (hoy, ayer...)
- Cada pedido: # + cliente + monto + estado (Impreso / $ignoó)

#### 7. Conectar Impresora
- Opciones de conexión:
  - **Bluetooth** — Conecta por Bluetooth
  - **Wi-Fi** — Conecta por red Wi-Fi
- Nota: “¿No encuentras tu impresora? Asegúrate de que esté encendida y en modo de emparejamiento.”

#### 8. Seleccionar Impresora Bluetooth
- Header: “Dispositivos Bluetooth”
- Indicador de búsqueda animado
- Lista de dispositivos encontrados (nombre + MAC address)
- Link: “¿Tu impresora no aparece? Ver ayuda”

#### 9. Probando Impresora
- Pantalla de progreso con pasos:
  - Conectando... ✓
  - Enviando datos... ✓
  - Imprimiendo... ✓
- Ilustración de impresora con página saliendo
- Resultado: banner verde “Impresora lista — La página de prueba se imprimió correctamente”

#### 10. Ajustes
- Sección “General”:
  - Nombre del dispositivo (editable)
  - Volumen de notificaciones
  - Imprimir automáticamente (toggle `#16A34A`)
  - Sonido de impresión (toggle)
- Sección “Información”:
  - Versión de la app
  - ID de dispositivo
- Botón: “Cerrar sesión” (texto rojo)

#### 11. Sin Conexión
- Fondo header: `#EF4444` (rojo)
- Título: “Sin conexión” en blanco
- Mensaje: “No podemos conectar con COLMARIA”
- Estado: “Intentando reconectar...” + timestamp último intento
- Botón: “Reintentar ahora”

#### 12. Error de Impresora
- Card de error con ícono rojo
- Título: “Error de impresora”
- Subtexto: “No se puede imprimir el pedido #XXXX”
- Lista de posibles causas:
  - Impresora apagada
  - Sin papel
  - Fuera de alcance
  - Error de conexión
- Botones: “Reintentar” (primario) + “Ver ayuda” (secundario)

---

## 🔗 Flujo de arquitectura del sistema

```
Cliente          LLM           COLMARIA        COLMARIA PRINT
(WhatsApp)  →  COLMARIA  →   (SaaS)     →   (Android)
                                                    ↓
                                              Bluetooth
                                                    ↓
                                           Impresora Térmica
```

---

## ⚠️ Reglas de diseño que NUNCA se deben violar

- ❌ No usar gradientes en botones — colores sólidos siempre
- ❌ No usar bordes de colores en cards — solo sombra o fondo diferente
- ❌ No usar más de 2 colores de acento en una misma pantalla
- ❌ No usar fuentes distintas a `Inter`
- ❌ No usar íconos rellenos (filled) — solo outline
- ❌ No usar `border-radius` mayor a 16px en cards web
- ✅ El verde `#22C55E` (web) / `#16A34A` (Android) es el único color de CTA
- ✅ Texto rojo solo para estados de error crítico
- ✅ Texto amarillo solo para advertencias de stock o conexión
- ✅ Todos los números monetarios con formato: `$X,XXX.XX`
- ✅ Todos los timestamps con formato: `DD/MM/YYYY HH:MM AM/PM`
