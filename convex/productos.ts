import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// Nano 1.8 - Mutation: crearProducto
export const crearProducto = mutation({
  args: {
    colmadoId: v.id("colmados"),
    nombre: v.string(),
    precio: v.number(),
    categoria: v.string(),
    imagen_url: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Validar precio positivo
    if (args.precio <= 0) {
      throw new Error("El precio debe ser mayor a 0");
    }

    const productoId = await ctx.db.insert("productos", {
      colmado_id: args.colmadoId,
      nombre: args.nombre,
      precio: args.precio,
      disponible: true,
      categoria: args.categoria,
      imagen_url: args.imagen_url,
      created_at: Date.now(),
    });

    return productoId;
  },
});

// Nano 1.9 - Mutation: actualizarPrecio
export const actualizarPrecio = mutation({
  args: {
    productoId: v.id("productos"),
    precio: v.number(),
  },
  handler: async (ctx, args) => {
    // Validar precio positivo
    if (args.precio <= 0) {
      throw new Error("El precio debe ser mayor a 0");
    }

    // Obtener el producto para verificar que existe
    const producto = await ctx.db.get(args.productoId);
    if (!producto) {
      throw new Error("Producto no encontrado");
    }

    // Actualizar el precio
    await ctx.db.patch(args.productoId, {
      precio: args.precio,
    });

    return args.productoId;
  },
});

// Nano 1.10 - Mutation: toggleDisponibilidad
export const toggleDisponibilidad = mutation({
  args: {
    productoId: v.id("productos"),
  },
  handler: async (ctx, args) => {
    // Obtener el producto
    const producto = await ctx.db.get(args.productoId);
    if (!producto) {
      throw new Error("Producto no encontrado");
    }

    // Invertir el estado de disponibilidad
    await ctx.db.patch(args.productoId, {
      disponible: !producto.disponible,
    });

    return !producto.disponible;
  },
});

// Mutation adicional: actualizarProducto (editar completo)
export const actualizarProducto = mutation({
  args: {
    productoId: v.id("productos"),
    nombre: v.optional(v.string()),
    precio: v.optional(v.number()),
    categoria: v.optional(v.string()),
    imagen_url: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const producto = await ctx.db.get(args.productoId);
    if (!producto) {
      throw new Error("Producto no encontrado");
    }

    // Validar precio si se proporciona
    if (args.precio !== undefined && args.precio <= 0) {
      throw new Error("El precio debe ser mayor a 0");
    }

    const updates: Record<string, unknown> = {};
    if (args.nombre) updates.nombre = args.nombre;
    if (args.precio) updates.precio = args.precio;
    if (args.categoria) updates.categoria = args.categoria;
    if (args.imagen_url !== undefined) updates.imagen_url = args.imagen_url;

    await ctx.db.patch(args.productoId, updates);

    return args.productoId;
  },
});

// Mutation adicional: eliminarProducto
export const eliminarProducto = mutation({
  args: {
    productoId: v.id("productos"),
  },
  handler: async (ctx, args) => {
    const producto = await ctx.db.get(args.productoId);
    if (!producto) {
      throw new Error("Producto no encontrado");
    }

    await ctx.db.delete(args.productoId);

    return { success: true };
  },
});

// ─── Query: productosPorCategoria ────────────────────────────────────────────

/**
 * Query: productosPorCategoria
 *
 * Filtra productos de un colmado por categoría y los ordena alfabéticamente.
 * Retorna TODOS los productos (disponibles y no disponibles) — el caller filtra.
 *
 * @param colmadoId - ID del colmado
 * @param categoria - Categoría exacta a filtrar (case-sensitive)
 * @returns Lista de productos ordenados por nombre
 */
export const productosPorCategoria = query({
  args: {
    colmadoId: v.id("colmados"),
    categoria: v.string(),
  },
  handler: async (ctx, args) => {
    // Edge case: categoría vacía retorna array vacío
    if (!args.categoria || args.categoria.trim() === "") {
      return [];
    }

    // Traer todos los productos del colmado (usa índice by_colmado_id)
    const productos = await ctx.db
      .query("productos")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .collect();

    // Filtrar por categoría y ordenar por nombre ASC
    return productos
      .filter((p) => p.categoria === args.categoria)
      .sort((a, b) => a.nombre.localeCompare(b.nombre));
  },
});

// ─── Query: listByColmado ──────────────────────────────────────────────────────

/**
 * Query: listByColmado
 *
 * Retorna todos los productos de un colmado, ordenados por nombre.
 *
 * @param colmado_id - ID del colmado
 * @returns Lista completa de productos
 */
export const listByColmado = query({
  args: { colmado_id: v.id("colmados") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("productos")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmado_id))
      .collect();
  },
});