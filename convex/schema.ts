import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // Nano 1.1 - Tabla colmados
  colmados: defineTable({
    nombre: v.string(),
    telefono_whatsapp: v.string(),
    whatsapp_phone_id: v.string(), // Bug #B: Phone ID por colmado
    telegram_chat_id: v.optional(v.string()),
    whatsapp_token: v.string(),
    activo: v.boolean(),
    created_at: v.number(),
  }),

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