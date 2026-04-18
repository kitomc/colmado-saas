import { httpAction } from "./_generated/server";
import { internalAction } from "./_generated/server";
import { mutation } from "./_generated/server";
import { query } from "./_generated/server";
import { v } from "convex/values";
import { internal } from "./_generated/server";

// @ts-check

// ============ NANO 3.1: ACTION ENVIAR MENSAJE TELEGRAM ============

/**
 * Envía un mensaje por Telegram al colmadero
 * @param {string} chatId - Chat ID del colmadero
 * @param {string} mensaje - Mensaje a enviar
 * @param {string} token - Bot Token de Telegram
 */
async function sendTelegramMessage(
  chatId: string,
  mensaje: string,
  token: string
): Promise<void> {
  const response = await fetch(
    `https://api.telegram.org/bot${token}/sendMessage`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        chat_id: chatId,
        text: mensaje,
        parse_mode: "HTML",
      }),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    console.error("[Telegram Send Error]", error);
    throw new Error(`Telegram API error: ${response.status}`);
  }
}

/**
 * Action interno para enviar mensaje de Telegram
 */
export const notificarTelegram = internalAction({
  args: {
    colmadoId: v.id("colmados"),
    mensaje: v.string(),
    tipo: v.optional(v.union(v.literal("orden_nueva"), v.literal("alerta"), v.literal("resumen"))),
  },
  handler: async (ctx, args) => {
    // Obtener el colmado para getting el chat_id de Telegram
    const colmado = await ctx.db.get(args.colmadoId);
    
    if (!colmado?.telegram_chat_id) {
      console.log("[Telegram] No hay telegram_chat_id configurado para este colmado");
      return { success: false, reason: "no_telegram_id" };
    }

    const token = process.env.TELEGRAM_BOT_TOKEN;
    if (!token) {
      console.log("[Telegram] TELEGRAM_BOT_TOKEN no configurado");
      return { success: false, reason: "no_token" };
    }

    // Agregar emoji según tipo
    let mensajeConEmoji = args.mensaje;
    if (args.tipo === "orden_nueva") {
      mensajeConEmoji = "🛒 <b>NUEVA ORDEN</b>\n\n" + args.mensaje;
    } else if (args.tipo === "alerta") {
      mensajeConEmoji = "⚠️ <b>ALERTA</b>\n\n" + args.mensaje;
    } else if (args.tipo === "resumen") {
      mensajeConEmoji = "📊 <b>RESUMEN DIARIO</b>\n\n" + args.mensaje;
    }

    await sendTelegramMessage(colmado.telegram_chat_id, mensajeConEmoji, token);
    return { success: true };
  },
});

// ============ NANO 3.2: WEBHOOK RECIBIR COMANDOS ============

/**
 * Parsea el payload de Telegram
 */
function parseTelegramPayload(payload: any): {
  chatId: string;
  texto: string;
  callbackQuery?: { data: string; messageId: string };
} | null {
  try {
    // Callback query (botones inline)
    if (payload.callback_query) {
      const callback = payload.callback_query;
      return {
        chatId: callback.message?.chat?.id?.toString() || "",
        texto: "",
        callbackQuery: {
          data: callback.data,
          messageId: callback.message?.message_id?.toString() || "",
        },
      };
    }

    // Mensaje normal
    const message = payload.message;
    if (!message?.chat?.id || !message?.text) {
      return null;
    }

    return {
      chatId: message.chat.id.toString(),
      texto: message.text,
    };
  } catch (error) {
    console.error("[Telegram Parse Error]", error);
    return null;
  }
}

/**
 * Detecta comandos en el texto
 */
function detectCommand(text: string): { comando: string; args: string } | null {
  const match = text.match(/^\/(\w+)(?:\s+(.*))?$/);
  if (!match) return null;
  
  return {
    comando: match[1].toLowerCase(),
    args: match[2]?.trim() || "",
  };
}

// ============ HANDLERS DE COMANDOS ============

/**
 * Busca el colmado por telegram_chat_id
 */
async function findColmadoByTelegramChatId(ctx: any, chatId: string) {
  const colmados = await ctx.db.query("colmados").collect();
  return colmados.find((c: any) => c.telegram_chat_id === chatId);
}

/**
 * Nano 3.3: Handler comando /precio
 */
async function handlePrecio(
  ctx: any,
  chatId: string,
  token: string
): Promise<string> {
  // Problema #3: Buscar el colmado por telegram_chat_id
  const colmado = await findColmadoByTelegramChatId(ctx, chatId);

  if (!colmado) {
    return "No hay colmados configurados para este chat.";
  }

  // Obtener productos disponibles
  const productos = await ctx.db
    .query("productos")
    .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", colmado._id))
    .filter((q: any) => q.eq("disponible", true))
    .collect();

  if (productos.length === 0) {
    return "No hay productos disponibles en el catálogo.";
  }

  // Formatear lista de precios
  const lista = productos
    .map((p: any) => `• ${p.nombre}: RD$${p.precio}`)
    .join("\n");

  return `📋 <b>Catálogo de ${colmado.nombre}</b>\n\n${lista}`;
}

/**
 * Nano 3.4: Handlers /deshabilitar y /habilitar
 */
async function handleToggleProducto(
  ctx: any,
  chatId: string,
  token: string,
  nombreProducto: string,
  habilitar: boolean
): Promise<string> {
  // Problema #3: Buscar el colmado por telegram_chat_id
  const colmado = await findColmadoByTelegramChatId(ctx, chatId);

  if (!colmado) {
    return "No hay colmados configurados para este chat.";
  }

  // Buscar producto por nombre (case insensitive)
  const productos = await ctx.db
    .query("productos")
    .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", colmado._id))
    .collect();

  const producto = productos.find(
    (p: any) => p.nombre.toLowerCase().includes(nombreProducto.toLowerCase())
  );

  if (!producto) {
    return `❌ Producto "${nombreProducto}" no encontrado en el catálogo.`;
  }

  // Actualizar disponibilidad
  await ctx.db.patch(producto._id, {
    disponible: habilitar,
  });

  const estado = habilitar ? "habilitado" : "deshabilitado";
  return `✅ Producto "${producto.nombre}" ${estado}.`;
}

/**
 * Nano 3.6: Handlers /tomar_chat y /liberar_chat
 */
async function handleChatControl(
  ctx: any,
  chatId: string,
  token: string,
  accion: "tomar" | "liberar",
  telefonoCliente?: string
): Promise<string> {
  // Problema #3: Buscar el colmado por telegram_chat_id
  const colmado = await findColmadoByTelegramChatId(ctx, chatId);

  if (!colmado) {
    return "No hay colmados configurados para este chat.";
  }

  if (accion === "liberar") {
    // Reanudar bot - obtener todos los chats del colmado
    const todosLosChats = await ctx.db
      .query("chats")
      .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", colmado._id))
      .collect();

    // Actualizar todos los chats para reanudar el bot
    for (const chat of todosLosChats) {
      await ctx.db.patch(chat._id, { bot_activo: true });
    }

    return "✅ Bot reanudado para todos los chats.";
  }

  // Si es "tomar" y se especifica teléfono
  if (telefonoCliente) {
    const chats = await ctx.db
      .query("chats")
      .withIndex("by_colmado_telefono", (q: any) =>
        q.eq("colmado_id", colmado._id).eq("cliente_telefono", telefonoCliente)
      )
      .collect();

    if (chats.length > 0) {
      await ctx.db.patch(chats[0]._id, { bot_activo: false });
      return `✅ Chat con ${telefonoCliente} tomado. Ahora podés responder manualmente.`;
    }
    return `❌ No hay chat activo con ${telefonoCliente}.`;
  }

  // Listar chats activos
  const chats = await ctx.db
    .query("chats")
    .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", colmado._id))
    .filter((q: any) => q.eq("bot_activo", true))
    .collect();

  if (chats.length === 0) {
    return "No hay chats activos con el bot.";
  }

  const lista = chats
    .map((c: any, i: number) => `${i + 1}. ${c.cliente_telefono} (${new Date(c.ultima_actividad).toLocaleString()})`)
    .join("\n");

  return `📱 <b>Chats activos</b>\n\n${lista}\n\nPara tomar un chat específico, usá: /tomar_chat [teléfono]`;
}

/**
 * Nano 3.5: Handler botones inline (confirmar/cancelar orden)
 */
async function handleCallbackQuery(
  ctx: any,
  callbackData: string,
  chatId: string,
  token: string
): Promise<string> {
  const [action, ordenId] = callbackData.split(":");

  if (action === "confirmar") {
    await ctx.db.patch(ordenId, { estado: "lista_para_imprimir" });
    return "Orden confirmada ✅";
  } else if (action === "cancelar") {
    await ctx.db.patch(ordenId, { estado: "cancelada" });
    return "Orden cancelada ❌";
  }

  return "Acción desconocida.";
}

// ============ HTTP ACTION PRINCIPAL ============

/**
 * Webhook de Telegram - recibe comandos del colmadero
 */
export const handleTelegram = httpAction(async (ctx, request) => {
  try {
    const payload = await request.json();
    const parsed = parseTelegramPayload(payload);

    if (!parsed) {
      return new Response("OK", { status: 200 });
    }

    const token = process.env.TELEGRAM_BOT_TOKEN;
    if (!token) {
      console.error("[Telegram] TELEGRAM_BOT_TOKEN no configurado");
      return new Response("OK", { status: 200 });
    }

    // Manejar callback query (botones inline)
    if (parsed.callbackQuery) {
      const respuesta = await handleCallbackQuery(
        ctx,
        parsed.callbackQuery.data,
        parsed.chatId,
        token
      );

      // Responder al callback
      await fetch(`https://api.telegram.org/bot${token}/answerCallbackQuery`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          callback_query_id: payload.callback_query.id,
          text: respuesta,
        }),
      });

      return new Response("OK", { status: 200 });
    }

    // Detectar comando
    const command = detectCommand(parsed.texto);

    let respuesta = "";

    if (!command) {
      // Mensaje normal - ignorar o responder con ayuda
      respuesta = "ℹ️ Usá /precio para ver el catálogo, /ayuda para ver todos los comandos.";
    } else {
      switch (command.comando) {
        case "precio":
          respuesta = await handlePrecio(ctx, parsed.chatId, token);
          break;

        case "deshabilitar":
          respuesta = await handleToggleProducto(
            ctx,
            parsed.chatId,
            token,
            command.args,
            false
          );
          break;

        case "habilitar":
          respuesta = await handleToggleProducto(
            ctx,
            parsed.chatId,
            token,
            command.args,
            true
          );
          break;

        case "tomar_chat":
          respuesta = await handleChatControl(
            ctx,
            parsed.chatId,
            token,
            "tomar",
            command.args || undefined
          );
          break;

        case "liberar_chat":
          respuesta = await handleChatControl(
            ctx,
            parsed.chatId,
            token,
            "liberar"
          );
          break;

        case "ayuda":
          respuesta = `
📋 <b>Comandos disponibles</b>

/precio - Ver catálogo de productos
/habilitar [producto] - Habilitar producto
/deshabilitar [producto] - Deshabilitar producto
/tomar_chat [teléfono] - Tomar control de un chat
/liberar_chat - Reanudar bot en todos los chats
/ayuda - Mostrar esta ayuda
          `.trim();
          break;

        default:
          respuesta = `Comando desconocido: /${command.comando}. Usá /ayuda para ver comandos disponibles.`;
      }
    }

    // Enviar respuesta
    await sendTelegramMessage(parsed.chatId, respuesta, token);

    return new Response("OK", { status: 200 });

  } catch (error) {
    console.error("[Telegram Handler Error]", error);
    return new Response("Error", { status: 500 });
  }
});

// ============ NANO 3.7: CRON RESUMEN DIARIO ============

/**
 * Scheduled function para enviar resumen diario
 */
export const resumenDiario = internalAction({
  handler: async (ctx) => {
    const token = process.env.TELEGRAM_BOT_TOKEN;
    if (!token) {
      console.log("[Cron] TELEGRAM_BOT_TOKEN no configurado");
      return;
    }

    // Obtener todos los colmados
    const colmados = await ctx.db.query("colmados").collect();

    for (const colmado of colmados) {
      if (!colmado.telegram_chat_id) continue;

      const ahora = Date.now();
      const inicioDia = new Date().setHours(0, 0, 0, 0);

      // Órdenes de hoy
      const ordenesHoy = await ctx.db
        .query("ordenes")
        .withIndex("by_colmado_id", (q: any) => q.eq("colmado_id", colmado._id))
        .filter((q: any) => q.gte("created_at", inicioDia))
        .collect();

      // Agrupar por estado
      const porEstado = {
        confirmada: ordenesHoy.filter((o: any) => o.estado === "confirmada").length,
        lista_para_imprimir: ordenesHoy.filter((o: any) => o.estado === "lista_para_imprimir").length,
        impresa: ordenesHoy.filter((o: any) => o.estado === "impresa").length,
        entrega: ordenesHoy.filter((o: any) => o.estado === "entregada").length,
        cancelada: ordenesHoy.filter((o: any) => o.estado === "cancelada").length,
      };

      const ingresos = ordenesHoy
        .filter((o: any) => o.estado !== "cancelada")
        .reduce((sum: number, o: any) => sum + o.total, 0);

      const resumen = `
📊 <b>Resumen del día</b>

🛒 <b>Total órdenes:</b> ${ordenesHoy.length}
💰 <b>Ingresos:</b> RD$${ingresos.toFixed(2)}

📍 Confirmadas: ${porEstado.confirmada}
🖨️ Lista para imprimir: ${porEstado.lista_para_imprimir}
✅ Impresas: ${porEstado.impresa}
🚚 Entregadas: ${porEstado.entrega}
❌ Canceladas: ${porEstado.cancelada}
      `.trim();

      await sendTelegramMessage(colmado.telegram_chat_id, resumen, token);
    }

    return { success: true };
  },
});