import { action } from "./_generated/server";
import { v } from "convex/values";
import { internal } from "./_generated/api";

// ============ CONFIG ============

const EVOLUTION_API_URL = process.env.EVOLUTION_API_URL || "http://localhost:8080";
const EVOLUTION_API_KEY = "colmado-api-2026-xyz";

// ============ HELPERS ============

/**
 * Helper: fetch con autenticación para Evolution API
 */
async function evolutionFetch(path: string, options: RequestInit = {}): Promise<Response> {
  return fetch(`${EVOLUTION_API_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      apikey: EVOLUTION_API_KEY,
      ...(options.headers as Record<string, string> | undefined),
    },
  });
}

// ============ ACTIONS ============

/**
 * Action: crearInstancia
 *
 * Crea una instancia de Evolution API para un colmado.
 * Luego actualiza Convex con el instance_name.
 *
 * POST /instance/create
 */
export const crearInstancia = action({
  args: {
    colmadoId: v.id("colmados"),
    instanceName: v.string(),
  },
  handler: async (ctx, args) => {
    const response = await evolutionFetch("/instance/create", {
      method: "POST",
      body: JSON.stringify({
        instanceName: args.instanceName,
        qrcode: true,
        integration: "WHATSAPP-BAILEYS",
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Evolution API error (${response.status}): ${errorBody}`);
    }

    const data = await response.json();

    // Persistir el instance_name en el colmado
    await ctx.runMutation(internal.colmados.actualizarEvolution, {
      colmadoId: args.colmadoId,
      instanceName: args.instanceName,
    });

    return data;
  },
});

/**
 * Action: obtenerQR
 *
 * Obtiene el QR code para conectar una instancia de WhatsApp.
 *
 * GET /instance/connect/{name}
 */
export const obtenerQR = action({
  args: {
    instanceName: v.string(),
  },
  handler: async (ctx, args) => {
    const response = await evolutionFetch(`/instance/connect/${args.instanceName}`, {
      method: "GET",
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Evolution API error (${response.status}): ${errorBody}`);
    }

    return await response.json();
  },
});

/**
 * Action: verificarEstado
 *
 * Verifica el estado de conexión de una instancia.
 * Actualiza Convex con connected = true/false.
 *
 * GET /instance/connectionState/{name}
 */
export const verificarEstado = action({
  args: {
    instanceName: v.string(),
  },
  handler: async (ctx, args) => {
    const response = await evolutionFetch(`/instance/connectionState/${args.instanceName}`, {
      method: "GET",
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Evolution API error (${response.status}): ${errorBody}`);
    }

    const data = await response.json();

    // Actualizar estado de conexión en Convex
    await ctx.runMutation(internal.colmados.actualizarEstadoEvolution, {
      instanceName: args.instanceName,
      connected: data.state === "open",
    });

    return data;
  },
});

/**
 * Action: desconectar
 *
 * Desconecta (logout) una instancia de WhatsApp.
 *
 * DELETE /instance/logout/{name}
 */
export const desconectar = action({
  args: {
    instanceName: v.string(),
  },
  handler: async (ctx, args) => {
    const response = await evolutionFetch(`/instance/logout/${args.instanceName}`, {
      method: "DELETE",
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Evolution API error (${response.status}): ${errorBody}`);
    }

    const data = await response.json();

    // Marcar como desconectado en Convex
    await ctx.runMutation(internal.colmados.actualizarEstadoEvolution, {
      instanceName: args.instanceName,
      connected: false,
    });

    return data;
  },
});

/**
 * Action: enviarMensajePrueba
 *
 * Envía un mensaje de texto de prueba a través de una instancia conectada.
 *
 * POST /message/sendText/{name}
 */
export const enviarMensajePrueba = action({
  args: {
    instanceName: v.string(),
    numero: v.string(),
    mensaje: v.string(),
  },
  handler: async (ctx, args) => {
    const response = await evolutionFetch(`/message/sendText/${args.instanceName}`, {
      method: "POST",
      body: JSON.stringify({
        number: args.numero,
        text: args.mensaje,
        delay: 1200,
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Evolution API error (${response.status}): ${errorBody}`);
    }

    return await response.json();
  },
});
