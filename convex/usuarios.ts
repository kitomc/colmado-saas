import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ QUERIES ============

export const getMe = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) return null;
    const usuario = await ctx.db
      .query("usuarios")
      .withIndex("by_userId", (q) => q.eq("userId", identity.subject))
      .first();
    if (!usuario) return null;
    const colmado = await ctx.db.get(usuario.colmado_id);
    return { ...usuario, colmado };
  },
});

// ============ MUTATIONS ============

export const registrar = mutation({
  args: {
    email: v.string(),
    nombre: v.string(),
    nombre_colmado: v.string(),
    telefono: v.string(),
  },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("No autenticado");

    const colmadoId = await ctx.db.insert("colmados", {
      nombre: args.nombre_colmado,
      telefono_whatsapp: args.telefono,
      activo: true,
      created_at: Date.now(),
    });

    await ctx.db.insert("usuarios", {
      userId: identity.subject,
      colmado_id: colmadoId,
      rol: "admin_colmado",
      email: args.email,
      nombre: args.nombre,
      activo: true,
      created_at: Date.now(),
    });

    return colmadoId;
  },
});
