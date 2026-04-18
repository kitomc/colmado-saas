# FlutterFlow - Panel Web Admin ColmadoAI

> Guía para implementar el Panel Web Admin con FlutterFlow

---

## Configuración Inicial

### 1. Crear proyecto
1. Ir a [FlutterFlow](https://flutterflow.io)
2. Click "Start New Project"
3. Nombre: "ColmadoAI Admin"
4. Seleccionar **Web** (no Android)

### 2. Configurar Fonts

En **Settings** → **Theme** → **Custom Fonts**:
- **Fira Code** (headings): Importar de Google Fonts
- **Fira Sans** (body): Importar de Google Fonts

### 3. Configurar Theme

**Colors:**
| Name | Hex | Usage |
|------|-----|-------|
| Primary | #6366F1 | Botones, headers |
| Secondary | #818CF8 | Accents |
| Success/CTA | #10B981 | Estados positivos |
| Warning | #F59E0B | Estados pendientes |
| Danger | #EF4444 | Eliminar, cancel |
| Background | #F5F3FF | Fondo general |
| Surface | #FFFFFF | Cards |
| Text Primary | #1E1B4B | Textos |
| Text Secondary | #4F46E5 | Labels |

---

## Estructure de Pages

### 1. Login Page

**Widgets:**
- Logo/Icono (Store icon)
- TextField: Email
- TextField: Password (obscure text)
- Button: "Iniciar Sesión" (Primary color)
- Background: #F5F3FF

**Actions:**
- On Submit → Call Convex Auth (signInWithPassword)
- Si éxito → Navigate to Dashboard
- Si error → Show snackbar con error

---

### 2. Dashboard (Home) Page

**Layout:** Column con:
- Header: "Dashboard" + fecha actual
- Row de 4 KPI Cards (responsive: 2 en móvil, 4 en desktop)
- Sección: Últimas órdenes (tabla)
- Sección: Chats activos (lista)

**KPI Cards:**
```
┌─────────────────────────┐
│ 📊 (icon)                │
│ 24                      │
│ Órdenes del día         │
└─────────────────────────┘
```

| Card | Icon | Label |
|------|------|-------|
| Órdenes | receipt_long | Órdenes del día |
| Ingresos | attach_money | Ingresos hoy |
| Productos | inventory_2 | Productos activos |
| Chats | chat_bubble | Chats activos |

**Query:** `getMetricasDiarias(colmadoId)` - Stream

---

### 3. Catálogo (Productos) Page

**Layout:**
- AppBar: "Catálogo" + FAB "+"
- Filtros Row: Search field + Dropdown categoría
- Data Table

**Data Table Columns:**
| Column | Widget | Width |
|--------|--------|-------|
| Imagen | Image (48x48) | 60px |
| Nombre | Text | flex |
| Categoría | Badge | 100px |
| Precio | Text (RD$) | 80px |
| Estado | Switch/Icon | 60px |
| Acciones | Row of IconButtons | 100px |

**Acciones:**
- Edit → Open modal con ProductForm
- Delete → Confirm dialog → Mutation eliminarProducto

**Product Form Modal:**
- TextField: Nombre
- TextField: Precio (number)
- Dropdown: Categoría
- TextField: Imagen URL (opcional)
- Button: Guardar / Cancelar

---

### 4. Órdenes Page

**Layout:**
- AppBar: "Órdenes"
- Tab Bar: Todas | Confirmadas | Lista | Impresas | Entregadas | Canceladas
- ListView / DataTable

**Filtros por tabs:**
```
Todas → sin filtro
Confirmadas → estado = "confirmada"
Lista → estado = "lista_para_imprimir"
Impresas → estado = "impresa"
Entregadas → estado = "entregada"
Canceladas → estado = "cancelada"
```

**Order Card:**
```
┌──────────────────────────────────────┐
│ #1234 • Cliente: Juan Pérez          │
│ 3 productos • RD$450.00              │
│ 🕐 10:30 AM • ✅ Confirmada          │
│ [Ver] [Imprimir] [Cancelar]          │
└──────────────────────────────────────┘
```

**Actions:**
- Ver → Open detail modal/page
- Cambiar estado → Dropdown → Mutation actualizarEstadoOrden

---

### 5. Chats en Vivo Page

**Layout:** Row (split view)
- Left: 300px - Lista de chats activos
- Right: flex - Conversación

**Left Panel - Chat List:**
- ListView de ChatListItem
- Each item:
  - Avatar (primeras 2 letras del teléfono)
  - Teléfono
  - Último mensaje (truncate 30 chars)
  - Timestamp
  - Badge "Nuevo" si no leído

**Right Panel - Chat Detail:**
- Messages List (ScrollView)
- User messages: alineados a la derecha, color primary
- Bot messages: alineados a la izquierda, gray
- Input Row: TextField + Send Button

**Actions:**
- Send → Mutation agregarMensajeChat
- Botones superiores:
  - "Tomar Chat" → Mutation toggle bot_activo: false
  - "Liberar Chat" → Mutation toggle bot_activo: true

---

### 6. Clientes Page

**Layout:**
- AppBar: "Clientes"
- Data Table

**Columns:**
| Column | Widget |
|--------|--------|
| Teléfono | Text |
| Nombre | Text (o "Sin nombre") |
| Total Órdenes | Number |
| Última Orden | Date |
| Acciones | IconButton (ver historial) |

**Query:** `getClientes(colmadoId)`

---

### 7. Configuración Page

**Layout:** Column de secciones

**Sección 1: Datos del Colmado**
- TextField: Nombre
- TextField: Teléfono WhatsApp
- TextField: WhatsApp Token
- Button: Guardar

**Sección 2: Telegram**
- TextField: Chat ID
- Toggle: Notificaciones enabled

**Sección 3: Preferencias**
- Dropdown: Hora resumen diario
- Toggle: Notificaciones de nuevas órdenes

**Mutation:** `actualizarColmado`

---

## Navigation

### Bottom Navigation Bar (5 items)
| Icon | Label | Page |
|------|-------|------|
| home | Dashboard | Home |
| shopping_bag | Catálogo | Catalogo |
| receipt_long | Órdenes | Ordenes |
| chat_bubble | Chats | Chats |
| settings | Ajustes | Settings |

**Selected:** #6366F1
**Unselected:** #9CA3AF

---

## Queries & Mutations

### Queries necesarias
| FlutterFlow Name | Convex Query | Params |
|------------------|--------------|--------|
| getMetricas | getMetricasDiarias | colmadoId |
| getProductos | getTodosProductos | colmadoId |
| getOrdenPending | getOrdenPorEstado | colmadoId, estado |
| getChats | getChatsActivos | colmadoId |
| getClientes | getClientes | colmadoId |
| getColmado | getColmadoById | colmadoId |

### Mutations necesarias
| FlutterFlow Name | Convex Mutation | Params |
|------------------|-----------------|--------|
| crearProducto | crearProducto | colmadoId, nombre, precio, categoria |
| actualizarProducto | actualizarProducto | productoId, ... |
| eliminarProducto | eliminarProducto | productoId |
| actualizarOrden | actualizarEstadoOrden | ordenId, estado |
| actualizarColmado | actualizarColmado | colmadoId, ... |
| enviarMensajeChat | agregarMensajeChat | chatId, mensaje |

---

## Responsive Breakpoints

FlutterFlow lo maneja automáticamente, pero configurar:
- **Móvil (< 768px):** Bottom nav, 1 columna KPIs
- **Tablet (768-1024px):** 2 columnas KPIs
- **Desktop (> 1024px):** Sidebar nav, 4 columnas KPIs

---

## Testing

1. **Publish:** Click **Publish** → **Web Build**
2. **Deploy:** Conectar a Firebase Hosting o similar
3. **Test:**
   - Login → Dashboard muestra métricas
   - Productos → CRUD funciona
   - Órdenes → Estados actualizan
   - Chats → Mensajes aparecen

---

## Assets Necesarios

- Iconos: Usar Material Icons de FlutterFlow
- No necesitan imágenes externas
- Colores según theme definido