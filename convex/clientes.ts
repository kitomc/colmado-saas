import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ VALIDATION HELPERS ============

interface ValidationResult {
  valid: boolean;
  error?: string;
}

/**
 * Valida formato de teléfono RD (República Dominicana)
 * Acepta: 8095551234, 8295551234, 8495551234, +18095551234
 */
function validateTelefonoRD(telefono: string | undefined): ValidationResult {
  if (!telefono || telefono.trim() === "") {
    return { valid: false, error: "El teléfono no puede estar vacío" };
  }

  const clean = telefono.replace(/\s/g, "");

  // Check: solo dígitos y +
  if (!/^\+?\d+$/.test(clean)) {
    return { valid: false, error: "Teléfono inválido: solo se permiten números" };
  }

  // Normalizar: remover +1 si existe
  const normalized = clean.startsWith("+1") ? clean.slice(2) : 
                      clean.startsWith("1") && clean.length === 11 ? clean.slice(1) : clean;

  // Check: debe tener 10 dígitos
  if (normalized.length !== 10) {
    return { valid: false, error: "El teléfono debe tener 10 dígitos" };
  }

  // Check: prefijo válido RD (809, 829, 849)
  const prefix = normalized.slice(0, 3);
  if (!["809", "829", "849"].includes(prefix)) {
    return { valid: false, error: "Prefijo RD inválido. Use 809, 829 o 849" };
  }

  return { valid: true };
}

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
    // Validar teléfono RD antes de continuar
    const validation = validateTelefonoRD(args.telefono);
    if (!validation.valid) {
      throw new Error(validation.error);
    }

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
    telefono: v.optional(v.string()),
    nombre: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const cliente = await ctx.db.get(args.clienteId);
    if (!cliente) {
      throw new Error("Cliente no encontrado");
    }

    // Validar teléfono si se proporciona
    if (args.telefono) {
      const validation = validateTelefonoRD(args.telefono);
      if (!validation.valid) {
        throw new Error(validation.error);
      }
    }

    const updates: Record<string, unknown> = {};
    if (args.nombre) updates.nombre = args.nombre;
    if (args.telefono) updates.telefono = args.telefono;

    await ctx.db.patch(args.clienteId, updates);

    return args.clienteId;
  },
});

// ============ QUERIES PARA ADMIN WEB ============

// Query: listByColmado — últimos 100 clientes de un colmado
export const listByColmado = query({
  args: { colmado_id: v.id("colmados") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("clientes")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmado_id))
      .order("desc")
      .take(100);
  },
});