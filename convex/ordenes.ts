import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ QUERIES ============

// Query: getOrdenesRecientes
export const getOrdenesRecientes = query({
  args: {
    colmadoId: v.id("colmados"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit || 10;
    return await ctx.db
      .query("ordenes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .order("desc")
      .take(limit);
  },
});

// Query: getOrdenesPorEstado
export const getOrdenesPorEstado = query({
  args: {
    colmadoId: v.id("colmados"),
    estado: v.union(
      v.literal("confirmada"),
      v.literal("lista_para_imprimir"),
      v.literal("impresa"),
      v.literal("entregada"),
      v.literal("cancelada")
    ),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("ordenes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .filter((q) => q.eq("estado", args.estado))
      .order("desc")
      .collect();
  },
});

// Query: getOrdenById
export const getOrdenById = query({
  args: {
    ordenId: v.id("ordenes"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.ordenId);
  },
});

// Query: getMetricasDiarias
export const getMetricasDiarias = query({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    const ahora = Date.now();
    const inicioDia = new Date().setHours(0, 0, 0, 0);
    
    // Órdenes de hoy
    const ordenesHoy = await ctx.db
      .query("ordenes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .filter((q) => q.gte("created_at", inicioDia))
      .collect();

    // Productos activos
    const productosActivos = await ctx.db
      .query("productos")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .filter((q) => q.eq("disponible", true))
      .collect();

    // Chats activos (última actividad en las últimas 24 horas)
    const hace24h = ahora - 24 * 60 * 60 * 1000;
    const chatsActivos = await ctx.db
      .query("chats")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .filter((q) => q.gte("ultima_actividad", hace24h))
      .collect();

    const ingresosHoy = ordenesHoy
      .filter((o) => o.estado !== "cancelada")
      .reduce((sum, o) => sum + o.total, 0);

    return {
      ordenesDelDia: ordenesHoy.length,
      ingresosHoy,
      productosActivos: productosActivos.length,
      chatsActivos: chatsActivos.length,
    };
  },
});

// ============ MUTATIONS ============

// Mutation: crearOrden
export const crearOrden = mutation({
  args: {
    colmadoId: v.id("colmados"),
    clienteId: v.id("clientes"),
    productos: v.array(
      v.object({
        productoId: v.id("productos"),
        nombre: v.string(),
        cantidad: v.number(),
        precioUnitario: v.number(),
      })
    ),
    direccion: v.optional(v.string()),
    metodoPago: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Calcular total
    const total = args.productos.reduce((sum, p) => {
      return sum + p.cantidad * p.precioUnitario;
    }, 0);

    const ordenId = await ctx.db.insert("ordenes", {
      colmado_id: args.colmadoId,
      cliente_id: args.clienteId,
      productos: args.productos.map((p) => ({
        producto_id: p.productoId,
        nombre: p.nombre,
        cantidad: p.cantidad,
        precio_unitario: p.precioUnitario,
        subtotal: p.cantidad * p.precioUnitario,
      })),
      total,
      estado: "confirmada",
      direccion: args.direccion,
      metodo_pago: args.metodoPago,
      created_at: Date.now(),
    });

    return ordenId;
  },
});

// Mutation: actualizarEstadoOrden
export const actualizarEstadoOrden = mutation({
  args: {
    ordenId: v.id("ordenes"),
    estado: v.union(
      v.literal("confirmada"),
      v.literal("lista_para_imprimir"),
      v.literal("impresa"),
      v.literal("entregada"),
      v.literal("cancelada")
    ),
  },
  handler: async (ctx, args) => {
    const orden = await ctx.db.get(args.ordenId);
    if (!orden) {
      throw new Error("Orden no encontrada");
    }

    await ctx.db.patch(args.ordenId, { estado: args.estado });

    return { success: true, ordenId: args.ordenId, estado: args.estado };
  },
});

// Mutation: cancelarOrden
export const cancelarOrden = mutation({
  args: {
    ordenId: v.id("ordenes"),
  },
  handler: async (ctx, args) => {
    const orden = await ctx.db.get(args.ordenId);
    if (!orden) {
      throw new Error("Orden no encontrada");
    }

    await ctx.db.patch(args.ordenId, { estado: "cancelada" });

    return { success: true, ordenId: args.ordenId };
  },
});

// ============ QUERIES PARA ADMIN WEB ============

// Query: listByEstado — órdenes filtradas por estado (o "todos" para todas)
export const listByEstado = query({
  args: { colmado_id: v.id("colmados"), estado: v.string() },
  handler: async (ctx, args) => {
    if (args.estado === "todos") {
      return await ctx.db
        .query("ordenes")
        .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmado_id))
        .order("desc")
        .take(100);
    }
    return await ctx.db
      .query("ordenes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmado_id))
      .filter((q) => q.eq(q.field("estado"), args.estado))
      .order("desc")
      .take(100);
  },
});

// Query: getMetricas — métricas de ventas en un rango de fechas
export const getMetricas = query({
  args: { colmado_id: v.id("colmados"), desde: v.number(), hasta: v.number() },
  handler: async (ctx, args) => {
    const ordenes = await ctx.db
      .query("ordenes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmado_id))
      .filter((q) =>
        q.and(q.gte(q.field("created_at"), args.desde), q.lte(q.field("created_at"), args.hasta))
      )
      .collect();

    const ventasTotal = ordenes.reduce((s, o) => s + o.total, 0);
    const ticketPromedio = ordenes.length > 0 ? ventasTotal / ordenes.length : 0;

    const porDia: Record<string, number> = {};
    for (const o of ordenes) {
      const dia = new Date(o.created_at).toISOString().split("T")[0];
      porDia[dia] = (porDia[dia] || 0) + o.total;
    }

    return { ventasTotal, totalOrdenes: ordenes.length, ticketPromedio, ventasPorDia: porDia };
  },
});