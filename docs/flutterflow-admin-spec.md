# Panel Admin FlutterFlow - Especificaciones de Diseño

## Design System: ColmadoAI Admin

### Patrón
- **Nombre:** Data-Dense + Drill-Down
- **Estilo:** Data-Dense Dashboard
- **Keywords:** Multiple charts/widgets, data tables, KPI cards, minimal padding, grid layout, space-efficient

---

## Paleta de Colores

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#6366F1` | Indigo - botones principales, headers |
| Secondary | `#818CF8` | Indigo claro - acentos, badges |
| CTA/Success | `#10B981` | Emerald - acciones positivas, estados "confirmada" |
| Warning | `#F59E0B` | Amber - alertas, estados "pendiente" |
| Danger | `#EF4444` | Red - eliminar, estados "cancelada" |
| Background | `#F5F3FF` | Indigo muy claro - fondo general |
| Surface | `#FFFFFF` | White - cards, tablas |
| Text Primary | `#1E1B4B` | Indigo oscuro - textos principales |
| Text Secondary | `#4F46E5` | Indigo medio - labels, hints |

---

## Tipografía

- **Headings:** Fira Code (Google Fonts)
- **Body:** Fira Sans (Google Fonts)

### Configuración FlutterFlow:
```
Font Family: Fira Code (headings), Fira Sans (body)
Sizes:
- H1: 28px, weight 700
- H2: 22px, weight 600
- H3: 18px, weight 600
- Body: 14px, weight 400
- Small: 12px, weight 400
```

---

## Estructura de Pantallas

### 1. Login Page
- Logo + nombre del colmado
- Email field
- Password field
- "Iniciar Sesión" button (Primary `#6366F1`)
- Fondo: Background `#F5F3FF`

### 2. Dashboard (Home)
**Layout:** Grid 2x2 de KPI cards + gráfico + tabla de órdenes recientes

**KPI Cards (4):**
1. **Órdenes del día** - número grande, icono de receipt
2. **Ingresos hoy** - formato moneda RD$
3. **Productos activos** - contador
4. **Chats activos** - indicador

**Gráfico:** Orders timeline (últimos 7 días)

**Tabla:** Últimas 5 órdenes con:
- ID, Cliente, Total, Estado (badge colored)

### 3. Catálogo (Productos)
**Layout:** Data Table con filtros

**Columnas:**
- Imagen (thumbnail 48x48)
- Nombre
- Categoría (badge)
- Precio (formato RD$)
- Estado (Disponible/No disponible toggle)
- Acciones (Edit, Delete)

**Filtros:**
- Buscar por nombre
- Filter por categoría
- Filter por disponibilidad

**Acciones:**
- FAB "+" para agregar producto
- Edit abre modal con campos

### 4. Órdenes
**Layout:** Kanban o Data Table con filtros de estado

**Estados (columns o filters):**
- Confirmada (`#6366F1`)
- Lista para imprimir (`#F59E0B`)
- Impresa (`#818CF8`)
- Entregada (`#10B981`)
- Cancelada (`#EF4444`)

**Row actions:**
- Ver detalle
- Cambiar estado
- Imprimir ticket
- Cancelar

### 5. Chats en Vivo
**Layout:** Split view

**Left Panel:** Lista de chats activos
- Avatar (iniciales)
- Teléfono cliente
- Último mensaje (truncated)
- Timestamp
- Badge "Nuevo" si hay mensajes sin leer

**Right Panel:** Conversación
- Historial de mensajes
- Input field para responder
- Botones quick: "Confirmar orden", "Ver catálogo"

### 6. Clientes
**Layout:** Data Table

**Columnas:**
- Teléfono
- Nombre
- Total órdenes
- Última orden (fecha)
- Acciones (Ver historial, Editar)

### 7. Configuración
**Sections:**
- **Datos del colmado:** nombre, teléfono WhatsApp, token
- **Telegram:** Chat ID, comandos
- **Preferencias:** notifications, horarios

---

## Componentes Reutilizables

### KPICard
```
Background: White
Border radius: 12px
Shadow: 0 4px 6px rgba(0,0,0,0.1)
Padding: 16px
Icon: 24x24, color según tipo
Value: Fira Code 28px bold
Label: Fira Sans 12px, color secondary
```

### DataTable
```
Header: bg `#F5F3FF`, text `#1E1B4B`, weight 600
Row hover: bg `#F5F3FF`
Row alternate: bg white / `#FAFAFA`
Border: 1px `#E5E7EB`
```

### StatusBadge
```
Padding: 4px 8px
Border radius: 6px
Font: 12px, weight 500
Colors según estado:
- Confirmada: bg `#EEF2FF`, text `#6366F1`
- Lista: bg `#FEF3C7`, text `#D97706`
- Impresa: bg `#E0E7FF`, text `#4F46E5`
- Entregada: bg `#D1FAE5`, text `#059669`
- Cancelada: bg `#FEE2E2`, text `#DC2626`
```

### PrimaryButton
```
Background: `#6366F1`
Text: White, 14px, weight 500
Border radius: 8px
Padding: 12px 24px
Hover: brightness 110%
Active: scale 0.98
```

### FloatingActionButton
```
Background: `#10B981`
Icon: Plus, white
Position: bottom-right, 24px margin
Size: 56x56
Shadow: prominent
```

---

## Navigation

**Bottom Navigation Bar (5 items):**
1. Dashboard (Home icon)
2. Catálogo (ShoppingBag icon)
3. Órdenes (Receipt icon)
4. Chats (ChatBubble icon)
5. Configuración (Cog icon)

**Activo:** Primary color `#6366F1`
**Inactivo:** Gray 400 `#9CA3AF`

---

## Responsive Breakpoints

FlutterFlow maneja esto automáticamente, pero:
- **Móvil:** 1 columna, bottom nav
- **Tablet:** 2 columnas para KPIs
- **Desktop:** Sidebar navigation + 4 columnas KPIs

---

## Integración con Convex

### Queries necesarias:
- `getMetricasDiarias(colmadoId)` → KPIs
- `getOrdenesRecientes(colmadoId, limit)` → Dashboard tabla
- `getProductos(colmadoId)` → Catálogo
- `getOrdenesPorEstado(colmadoId, estado)` → Órdenes filter
- `getChatsActivos(colmadoId)` → Chats list
- `getClientes(colmadoId)` → Clientes table

### Mutations necesarias:
- `crearProducto(data)`
- `actualizarProducto(productoId, data)`
- `eliminarProducto(productoId)`
- `actualizarEstadoOrden(ordenId, estado)`
- `enviarMensajeChat(chatId, mensaje)`
- `actualizarColmado(data)`

---

## Action: Imprimir Ticket

Para la comunicación con impresora térmica (Android):
- Custom Action en FlutterFlow
- Bridge a código nativo Android
- Envía a través de método channel

---

## Implementación en FlutterFlow

1. **Crear proyecto** → "ColmadoAI Admin"
2. **Configurar fonts** → Importar Fira Code y Fira Sans
3. **Crear tema** → Colores según paleta
4. **Crear componentes** → KPICard, DataTable, StatusBadge, etc.
5. **Crear páginas** → Login, Dashboard, Catálogo, Órdenes, Chats, Clientes, Settings
6. **Conectar Convex** → SDK setup
7. **Crear queries/mutations** → Mapear a Convex backend
8. **Testear** → Preview mode

---

## Assets Necesarios

- Logo colmado (placeholder: icono de tienda)
- Icons: Lucide or Heroicons (importar como SVG)
- Placeholder images para productos