import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ QUERIES ============

// Query: getClientes
export const getClientes = query({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("clientes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .order("desc")
      .collect();
  },
});

// Query: getClienteByTelefono
export const getClienteByTelefono = query({
  args: {
    colmadoId: v.id("colmados"),
    telefono: v.string(),
  },
  handler: async (ctx, args) => {
    const clientes = await ctx.db
      .query("clientes")
      .withIndex("by_colmado_telefono", (q) => 
        q.eq("colmado_id", args.colmadoId).eq("telefono", args.telefono)
      )
      .collect();
    return clientes[0] || null;
  },
});

// Query: getClienteById
export const getClienteById = query({
  args: {
    clienteId: v.id("clientes"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.clienteId);
  },
});

// ============ MUTATIONS ============

// Mutation: crearOActualizarCliente
export const crearOActualizarCliente = mutation({
  args: {
    colmadoId: v.id("colmados"),
    telefono: v.string(),
    nombre: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Buscar cliente existente
    const clientesExistentes = await ctx.db
      .query("clientes")
      .withIndex("by_colmado_telefono", (q) => 
        q.eq("colmado_id", args.colmadoId).eq("telefono", args.telefono)
      )
      .collect();

    if (clientesExistentes.length > 0) {
      // Actualizar cliente existente
      const cliente = clientesExistentes[0];
      await ctx.db.patch(cliente._id, {
        nombre: args.nombre || cliente.nombre,
        total_ordenes: cliente.total_ordenes + 1,
        ultima_orden: Date.now(),
      });
      return cliente._id;
    } else {
      // Crear nuevo cliente
      const clienteId = await ctx.db.insert("clientes", {
        colmado_id: args.colmadoId,
        telefono: args.telefono,
        nombre: args.nombre,
        total_ordenes: 1,
        ultima_orden: Date.now(),
        created_at: Date.now(),
      });
      return clienteId;
    }
  },
});

// Mutation: actualizarCliente
export const actualizarCliente = mutation({
  args: {
    clienteId: v.id("clientes"),
    nombre: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const cliente = await ctx.db.get(args.clienteId);
    if (!cliente) {
      throw new Error("Cliente no encontrado");
    }

    const updates: Record<string, unknown> = {};
    if (args.nombre) updates.nombre = args.nombre;

    await ctx.db.patch(args.clienteId, updates);

    return args.clienteId;
  },
});