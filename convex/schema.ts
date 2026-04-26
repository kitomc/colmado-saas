import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";
import { authTables } from "./auth";

export default defineSchema({
  // Convex Auth tables (users + sessions)
  ...authTables,

  // Nano 1.1 - Tabla colmados
  // ACTUALIZADO: campos Embedded Signup de Meta + Convex Auth user_id
  colmados: defineTable({
    nombre: v.string(),
    telefono_whatsapp: v.string(),        // Número visible: +18091234567
    whatsapp_phone_id: v.string(),        // Phone Number ID de Meta
    whatsapp_token: v.string(),           // Token del System User (permanente)
    waba_id: v.optional(v.string()),      // WhatsApp Business Account ID
    meta_conectado: v.optional(v.boolean()), // true = conectado via Embedded Signup
    meta_connected_at: v.optional(v.number()), // timestamp de conexión
    evolution_instance_name: v.optional(v.string()),
    evolution_connected: v.optional(v.boolean()),
    evolution_connected_at: v.optional(v.number()),
    onboarding_completo: v.optional(v.boolean()),
    telegram_chat_id: v.optional(v.string()),
    user_id: v.optional(v.id("users")),   // Convex Auth user ID (opcional para backward compat)
    activo: v.boolean(),
    created_at: v.number(),
  })
    .index("by_telefono_whatsapp", ["telefono_whatsapp"])
    .index("by_waba_id", ["waba_id"])
    .index("by_user_id", ["user_id"]),

  // Tabla usuarios — mapeo entre Convex Auth users y roles del sistema
  usuarios: defineTable({
    userId: v.id("users"),
    colmado_id: v.id("colmados"),
    rol: v.union(v.literal("super_admin"), v.literal("admin_colmado"), v.literal("empleado")),
    email: v.string(),
    nombre: v.optional(v.string()),
    activo: v.boolean(),
    created_at: v.number(),
  })
    .index("by_userId", ["userId"])
    .index("by_colmado_id", ["colmado_id"]),

  // Nano 1.2 - Tabla productos
  productos: defineTable({
    colmado_id: v.id("colmados"),
    nombre: v.string(),
    precio: v.number(),
    disponible: v.boolean(),
    categoria: v.string(),
    imagen_url: v.optional(v.string()),
    created_at: v.number(),
  })
    .index("by_colmado_id", ["colmado_id"]),

  // Nano 1.3 - Tabla clientes
  clientes: defineTable({
    colmado_id: v.id("colmados"),
    telefono: v.string(),
    nombre: v.optional(v.string()),
    total_ordenes: v.number(),
    ultima_orden: v.optional(v.number()),
    created_at: v.number(),
  })
    .index("by_colmado_telefono", ["colmado_id", "telefono"])
    .index("by_colmado_id", ["colmado_id"]),

  // Nano 1.4 - Tabla chats
  chats: defineTable({
    colmado_id: v.id("colmados"),
    cliente_telefono: v.string(),
    historial: v.array(
      v.object({
        role: v.union(v.literal("user"), v.literal("assistant"), v.literal("system")),
        content: v.string(),
      })
    ),
    bot_activo: v.boolean(),
    ultima_actividad: v.number(),
    created_at: v.number(),
  })
    .index("by_colmado_telefono", ["colmado_id", "cliente_telefono"])
    .index("by_colmado_id", ["colmado_id"]),

  // Nano 1.5 - Tabla ordenes
  ordenes: defineTable({
    colmado_id: v.id("colmados"),
    cliente_id: v.id("clientes"),
    productos: v.array(
      v.object({
        producto_id: v.id("productos"),
        nombre: v.string(),
        cantidad: v.number(),
        precio_unitario: v.number(),
        subtotal: v.number(),
      })
    ),
    total: v.number(),
    estado: v.union(
      v.literal("confirmada"),
      v.literal("lista_para_imprimir"),
      v.literal("impresa"),
      v.literal("entregada"),
      v.literal("cancelada")
    ),
    direccion: v.optional(v.string()),
    metodo_pago: v.optional(v.string()),
    created_at: v.number(),
  })
    .index("by_estado", ["estado"])
    .index("by_colmado_id", ["colmado_id"]),
});
