import { httpAction } from "./_generated/server";
import { mutation } from "./_generated/server";
import { v } from "convex/values";
import { httpRouter } from "convex/server";
import { handleTelegram } from "./telegram";
import { api } from "./_generated/api";
import { auth } from "./auth";

// @ts-check

/**
 * Nano 2.3: Parser del payload de WhatsApp
 */
interface WhatsAppMessage {
  from: string;
  text: { body: string };
  timestamp: string;
  type: string;
}

interface ParsedMessage {
  telefono: string;
  mensaje: string;
  timestamp: number;
}

function parseWhatsAppPayload(payload: any): ParsedMessage | null {
  try {
    const entry = payload.entry?.[0];
    const changes = entry?.changes?.[0];
    const message: WhatsAppMessage = changes?.value?.messages?.[0];
    if (!message || message.type !== "text" || !message.text?.body) return null;
    return {
      telefono: message.from,
      mensaje: message.text.body,
      timestamp: parseInt(message.timestamp) * 1000 || Date.now(),
    };
  } catch (error) {
    console.error("[Parse Error]", error);
    return null;
  }
}

async function callGroq(
  messages: { role: string; content: string }[],
  systemPrompt: string
): Promise<string> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error("GROQ_API_KEY no configurada");

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "system", content: systemPrompt }, ...messages],
      temperature: 0.7,
      max_tokens: 500,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Groq API error: ${response.status} - ${error}`);
  }
  const data = await response.json();
  return data.choices?.[0]?.message?.content || "";
}

async function saveChatMessage(
  ctx: any,
  colmadoId: string,
  telefono: string,
  userMessage: string,
  botResponse: string
) {
  const existingChats = await ctx.db
    .query("chats")
    .withIndex("by_colmado_telefono", (q: any) =>
      q.eq("colmado_id", colmadoId).eq("cliente_telefono", telefono)
    )
    .collect();
  const now = Date.now();
  if (existingChats.length > 0) {
    const chat = existingChats[0];
    await ctx.db.patch(chat._id, {
      historial: [
        ...chat.historial,
        { role: "user", content: userMessage },
        { role: "assistant", content: botResponse },
      ],
      ultima_actividad: now,
    });
    return chat._id;
  } else {
    return await ctx.db.insert("chats", {
      colmado_id: colmadoId,
      cliente_telefono: telefono,
      historial: [
        { role: "user", content: userMessage },
        { role: "assistant", content: botResponse },
      ],
      bot_activo: true,
      ultima_actividad: now,
      created_at: now,
    });
  }
}

async function sendWhatsAppMessage(
  phoneNumber: string,
  message: string,
  token: string,
  phoneId: string
): Promise<void> {
  const response = await fetch(`https://graph.facebook.com/v20.0/${phoneId}/messages`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: phoneNumber,
      type: "text",
      text: { body: message },
    }),
  });
  if (!response.ok) {
    const error = await response.text();
    throw new Error(`WhatsApp API error: ${response.status} - ${error}`);
  }
}

interface OrderJSON {
  orden?: {
    productos: Array<{ nombre: string; cantidad: number; precio: number }>;
    nombre?: string;
    direccion?: string;
    metodo_pago?: string;
  };
}

function detectOrderJSON(response: string): OrderJSON | null {
  try {
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return null;
    const parsed = JSON.parse(jsonMatch[0]);
    if (parsed.orden && Array.isArray(parsed.orden.productos)) return parsed;
    return null;
  } catch { return null; }
}

async function buildSystemPrompt(ctx: any, colmadoId: string): Promise<string> {
  const colmado = await ctx.db.get(colmadoId);
  const productos = await ctx.db
    .query("productos")
    .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", colmadoId))
    .filter((q: any) => q.eq("disponible", true))
    .collect();
  const catalogo = productos
    .map((p: any) => `- ${p.nombre}: RD$${p.precio} (${p.categoria})`)
    .join("\n");
  return `
Eres el asistente de ventas de ${colmado?.nombre || "un colmado"}.

CATALOGO DE PRODUCTOS:
${catalogo || "No hay productos disponibles"}

INSTRUCCIONES:
1. Saludar amablemente y preguntar que necesita el cliente
2. Cuando el cliente pida productos, ofrecer el catalogo disponible
3. Cuando el cliente confirme una orden, pedir: nombre, direccion y metodo de pago
4. Cuando tengas toda la informacion, generar un JSON:
{"orden": {"productos": [{"nombre": "...", "cantidad": N, "precio": N}], "nombre": "...", "direccion": "...", "metodo_pago": "..."}}
5. Solo generar JSON cuando el cliente confirme todos los datos
6. Responder en espanol, de forma amable y concisa
`.trim();
}

// ============ HTTP ACTION: WhatsApp Webhook ============

export const handleWhatsApp = httpAction(async (ctx, request) => {
  try {
    if (request.method === "GET") {
      const url = new URL(request.url);
      const mode = url.searchParams.get("hub.mode");
      const token = url.searchParams.get("hub.verify_token");
      const challenge = url.searchParams.get("hub.challenge");
      if (mode === "subscribe" && token === process.env.WHATSAPP_VERIFY_TOKEN) {
        return new Response(challenge ?? "", { status: 200 });
      }
      return new Response("Forbidden", { status: 403 });
    }

    const payload = await request.json();
    const parsed = parseWhatsAppPayload(payload);
    if (!parsed) return new Response("OK", { status: 200 });

    const wabaNumber = payload?.entry?.[0]?.changes?.[0]?.value?.metadata?.display_phone_number;
    const colmadosPorTelefono = await ctx.db
      .query("colmados")
      .withIndex("by_telefono_whatsapp", (q: any) => q.eq("telefono_whatsapp", wabaNumber))
      .collect();
    const colmado = colmadosPorTelefono[0];
    if (!colmado || !colmado.meta_conectado) return new Response("OK", { status: 200 });

    const COLMADO_ID = colmado._id;
    const WHATSAPP_TOKEN = colmado.whatsapp_token;
    const WHATSAPP_PHONE_ID = colmado.whatsapp_phone_id || "";

    const systemPrompt = await buildSystemPrompt(ctx, COLMADO_ID);
    const existingChats = await ctx.db
      .query("chats")
      .withIndex("by_colmado_telefono", (q: any) =>
        q.eq("colmado_id", COLMADO_ID).eq("cliente_telefono", parsed.telefono)
      )
      .collect();
    const historial = (existingChats[0]?.historial || []).slice(-20);
    if (existingChats[0] && !existingChats[0].bot_activo) return new Response("OK", { status: 200 });

    const llmResponse = await callGroq([...historial, { role: "user", content: parsed.mensaje }], systemPrompt);
    const orderData = detectOrderJSON(llmResponse);

    if (orderData?.orden) {
      const productosColmado = await ctx.db
        .query("productos")
        .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", COLMADO_ID))
        .collect();
      const productosValidos = orderData.orden.productos
        .map((p: any) => {
          const db = productosColmado.find((prod: any) =>
            prod.nombre.toLowerCase().includes(p.nombre.toLowerCase())
          );
          return db ? { productoId: db._id, nombre: p.nombre, cantidad: p.cantidad, precioUnitario: p.precio } : null;
        })
        .filter(Boolean);

      if (productosValidos.length > 0) {
        const existing = await ctx.db
          .query("clientes")
          .withIndex("by_colmado_telefono", (q: any) =>
            q.eq("colmado_id", COLMADO_ID).eq("telefono", parsed.telefono)
          )
          .collect();
        let clienteId;
        if (existing.length > 0) {
          await ctx.db.patch(existing[0]._id, { total_ordenes: existing[0].total_ordenes + 1, ultima_orden: Date.now() });
          clienteId = existing[0]._id;
        } else {
          clienteId = await ctx.db.insert("clientes", {
            colmado_id: COLMADO_ID, telefono: parsed.telefono,
            nombre: orderData.orden.nombre || "Cliente WhatsApp",
            total_ordenes: 1, ultima_orden: Date.now(), created_at: Date.now(),
          });
        }
        await ctx.db.insert("ordenes", {
          colmado_id: COLMADO_ID, cliente_id: clienteId,
          productos: productosValidos.map((p: any) => ({
            producto_id: p.productoId, nombre: p.nombre, cantidad: p.cantidad,
            precio_unitario: p.precioUnitario, subtotal: p.cantidad * p.precioUnitario,
          })),
          total: productosValidos.reduce((s: number, p: any) => s + p.cantidad * p.precioUnitario, 0),
          estado: "lista_para_imprimir",
          direccion: orderData.orden.direccion,
          metodo_pago: orderData.orden.metodo_pago,
          created_at: Date.now(),
        });
      }
    }

    await saveChatMessage(ctx, COLMADO_ID, parsed.telefono, parsed.mensaje, llmResponse);
    if (WHATSAPP_TOKEN && WHATSAPP_PHONE_ID) {
      await sendWhatsAppMessage(parsed.telefono, llmResponse, WHATSAPP_TOKEN, WHATSAPP_PHONE_ID);
    }
    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error("[WhatsApp Handler Error]", error);
    return new Response("Error", { status: 500 });
  }
});

// ============ HTTP ACTION: Embedded Signup ============

export const handleEmbeddedSignup = httpAction(async (ctx, request) => {
  try {
    const { code, colmadoId } = await request.json();
    if (!code || !colmadoId) {
      return new Response(JSON.stringify({ success: false, error: "Faltan parametros" }),
        { status: 400, headers: { "Content-Type": "application/json" } });
    }
    const result = await ctx.runAction(api.embeddedSignup.exchangeCodeForToken, { code, colmadoId });
    return new Response(JSON.stringify(result), {
      status: result.success ? 200 : 400,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: "Error interno" }),
      { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

export const handleEmbeddedSignupOptions = httpAction(async (_ctx, _request) => {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
});

export const handleMetaDeauth = httpAction(async (ctx, request) => {
  try {
    const body = await request.json();
    const wabaId = body?.signed_request || body?.waba_id;
    if (wabaId) {
      const colmados = await ctx.db
        .query("colmados")
        .withIndex("by_waba_id", (q: any) => q.eq("waba_id", wabaId))
        .collect();
      for (const colmado of colmados) {
        await ctx.db.patch(colmado._id, { meta_conectado: false });
      }
    }
    return new Response("OK", { status: 200 });
  } catch { return new Response("Error", { status: 500 }); }
});

// ============ MUTATION PARA CREAR ORDENES ============

export const crearOrdenDesdeChat = mutation({
  args: {
    colmadoId: v.id("colmados"),
    clienteTelefono: v.string(),
    clienteNombre: v.optional(v.string()),
    productos: v.array(v.object({
      productoId: v.id("productos"),
      nombre: v.string(),
      cantidad: v.number(),
      precioUnitario: v.number(),
    })),
    direccion: v.optional(v.string()),
    metodoPago: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("clientes")
      .withIndex("by_colmado_telefono", (q: any) =>
        q.eq("colmado_id", args.colmadoId).eq("telefono", args.clienteTelefono)
      )
      .collect();
    let clienteId: string;
    if (existing.length > 0) {
      await ctx.db.patch(existing[0]._id, {
        nombre: args.clienteNombre || existing[0].nombre,
        total_ordenes: existing[0].total_ordenes + 1,
        ultima_orden: Date.now(),
      });
      clienteId = existing[0]._id;
    } else {
      clienteId = await ctx.db.insert("clientes", {
        colmado_id: args.colmadoId,
        telefono: args.clienteTelefono,
        nombre: args.clienteNombre,
        total_ordenes: 1,
        ultima_orden: Date.now(),
        created_at: Date.now(),
      });
    }
    const total = args.productos.reduce((s, p) => s + p.cantidad * p.precioUnitario, 0);
    return await ctx.db.insert("ordenes", {
      colmado_id: args.colmadoId,
      cliente_id: clienteId,
      productos: args.productos.map((p) => ({
        producto_id: p.productoId,
        nombre: p.nombre,
        cantidad: p.cantidad,
        precio_unitario: p.precioUnitario,
        subtotal: p.cantidad * p.precioUnitario,
      })),
      total,
      estado: "lista_para_imprimir",
      direccion: args.direccion,
      metodo_pago: args.metodoPago,
      created_at: Date.now(),
    });
  },
});

// ============ HTTP ROUTER ============

const http = httpRouter();

// ✅ CRITICO: Registrar rutas de Convex Auth (/api/auth/signin, /api/auth/token, etc.)
auth.addHttpRoutes(http);

// WhatsApp webhook
http.route({ path: "/whatsapp", method: "POST", handler: handleWhatsApp });
http.route({ path: "/whatsapp", method: "GET", handler: handleWhatsApp });

// Embedded Signup
http.route({ path: "/embedded-signup", method: "POST", handler: handleEmbeddedSignup });
http.route({ path: "/embedded-signup", method: "OPTIONS", handler: handleEmbeddedSignupOptions });

// Meta deauth
http.route({ path: "/meta-deauth", method: "POST", handler: handleMetaDeauth });

// Telegram bot
http.route({ path: "/telegram", method: "POST", handler: handleTelegram });

export default http;
