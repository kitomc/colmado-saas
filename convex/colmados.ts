import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ QUERIES ============

// Query: getMyColmado — retorna el colmado + email del usuario autenticado
export const getMyColmado = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      return { colmado: null, userEmail: null };
    }

    const colmado = await ctx.db
      .query("colmados")
      .withIndex("by_user_id", (q) => q.eq("user_id", identity.subject))
      .first();

    return {
      colmado: colmado ?? null,
      userEmail: identity.email ?? null,
    };
  },
});

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
    whatsappPhoneId: v.string(),  // Bug #B fix
    telegramChatId: v.optional(v.string()),
    whatsappToken: v.string(),
  },
  handler: async (ctx, args) => {
    const colmadoId = await ctx.db.insert("colmados", {
      nombre: args.nombre,
      telefono_whatsapp: args.telefonoWhatsApp,
      whatsapp_phone_id: args.whatsappPhoneId,  // Bug #B fix
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
    whatsappPhoneId: v.optional(v.string()),  // Bug #B fix
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
    if (args.whatsappPhoneId) updates.whatsapp_phone_id = args.whatsappPhoneId;
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

// ============ EVOLUTION API MUTATIONS ============

// Mutation: actualizarEvolution — guarda el instance_name de Evolution API
export const actualizarEvolution = mutation({
  args: { colmadoId: v.id("colmados"), instanceName: v.string() },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.colmadoId, {
      evolution_instance_name: args.instanceName,
    });
  },
});

// Mutation: actualizarEstadoEvolution — actualiza estado de conexión Evolution
export const actualizarEstadoEvolution = mutation({
  args: { instanceName: v.string(), connected: v.boolean() },
  handler: async (ctx, args) => {
    const colmado = await ctx.db
      .query("colmados")
      .filter((q) => q.eq(q.field("evolution_instance_name"), args.instanceName))
      .first();
    if (colmado) {
      await ctx.db.patch(colmado._id, {
        evolution_connected: args.connected,
        evolution_connected_at: args.connected ? Date.now() : undefined,
      });
    }
  },
});

// Mutation: marcarOnboardingCompleto — marca el onboarding como finalizado
export const marcarOnboardingCompleto = mutation({
  args: { colmadoId: v.id("colmados") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.colmadoId, { onboarding_completo: true });
  },
});