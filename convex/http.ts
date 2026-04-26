import { httpAction } from "./_generated/server";
import { internalAction } from "./_generated/server";
import { query } from "./_generated/server";
import { mutation } from "./_generated/server";
import { v } from "convex/values";
import { httpRouter } from "convex/server";
import { handleTelegram } from "./telegram";

// @ts-check

/**
 * Nano 2.3: Parser del payload de WhatsApp
 * Extrae: from, text.body, timestamp
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

/**
 * Parsea el payload de Meta y retorna un objeto limpio
 */
function parseWhatsAppPayload(payload: any): ParsedMessage | null {
  try {
    const entry = payload.entry?.[0];
    const changes = entry?.changes?.[0];
    const message: WhatsAppMessage = changes?.value?.messages?.[0];

    if (!message || message.type !== "text" || !message.text?.body) {
      return null;
    }

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

/**
 * Nano 2.4: Llamada a Groq API
 */
async function callGroq(
  messages: { role: string; content: string }[],
  systemPrompt: string
): Promise<string> {
  const apiKey = process.env.GROQ_API_KEY;
  
  if (!apiKey) {
    throw new Error("GROQ_API_KEY no configurada");
  }

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [
        { role: "system", content: systemPrompt },
        ...messages,
      ],
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

/**
 * Nano 2.5: Guardar mensaje en tabla chats
 */
async function saveChatMessage(
  ctx: any,
  colmadoId: string,
  telefono: string,
  userMessage: string,
  botResponse: string
) {
  // Buscar chat existente
  const existingChats = await ctx.db
    .query("chats")
    .withIndex("by_colmado_telefono", (q: any) =>
      q.eq("colmado_id", colmadoId).eq("cliente_telefono", telefono)
    )
    .collect();

  const now = Date.now();

  if (existingChats.length > 0) {
    // Actualizar chat existente
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
    // Crear nuevo chat
    const chatId = await ctx.db.insert("chats", {
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
    return chatId;
  }
}

/**
 * Nano 2.6: Responder por WhatsApp API
 */
async function sendWhatsAppMessage(
  phoneNumber: string,
  message: string,
  token: string,
  phoneId: string
): Promise<void> {
  const response = await fetch(
    `https://graph.facebook.com/v20.0/${phoneId}/messages`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: phoneNumber,
        type: "text",
        text: { body: message },
      }),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    console.error("[WhatsApp Send Error]", error);
    throw new Error(`WhatsApp API error: ${response.status}`);
  }
}

/**
 * Nano 2.7: Detectar y procesar JSON de orden
 */
interface OrderJSON {
  orden?: {
    productos: Array<{
      nombre: string;
      cantidad: number;
      precio: number;
    }>;
    nombre?: string;
    direccion?: string;
    metodo_pago?: string;
  };
}

function detectOrderJSON(response: string): OrderJSON | null {
  try {
    // Buscar JSON en la respuesta (puede estar envuelto en texto)
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return null;

    const parsed = JSON.parse(jsonMatch[0]);
    
    // Validar que sea una orden
    if (parsed.orden && Array.isArray(parsed.orden.productos)) {
      return parsed;
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Nano 2.8: Construir system prompt dinámico con catálogo
 */
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
Eres el asistente de ventas de ${colmado?.nombre || "uncolmado"}.

CATÁLOGO DE PRODUCTOS:
${catalogo || "No hay productos disponibles"}

INSTRUCCIONES:
1. Saludar amablemente y preguntar qué necesita el cliente
2. Cuando el cliente pida productos, ofrecer el catálogo disponible
3. Cuando el cliente confirme una orden, pedir: nombre, dirección y método de pago
4. Cuando tengas toda la información, generar un JSON con la estructura:
{"orden": {"productos": [{"nombre": "...", "cantidad": N, "precio": N}], "nombre": "...", "direccion": "...", "metodo_pago": "..."}}
5. Solo generar JSON cuando el cliente confirme todos los datos de la orden
6. Responder en español, de forma amable y concisa
`.trim();
}

// ============ HTTP ACTION PRINCIPAL ============

/**
 * HTTP Action que recibe el webhook de WhatsApp
 * Orchestrates: parse -> deepseek -> save -> respond
 */
export const handleWhatsApp = httpAction(async (ctx, request) => {
  try {
    // Tarea 2: Manejar GET de verificación de Meta
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

    // Nano 2.3: Parsear payload
    const payload = await request.json();
    const parsed = parseWhatsAppPayload(payload);

    if (!parsed) {
      console.log("[WhatsApp] Mensaje ignorado (no es texto)");
      return new Response("OK", { status: 200 });
    }

    console.log("[WhatsApp] Mensaje parseado:", parsed);

    // Problema #2: Buscar el colmado por el número de WhatsApp del payload
    const wabaNumber = payload?.entry?.[0]?.changes?.[0]?.value?.metadata?.display_phone_number;
    const todosColmados = await ctx.db.query("colmados").collect();
    const colmado = todosColmados.find((c: any) => c.telefono_whatsapp === wabaNumber);

    if (!colmado) {
      console.log("[WhatsApp] No se encontró colmado para", wabaNumber);
      return new Response("OK", { status: 200 });
    }

    const COLMADO_ID = colmado._id;
    const WHATSAPP_TOKEN = colmado.whatsapp_token;

    console.log("[WhatsApp] Colmado encontrado:", colmado.nombre);

    // Nano 2.8: Obtener system prompt con catálogo
    const systemPrompt = await buildSystemPrompt(ctx, COLMADO_ID);

    // Obtener historial del chat para contexto
    const existingChats = await ctx.db
      .query("chats")
      .withIndex("by_colmado_telefono", (q: any) =>
        q.eq("colmado_id", COLMADO_ID).eq("cliente_telefono", parsed.telefono)
      )
      .collect();

    const historialCompleto = existingChats[0]?.historial || [];
    const historial = historialCompleto.slice(-20); // Limitar a últimos 20 mensajes

    // #9 Verificar si el bot está activo para este chat
    const chatActual = existingChats[0];
    if (chatActual && !chatActual.bot_activo) {
      console.log("[WhatsApp] Bot pausado para este chat, ignorando mensaje");
      return new Response("OK", { status: 200 });
    }

    // Problema #1: Incluir el mensaje nuevo del cliente en el historial
    const mensajesConNuevo = [
      ...historial,
      { role: "user", content: parsed.mensaje }
    ];

    // Nano 2.4: Llamar a Groq
    const llmResponse = await callGroq(mensajesConNuevo, systemPrompt);

    console.log("[Groq] Respuesta:", llmResponse);

    // Problema #4: Detectar Y guardar la orden si se detecta
    const orderData = detectOrderJSON(llmResponse);

    if (orderData && orderData.orden) {
      console.log("[Orden] Detectada:", orderData);

      // Buscar o crear productos en el catálogo
      const productosColmado = await ctx.db
        .query("productos")
        .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", COLMADO_ID))
        .collect();

      const productosOrden = orderData.orden.productos.map((p: any) => {
        const productoDb = productosColmado.find((prod: any) =>
          prod.nombre.toLowerCase().includes(p.nombre.toLowerCase())
        );
        return {
          productoId: productoDb?._id || null,
          nombre: p.nombre,
          cantidad: p.cantidad,
          precioUnitario: p.precio,
        };
      });

      // Filtrar productos que no se encontraron
      const productosValidos = productosOrden.filter((p: any) => p.productoId);

      if (productosValidos.length > 0) {
        // Bug #A: Crear o buscar el cliente primero
        const clientesExistentes = await ctx.db
          .query("clientes")
          .withIndex("by_colmado_telefono", (q: any) =>
            q.eq("colmado_id", COLMADO_ID).eq("telefono", parsed.telefono)
          )
          .collect();

        let clienteId;
        if (clientesExistentes.length > 0) {
          const cliente = clientesExistentes[0];
          await ctx.db.patch(cliente._id, {
            total_ordenes: cliente.total_ordenes + 1,
            ultima_orden: Date.now(),
          });
          clienteId = cliente._id;
        } else {
          clienteId = await ctx.db.insert("clientes", {
            colmado_id: COLMADO_ID,
            telefono: parsed.telefono,
            nombre: orderData.orden.nombre || "Cliente WhatsApp",
            total_ordenes: 1,
            ultima_orden: Date.now(),
            created_at: Date.now(),
          });
        }

        // Insertar la orden con cliente_id válido
        const ordenId = await ctx.db.insert("ordenes", {
          colmado_id: COLMADO_ID,
          cliente_id: clienteId,
          productos: productosValidos.map((p: any) => ({
            producto_id: p.productoId,
            nombre: p.nombre,
            cantidad: p.cantidad,
            precio_unitario: p.precioUnitario,
            subtotal: p.cantidad * p.precioUnitario,
          })),
          total: productosValidos.reduce((sum: number, p: any) =>
            sum + (p.cantidad * p.precioUnitario), 0
          ),
          estado: "lista_para_imprimir",
          direccion: orderData.orden.direccion,
          metodo_pago: orderData.orden.metodo_pago,
          created_at: Date.now(),
        });

        console.log("[Orden] Creada con ID:", ordenId);
      }
    }

    // Nano 2.5: Guardar en chats
    await saveChatMessage(
      ctx,
      COLMADO_ID,
      parsed.telefono,
      parsed.mensaje,
      llmResponse
    );

    // Bug #B: Usar el whatsapp_phone_id del colmado encontrado
    const WHATSAPP_PHONE_ID = colmado.whatsapp_phone_id || "";

    if (WHATSAPP_TOKEN && WHATSAPP_PHONE_ID) {
      await sendWhatsAppMessage(
        parsed.telefono,
        llmResponse,
        WHATSAPP_TOKEN,
        WHATSAPP_PHONE_ID
      );
    }

    return new Response("OK", { status: 200 });

  } catch (error) {
    console.error("[WhatsApp Handler Error]", error);
    return new Response("Error", { status: 500 });
  }
});

// ============ MUTATION PARA CREAR ÓRDENES ============

/**
 * Mutation: crearOrdenDesdeChat
 * Crea una orden cuando el LLM detecta que es una orden
 */
export const crearOrdenDesdeChat = mutation({
  args: {
    colmadoId: v.id("colmados"),
    clienteTelefono: v.string(),
    clienteNombre: v.optional(v.string()),
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
    // Buscar o crear cliente
    const clientesExistentes = await ctx.db
      .query("clientes")
      .withIndex("by_colmado_telefono", (q: any) =>
        q.eq("colmado_id", args.colmadoId).eq("telefono", args.clienteTelefono)
      )
      .collect();

    let clienteId: string;
    
    if (clientesExistentes.length > 0) {
      const cliente = clientesExistentes[0];
      await ctx.db.patch(cliente._id, {
        nombre: args.clienteNombre || cliente.nombre,
        total_ordenes: cliente.total_ordenes + 1,
        ultima_orden: Date.now(),
      });
      clienteId = cliente._id;
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

    // Calcular total
    const total = args.productos.reduce((sum, p) => {
      return sum + p.cantidad * p.precioUnitario;
    }, 0);

    // Crear orden
    const ordenId = await ctx.db.insert("ordenes", {
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

    return ordenId;
  },
});

// ============ HTTP ROUTER ============

const http = httpRouter();

http.route({
  path: "/whatsapp",
  method: "POST",
  handler: handleWhatsApp,
});

http.route({
  path: "/whatsapp",
  method: "GET",
  handler: handleWhatsApp,
});

http.route({
  path: "/telegram",
  method: "POST",
  handler: handleTelegram,
});

export default http;