import { mutation } from "./_generated/server";
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