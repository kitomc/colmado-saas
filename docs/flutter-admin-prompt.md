# Prompt: Implementar Web Admin COLMARIA en Flutter

> Copia y pega este prompt completo al LLM (Cursor, Claude, ChatGPT, FlutterFlow AI).
> Adjunta también: `docs/design-admin.md` y `convex/schema.ts`

---

```
Eres un experto en FlutterFlow y Flutter Web. Voy a darte el contexto completo
de un proyecto SaaS llamado COLMARIA para que implementes el Web Admin.

## CONTEXTO DEL PROYECTO

COLMARIA es un SaaS para colmados dominicanos. El Web Admin permite al dueño:
- Registrar y gestionar productos
- Ver pedidos generados por un bot de WhatsApp con IA
- Conectar su número de WhatsApp Business (Embedded Signup de Meta)
- Ver métricas de ventas
- Gestionar clientes

## BACKEND: CONVEX

El backend es 100% Convex (https://convex.dev). Ya existe y está funcional.

Convex Cloud URL:   https://different-hare-762.convex.cloud
Convex HTTP URL:    https://different-hare-762.convex.site

Tablas principales:
- colmados: { nombre, telefono_whatsapp, whatsapp_token, whatsapp_phone_id,
              waba_id, meta_conectado, meta_connected_at }
- productos: { colmado_id, nombre, categoria, precio, disponible, descripcion }
- ordenes:   { colmado_id, cliente_id, productos[], total, estado,
              direccion, metodo_pago, created_at }
- clientes:  { colmado_id, telefono, nombre, total_ordenes, ultima_orden }
- chats:     { colmado_id, cliente_telefono, historial[], bot_activo,
              ultima_actividad }

Estados de orden: "lista_para_imprimir" | "imprimiendo" | "impreso" | "cancelado"

Autenticación: Convex Auth con email/password.

## ENDPOINTS HTTP (Convex HTTP Actions)

Base URL: https://different-hare-762.convex.site

POST /whatsapp          → Webhook de WhatsApp (solo Meta llama esto)
GET  /whatsapp          → Verificación de webhook de Meta
POST /embedded-signup   → Conectar WhatsApp Business de un colmado
                           Body: { code: string, colmadoId: string }
                           Response: { success: boolean, phoneNumber?: string }
POST /meta-deauth       → Desconexion automática por Meta (solo Meta)

## DISEÑO (Design Tokens)

Colores:
  Primary:       #16AA3A
  Primary Dark:  #0F5132  (sidebar, headers)
  Background:    #F8FAFC
  Surface:       #FFFFFF
  Error:         #EF4444
  Warning:       #F5960B
  Info:          #3B82F6
  Text:          #1A1A2E
  Text Muted:    #687280
  Divider:       #E5E7EB

Tipografía: Inter (una sola familia)
  Títulos:    SemiBold 24px
  Subtítulos: Medium 16px
  Body:       Regular 14px
  Labels:     Medium 12px uppercase

Chips de estado de orden:
  lista_para_imprimir → bg #FEF3C7  text #D97706  (amarillo)
  imprimiendo         → bg #DBEAFE  text #2563EB  (azul)
  impreso             → bg #DCFCE7  text #16AA3A  (verde)
  cancelado           → bg #F1F5F9  text #687280  (gris)
  error               → bg #FEE2E2  text #EF4444  (rojo)

## LAYOUT

Sidebar fijo 240px · fondo #0F5132.
Topbar 64px · blanco · borde inferior 1px #E5E7EB.
Contenido: scroll vertical · máximo 1400px centrado · padding 32px.

Navegación del sidebar:
  1. Dashboard    (icono: dashboard)
  2. Productos    (icono: inventory_2)
  3. Pedidos      (icono: receipt_long) + badge con count "En cola"
  4. WhatsApp     (icono: forum — verde si conectado, rojo si no)
  5. Clientes     (icono: people)
  6. Métricas     (icono: bar_chart)
  7. Configuración (icono: settings)

## PÁGINAS A IMPLEMENTAR (en orden de prioridad)

### PRIORIDAD 1 — Layout principal
Sidebar + Topbar wrapper que envuelve todas las demás páginas.
Topbar muestra: nombre página actual | indicador WhatsApp (● verde/rojo) | avatar usuario.

### PRIORIDAD 1 — Dashboard
- 4 KPI Cards en fila:
  * Pedidos hoy (icono receipt)
  * Ventas hoy en RD$ (icono payments)
  * Clientes activos hoy (icono people)
  * Mensajes del bot hoy (icono smart_toy)
- Gráfico de ventas últimos 7 días (line chart — fl_chart package)
- Lista de últimos 5 pedidos con chip de estado
- Card "Estado del sistema":
  * ✅/❌ WhatsApp conectado
  * ✅/❌ Bot activo
  * Número de órdenes pendientes de imprimir

### PRIORIDAD 1 — Productos
- Barra superior: search input + filtro categoría + botón "+Nuevo producto"
- Tabla con columnas: Nombre | Categoría | Precio | Disponible (Toggle) | Acciones
- Toggle "Disponible" llama a mutation Convex inmediatamente (optimistic update)
- Acciones: botón Editar (abre modal) · botón Eliminar (confirm dialog)
- Modal Crear/Editar campos:
  * Nombre (TextField)
  * Descripción (TextArea)
  * Categoría (DropdownMenu): Bebidas, Comida, Snacks, Lácteos,
    Limpieza, Cigarrillos, Otros
  * Precio (TextField numérico, prefijo RD$)
  * Disponible (Switch)
- Validación: nombre requerido, precio > 0

### PRIORIDAD 1 — Pedidos
- Sub-tabs: En cola | Imprimiendo | Impresos | Todos
- Tabla: #ID | Cliente (teléfono) | Productos (resumen N items) | Total RD$ | Estado | Hora
- Clic en fila → modal de detalle:
  * Header: #1250 · chip estado
  * Lista de productos: nombre · cantidad · precio unitario · subtotal
  * Total en bold
  * Dirección de entrega
  * Método de pago
  * Botón "Reimprimir" (llama mutation Convex: cambiar estado a lista_para_imprimir)
  * Botón "Cancelar orden" (solo si estado = lista_para_imprimir, rojo)

### PRIORIDAD 2 — WhatsApp

CUANDO meta_conectado == false:
  Mostrar card centrada:
  - Icono WhatsApp grande
  - Título: "Conecta tu WhatsApp Business"
  - Subtitulo explicativo
  - Botón primario: "Conectar con WhatsApp Business"
    Al hacer clic ejecutar el Embedded Signup de Meta:

    1. Cargar el Facebook JS SDK en el HTML:
       <script async defer src="https://connect.facebook.net/en_US/sdk.js"></script>

    2. Inicializar:
       FB.init({ appId: '[META_APP_ID]', version: 'v20.0' });

    3. Al clic del botón llamar:
       FB.login(function(response) {
         if (response.authResponse?.code) {
           // Llamar al endpoint de Convex
           fetch('https://different-hare-762.convex.site/embedded-signup', {
             method: 'POST',
             headers: { 'Content-Type': 'application/json' },
             body: JSON.stringify({
               code: response.authResponse.code,
               colmadoId: currentColmadoId
             })
           })
           .then(r => r.json())
           .then(data => {
             if (data.success) {
               // Mostrar toast de éxito y recargar estado
             } else {
               // Mostrar toast de error
             }
           });
         }
       }, {
         config_id: '[META_CONFIG_ID]',
         response_type: 'code',
         override_default_response_type: true
       });

    Implementa esto como un HtmlElementView (webview_flutter_web o
    js interop desde Flutter Web).

CUANDO meta_conectado == true:
  Card verde con:
  - Número WhatsApp conectado
  - Nombre de la cuenta WABA
  - Fecha de conexión
  - Switch "Bot activo / pausado" (llama mutation: actualizar bot_activo en chats)
  - Stats: Mensajes hoy | Órdenes generadas hoy | Última actividad
  - Link rojo "Desconectar" (confirm dialog → mutation desconectarWhatsApp)

### PRIORIDAD 2 — Métricas
- Selector rango: Últimos 7 / 30 / 90 días
- KPIs: Ventas totales RD$ | Total órdenes | Ticket promedio | Clientes únicos
- Gráfico ventas por día (line chart)
- Top 5 productos más vendidos (bar chart horizontal)
- Distribución métodos de pago (donut chart)

### PRIORIDAD 3 — Clientes
- Tabla: Teléfono | Nombre | Total órdenes | Total gastado RD$ | Última orden
- Clic → modal historial de órdenes del cliente

### PRIORIDAD 3 — Configuración
- Tabs: Perfil del negocio | Usuarios | Impresoras vinculadas | Suscripción

## QUERIES Y MUTATIONS DE CONVEX

Usar el Convex Flutter SDK con useQuery / useMutation.
Colmado ID viene del usuario autenticado: ConvexAuthState.colmadoId

Queries disponibles:
  api.productos.getByColmado     args: { colmadoId }
  api.ordenes.getByColmado       args: { colmadoId, estado? }
  api.clientes.getByColmado      args: { colmadoId }
  api.colmados.get               args: { colmadoId }
  api.embeddedSignup.getEstadoConexion  args: { colmadoId }

Mutations disponibles:
  api.productos.create           args: { colmadoId, nombre, categoria, precio, disponible, descripcion? }
  api.productos.update           args: { productoId, ...campos }
  api.productos.remove           args: { productoId }
  api.ordenes.updateEstado       args: { ordenId, estado }
  api.embeddedSignup.desconectarWhatsApp  args: { colmadoId }

## CONVENCIONES DE CÓDIGO

- Riverpod para manejo de estado
- Convex Flutter SDK para datos en tiempo real
- GoRouter para navegación
- Responsive: sidebar colapsa a 60px (solo iconos) en pantallas < 1024px
- Skeleton loading en tablas mientras cargan (3 filas animadas)
- Toast de éxito/error después de cada mutación (posición: bottom-right)
- Todos los precios: NumberFormat("RD\$ #,##0.00")
- Timestamps: formato relativo ("hace 3 min", "hace 2h")
- Paginación en tablas: 20 items por página

## LO QUE NO DEBES HACER

- No crear backend propio, TODO va por Convex
- No usar Firebase
- No inventar queries/mutations que no estén en la lista
- No hardcodear el colmadoId, viene del usuario autenticado
- No usar colores fuera de los design tokens
- No crear pantallas de registro (las cuentas las crea el Super Admin)

## ENTREGABLE ESPERADO

Implementa en este orden:
1. ColmariaTheme (theme.dart con todos los design tokens)
2. Layout principal: AppShell con Sidebar + Topbar
3. DashboardPage
4. ProductosPage + ProductoModal
5. PedidosPage + OrdenModal
6. WhatsAppPage con Embedded Signup
7. MetricasPage
8. ClientesPage
9. ConfiguracionPage

Por cada entregable dame:
  a) El widget completo
  b) El provider Riverpod si aplica
  c) La ruta registrada en GoRouter

Empieza por ColmariaTheme y AppShell.
```
