import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ QUERIES ============

// Query: getColmadoById
export const getColmadoById = query({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.colmadoId);
  },
});

// Query: getColmados (todos los colmados - admin)
export const getColmados = query({
  handler: async (ctx) => {
    return await ctx.db.query("colmados").collect();
  },
});

// ============ MUTATIONS ============

// Mutation: crearColmado
export const crearColmado = mutation({
  args: {
    nombre: v.string(),
    telefonoWhatsApp: v.string(),
    telegramChatId: v.optional(v.string()),
    whatsappToken: v.string(),
  },
  handler: async (ctx, args) => {
    const colmadoId = await ctx.db.insert("colmados", {
      nombre: args.nombre,
      telefono_whatsapp: args.telefonoWhatsApp,
      telegram_chat_id: args.telegramChatId,
      whatsapp_token: args.whatsappToken,
      activo: true,
      created_at: Date.now(),
    });

    return colmadoId;
  },
});

// Mutation: actualizarColmado
export const actualizarColmado = mutation({
  args: {
    colmadoId: v.id("colmados"),
    nombre: v.optional(v.string()),
    telefonoWhatsApp: v.optional(v.string()),
    telegramChatId: v.optional(v.string()),
    whatsappToken: v.optional(v.string()),
    activo: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const colmado = await ctx.db.get(args.colmadoId);
    if (!colmado) {
      throw new Error("Colmado no encontrado");
    }

    const updates: Record<string, unknown> = {};
    if (args.nombre) updates.nombre = args.nombre;
    if (args.telefonoWhatsApp) updates.telefono_whatsapp = args.telefonoWhatsApp;
    if (args.telegramChatId !== undefined) updates.telegram_chat_id = args.telegramChatId;
    if (args.whatsappToken) updates.whatsapp_token = args.whatsappToken;
    if (args.activo !== undefined) updates.activo = args.activo;

    await ctx.db.patch(args.colmadoId, updates);

    return args.colmadoId;
  },
});

// Mutation: toggleColmadoActivo
export const toggleColmadoActivo = mutation({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    const colmado = await ctx.db.get(args.colmadoId);
    if (!colmado) {
      throw new Error("Colmado no encontrado");
    }

    await ctx.db.patch(args.colmadoId, {
      activo: !colmado.activo,
    });

    return !colmado.activo;
  },
});