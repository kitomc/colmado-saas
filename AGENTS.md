# AGENTS.md — ColmadoAI SaaS
> Este archivo es leído por OpenCode en CADA sesión. Nunca lo ignores.
> Sigue las instrucciones en el orden exacto en que aparecen.

---

## 🧠 CADENA DE PENSAMIENTO OBLIGATORIA (Chain of Thought)

Antes de escribir CUALQUIER línea de código, debes ejecutar internamente este proceso:

```
PASO 1 — COMPRENSIÓN
  └─ ¿Entiendo completamente lo que se me pide?
  └─ ¿Cuáles son los inputs y outputs esperados de esta tarea?
  └─ ¿Qué dominio DDD está involucrado (Colmado, Orden, Producto, Chat, Cliente)?

PASO 2 — CONTEXTO
  └─ ¿Qué archivos ya existen que son relevantes para esta tarea?
  └─ ¿Esta tarea depende de algún otro módulo ya implementado?
  └─ ¿Hay algún contrato de interfaz que debo respetar?

PASO 3 — DISEÑO
  └─ ¿Cuál es la entidad de dominio (DDD) que modela esto?
  └─ ¿Qué principio SOLID aplica aquí?
      - S: ¿Esta función/clase tiene una sola responsabilidad?
      - O: ¿Estoy extendiendo sin modificar lo que ya funciona?
      - L: ¿Si hay herencia, el hijo puede reemplazar al padre?
      - I: ¿Las interfaces son pequeñas y específicas?
      - D: ¿Dependo de abstracciones, no de implementaciones concretas?
  └─ ¿Cuál es el modelo de datos mínimo necesario?
  └─ ¿Hay efectos secundarios? ¿Son intencionales?

PASO 4 — NANO-TAREA
  └─ ¿Puedo dividir esto en una tarea AÚN MÁS PEQUEÑA?
  └─ Si la respuesta es SÍ → divide y ejecuta solo la primera parte.
  └─ Una nano-tarea = UN archivo, UNA función, UN test.

PASO 5 — VERIFICACIÓN PREVIA
  └─ ¿El código que voy a escribir compila en mi cabeza sin errores?
  └─ ¿Respeta los tipos TypeScript estrictos?
  └─ ¿Tiene su validación con v. (validators de Convex)?
  └─ ¿Hay un test o verificación que confirme que funciona?

PASO 6 — ESCRITURA
  └─ Escribe el código solo si pasaste los 5 pasos anteriores.
  └─ Escribe el checklist de verificación debajo del código.
  └─ DETENTE. Espera confirmación del humano antes de continuar.
```

> ⚠️ Si salteas algún paso del Chain of Thought, el resultado será incorrecto.
> Cuando tengas duda, escribe tu razonamiento en comentarios antes del código.

---

## 📐 METODOLOGÍA: DIVIDE Y VENCERÁS (Nano-Tareas)

### Definición de tamaños de tarea:

| Nivel | Definición | Ejemplo |
|-------|-----------|---------|
| **Épica** | Módulo completo del sistema | "Panel de Admin Web" |
| **Historia** | Feature de una épica | "CRUD de productos" |
| **Tarea** | Implementación de una historia | "Mutation para crear producto" |
| **Nano-tarea** | Unidad atómica indivisible | "Validador `v.` del schema de producto" |

### Regla de oro:
> **Una nano-tarea = Un archivo = Un commit = Una verificación**

### Proceso de división obligatorio:
```
Épica recibida
    │
    ▼
¿Se puede dividir? ──SI──▶ Divide en Historias
    │NO
    ▼
¿Se puede dividir? ──SI──▶ Divide en Tareas
    │NO
    ▼
¿Se puede dividir? ──SI──▶ Divide en Nano-tareas
    │NO
    ▼
Implementa la Nano-tarea
    │
    ▼
Escribe verificación
    │
    ▼
DETENTE → Espera confirmación
```

---

## 🏗️ ARQUITECTURA DDD (Domain-Driven Design)

### Dominios del sistema ColmadoAI:

```
colmadoai/
├── domain/                    # Núcleo del negocio (sin dependencias externas)
│   ├── colmado/               # Agregado raíz: Colmado
│   │   ├── Colmado.ts         # Entidad raíz
│   │   ├── ColmadoId.ts       # Value Object
│   │   └── ColmadoRepository.ts # Interfaz del repositorio
│   │
│   ├── producto/              # Agregado: Producto
│   │   ├── Producto.ts
│   │   ├── Precio.ts          # Value Object (precio no puede ser negativo)
│   │   └── ProductoRepository.ts
│   │
│   ├── orden/                 # Agregado raíz: Orden
│   │   ├── Orden.ts
│   │   ├── LineaOrden.ts      # Entidad hija
│   │   ├── EstadoOrden.ts     # Value Object (enum de estados)
│   │   └── OrdenRepository.ts
│   │
│   ├── cliente/               # Agregado: Cliente
│   │   ├── Cliente.ts
│   │   ├── Telefono.ts        # Value Object (validación de formato)
│   │   └── ClienteRepository.ts
│   │
│   └── chat/                  # Agregado: Chat
│       ├── Chat.ts
│       ├── Mensaje.ts         # Entidad hija
│       └── ChatRepository.ts
│
├── application/               # Casos de uso (orquestan el dominio)
│   ├── ordenes/
│   │   ├── ConfirmarOrden.ts  # Use case
│   │   └── CancelarOrden.ts
│   ├── productos/
│   │   ├── ActualizarPrecio.ts
│   │   └── ToggleDisponibilidad.ts
│   └── chat/
│       └── ProcesarMensaje.ts
│
├── infrastructure/            # Implementaciones concretas (Convex, APIs)
│   ├── convex/                # Implementación de repositorios en Convex
│   ├── whatsapp/              # Adapter WhatsApp Cloud API
│   ├── telegram/              # Adapter Telegram Bot
│   └── deepseek/              # Adapter DeepSeek LLM
│
└── convex/                    # Capa de Convex (schema, queries, mutations, actions)
    ├── schema.ts
    ├── productos.ts
    ├── ordenes.ts
    ├── chats.ts
    ├── clientes.ts
    └── http.ts
```

### Reglas DDD que NUNCA puedes violar:
1. **El dominio NO importa nada de infrastructure/**: las entidades no conocen Convex ni APIs externas.
2. **Los repositorios son INTERFACES en domain/**: la implementación está en infrastructure/.
3. **Un agregado raíz controla su consistencia**: nadie modifica un `Orden` sin pasar por `Orden.ts`.
4. **Los Value Objects son inmutables**: `Precio`, `Telefono`, `EstadoOrden` nunca se mutan directamente.
5. **Los casos de uso en application/ son transaccionales**: hacen UNA cosa y emiten eventos de dominio.

---

## 🔷 PRINCIPIOS SOLID — Aplicación Práctica

### S — Single Responsibility Principle
```typescript
// ❌ MAL: Una función que hace todo
async function procesarMensajeWhatsApp(payload: any) {
  // valida el payload
  // busca el colmado
  // llama al LLM
  // guarda en DB
  // envía respuesta
  // notifica por Telegram
}

// ✅ BIEN: Cada clase tiene una sola razón para cambiar
class WhatsAppPayloadParser {        // solo parsea
class ColmadoFinder {               // solo busca el colmado
class LLMOrchestrator {             // solo coordina el LLM
class ChatRepository {              // solo persiste
class WhatsAppSender {              // solo envía
class TelegramNotifier {            // solo notifica
```

### O — Open/Closed Principle
```typescript
// Las entidades están cerradas para modificación, abiertas para extensión
// Si necesitas un nuevo tipo de notificación, crea un nuevo Notifier
// NO modifiques el TelegramNotifier existente

interface Notifier {
  notify(colmadoId: string, mensaje: string): Promise<void>;
}
class TelegramNotifier implements Notifier { ... }
class WhatsAppNotifier implements Notifier { ... } // nueva extensión, no modificación
```

### L — Liskov Substitution Principle
```typescript
// Cualquier implementación de repositorio debe poder sustituir a la interfaz
interface ProductoRepository {
  findById(id: string): Promise<Producto | null>;
  save(producto: Producto): Promise<void>;
}
// ConvexProductoRepository puede reemplazar a cualquier otro sin romper nada
```

### I — Interface Segregation Principle
```typescript
// ❌ MAL: Interfaz gigante
interface ColmadoService {
  getProductos(): Promise<Producto[]>;
  updatePrecio(): Promise<void>;
  getOrdenes(): Promise<Orden[]>;
  sendWhatsApp(): Promise<void>;
  notifyTelegram(): Promise<void>;
}

// ✅ BIEN: Interfaces pequeñas y específicas
interface CatalogoReader { getProductos(): Promise<Producto[]>; }
interface PrecioUpdater { updatePrecio(): Promise<void>; }
interface OrdenReader { getOrdenes(): Promise<Orden[]>; }
```

### D — Dependency Inversion Principle
```typescript
// ❌ MAL: Depende de la implementación concreta
class ProcesarMensaje {
  private db = new ConvexClient(); // acoplado a Convex
}

// ✅ BIEN: Depende de la abstracción
class ProcesarMensaje {
  constructor(
    private chatRepo: ChatRepository,     // interfaz
    private productoRepo: ProductoRepository, // interfaz
    private llm: LLMClient,               // interfaz
    private sender: MessageSender         // interfaz
  ) {}
}
```

---

## 🎯 POO — Patrones de Clases Obligatorios

### Value Objects (inmutables, se validan en el constructor):
```typescript
class Precio {
  private readonly _value: number;

  constructor(value: number) {
    if (value < 0) throw new Error("El precio no puede ser negativo");
    if (!Number.isFinite(value)) throw new Error("Precio inválido");
    this._value = value;
  }

  get value(): number { return this._value; }

  equals(other: Precio): boolean {
    return this._value === other._value;
  }

  // Value Objects son inmutables, retornan nuevas instancias
  aplicarDescuento(porcentaje: number): Precio {
    return new Precio(this._value * (1 - porcentaje / 100));
  }
}
```

### Entidades (tienen identidad única, pueden mutar):
```typescript
class Orden {
  private _estado: EstadoOrden;
  private _lineas: LineaOrden[];

  constructor(
    private readonly _id: OrdenId,
    private readonly _colmadoId: ColmadoId,
    private readonly _clienteId: ClienteId
  ) {
    this._estado = EstadoOrden.PENDIENTE;
    this._lineas = [];
  }

  agregarLinea(producto: Producto, cantidad: number): void {
    if (!producto.disponible) throw new Error(`${producto.nombre} no está disponible`);
    this._lineas.push(new LineaOrden(producto, cantidad));
  }

  confirmar(): void {
    if (this._lineas.length === 0) throw new Error("La orden no tiene productos");
    this._estado = EstadoOrden.CONFIRMADA;
  }

  // Getters read-only
  get estado(): EstadoOrden { return this._estado; }
  get lineas(): readonly LineaOrden[] { return [...this._lineas]; }
  get total(): number {
    return this._lineas.reduce((sum, l) => sum + l.subtotal, 0);
  }
}
```

---

## 📋 STACK Y RESTRICCIONES TÉCNICAS

### Stack permitido (NO uses otras herramientas):
- **Backend**: Convex (TypeScript) — queries, mutations, actions, http, cron
- **Frontend**: FlutterFlow — no escribas código Flutter a mano a menos que sea un Custom Action
- **Webhook relay**: Cloudflare Workers (JavaScript vanilla, sin frameworks)
- **LLM**: DeepSeek V3.2 API (`https://api.deepseek.com/v1/chat/completions`)
- **WhatsApp**: Meta Cloud API v20+
- **Telegram**: Bot API via HTTP directo o librería `node-telegram-bot-api` en Worker
- **Impresión**: Flutter package `print_bluetooth_thermal`

### Restricciones absolutas:
- ❌ No uses `any` en TypeScript. Siempre define el tipo.
- ❌ No escribas lógica de negocio dentro de las mutations de Convex. Esa lógica va en domain/.
- ❌ No hagas llamadas directas a APIs externas desde las mutations. Usa actions.
- ❌ No escribas más de 50 líneas por función. Si supera eso, divídela.
- ❌ No uses `console.log` en producción. Usa el sistema de logging de Convex.
- ✅ Siempre valida con `v.` en el `args` de cada mutation/query.
- ✅ Siempre maneja errores con try/catch y mensajes descriptivos.
- ✅ Siempre agrega `// @ts-check` al inicio de archivos JS (Cloudflare Worker).

---

## 🗂️ ORDEN DE IMPLEMENTACIÓN (NO saltear fases)

```
FASE 1: Fundamentos del Backend
  └─ Nano 1.1: Schema Convex — tabla colmados
  └─ Nano 1.2: Schema Convex — tabla productos
  └─ Nano 1.3: Schema Convex — tabla clientes
  └─ Nano 1.4: Schema Convex — tabla chats
  └─ Nano 1.5: Schema Convex — tabla ordenes
  └─ Nano 1.6: Convex Auth — configuración inicial
  └─ Nano 1.7: Query — getProductosActivos(colmadoId)
  └─ Nano 1.8: Mutation — crearProducto(colmadoId, datos)
  └─ Nano 1.9: Mutation — actualizarPrecio(productoId, precio)
  └─ Nano 1.10: Mutation — toggleDisponibilidad(productoId)

FASE 2: Webhook y Agente LLM
  └─ Nano 2.1: Cloudflare Worker — verificación challenge Meta
  └─ Nano 2.2: Cloudflare Worker — relay a Convex HTTP Action
  └─ Nano 2.3: Convex HTTP Action — parser payload WhatsApp
  └─ Nano 2.4: Convex HTTP Action — llamada a DeepSeek V3.2
  └─ Nano 2.5: Convex HTTP Action — guardar mensaje en tabla chats
  └─ Nano 2.6: Convex HTTP Action — responder por WhatsApp API
  └─ Nano 2.7: Convex Mutation — insertarOrden cuando LLM confirma
  └─ Nano 2.8: Convex Action — System Prompt dinámico con catálogo

FASE 3: Telegram Bot
  └─ Nano 3.1: Convex Action — enviar mensaje Telegram al colmadero
  └─ Nano 3.2: Convex Webhook — recibir comandos de Telegram
  └─ Nano 3.3: Handler comando /precio
  └─ Nano 3.4: Handler comando /deshabilitar y /habilitar
  └─ Nano 3.5: Handler botones inline (confirmar/cancelar orden)
  └─ Nano 3.6: Handler /tomar_chat y /liberar_chat
  └─ Nano 3.7: Convex Cron — notificación resumen diario

FASE 4: App Android (FlutterFlow)
  └─ Nano 4.1: Conectar Convex SDK en FlutterFlow
  └─ Nano 4.2: Stream Query — ordenes lista_para_imprimir
  └─ Nano 4.3: Custom Action — conectar impresora Bluetooth
  └─ Nano 4.4: Custom Action — construir ticket ESC/POS
  └─ Nano 4.5: Custom Action — imprimir y confirmar en Convex
  └─ Nano 4.6: Pantalla principal con lista de órdenes

FASE 5: Panel Web Admin
  └─ Nano 5.1: Pantalla Login (Convex Auth)
  └─ Nano 5.2: Query — métricas del día (órdenes, ingresos)
  └─ Nano 5.3: Dashboard con KPIs
  └─ Nano 5.4: Pantalla Catálogo — lista de productos
  └─ Nano 5.5: Form — agregar/editar producto
  └─ Nano 5.6: Pantalla Chats en Vivo — stream de chats activos
  └─ Nano 5.7: Acción — tomar control / liberar chat
  └─ Nano 5.8: Pantalla Clientes
  └─ Nano 5.9: Pantalla Órdenes con filtros
  └─ Nano 5.10: Pantalla Configuración del Agente
```

---

## ✅ PROTOCOLO DE VERIFICACIÓN POST-IMPLEMENTACIÓN

Después de cada nano-tarea, verifica en este orden:

```
1. COMPILA
   └─ TypeScript: npx tsc --noEmit (0 errores)
   └─ Convex: npx convex dev (sin errores en consola)

2. FUNCIONA EN AISLADO
   └─ La función/módulo puede ser llamado de forma independiente
   └─ Escribe una llamada de prueba en los comentarios

3. CONTRATO RESPETADO
   └─ Los tipos de entrada y salida coinciden con la interfaz definida
   └─ Los validators v. cubren todos los campos obligatorios

4. PRINCIPIOS RESPETADOS
   └─ ¿Tiene una sola responsabilidad? (S)
   └─ ¿El dominio no importa infrastructure? (D)
   └─ ¿Menos de 50 líneas por función?

5. CHECKLIST MARCADO
   └─ Marca el ítem correspondiente en checklists/fase[N].md
   └─ Solo entonces informa al humano que está listo
```

---

## 🚨 MANEJO DE ERRORES Y BLOQUEOS

Si te encuentras bloqueado o inseguro:

```
1. NO inventes una solución que no conoces con certeza.
2. Escribe: "// TODO: [descripción del problema]" en el código.
3. Informa al humano exactamente qué necesitas saber.
4. Proporciona las 2-3 opciones posibles con sus tradeoffs.
5. Espera decisión antes de continuar.
```

Si un test falla:
```
1. Lee el error completo, no el resumen.
2. Identifica el archivo y línea exacta.
3. Aplica Chain of Thought desde el PASO 1 para ese error.
4. Corrige SOLO el error, no refactorices nada más.
5. Re-ejecuta la verificación completa.
```
