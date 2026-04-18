/**
 * ColmadoAI WhatsApp Relay Worker
 * Cloudflare Worker que:
 * 1. Verifica el challenge de Meta (GET)
 * 2. Reenvía mensajes entrantes a Convex (POST)
 * 
 * @version 2.0.0
 */

// @ts-check

/**
 * Maneja las requests entrantes - formato module Worker con env vars
 */
export default {
  async fetch(request, env, ctx) {
    const CONVEX_HTTP_URL = env.CONVEX_WHATSAPP_URL;
    const VERIFY_TOKEN = env.VERIFY_TOKEN || "colmadoai_webhook_verify";
    
    const url = new URL(request.url);

    if (request.method === "GET") {
      return handleVerify(request, url, VERIFY_TOKEN);
    } else if (request.method === "POST") {
      return handleMessage(request, CONVEX_HTTP_URL);
    }

    return new Response("Method not allowed", { status: 405 });
  }
};

/**
 * Nano 2.1: Verificación del challenge de Meta
 * GET ?hub.mode=subscribe&hub.verify_token=xxx&hub.challenge=xxx
 */
function handleVerify(request, url, verifyToken) {
  const mode = url.searchParams.get("hub.mode");
  const token = url.searchParams.get("hub.verify_token");
  const challenge = url.searchParams.get("hub.challenge");

  if (mode !== "subscribe") {
    return new Response("Invalid mode", { status: 403 });
  }

  if (token !== verifyToken) {
    return new Response("Invalid token", { status: 403 });
  }

  console.log("[WhatsApp Relay] Webhook verificado correctamente");
  return new Response(challenge, {
    status: 200,
    headers: { "Content-Type": "text/plain" },
  });
}

/**
 * Nano 2.2: Relay de mensaje a Convex
 * POST - reenvía el body a Convex y responde 200 inmediatamente
 */
async function handleMessage(request, convexUrl) {
  try {
    if (!convexUrl) {
      console.error("[WhatsApp Relay] CONVEX_HTTP_URL no configurada");
      return new Response("Convex URL not configured", { status: 500 });
    }

    // Parsear el body
    const payload = await request.json();

    // Validar que sea un mensaje de WhatsApp válido
    if (!isValidWhatsAppMessage(payload)) {
      console.log("[WhatsApp Relay] Ignorando mensaje de status o no válido");
      return new Response("OK", { status: 200 });
    }

    // Log del mensaje recibido
    console.log("[WhatsApp Relay] Mensaje recibido:", JSON.stringify(payload, null, 2));

    // Reenviar a Convex (fire and forget - responder inmediatamente a Meta)
    fetch(convexUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    }).catch((err) => {
      console.error("[WhatsApp Relay] Error reenviando a Convex:", err);
    });

    // Responder 200 a Meta inmediatamente
    return new Response("OK", { status: 200 });

  } catch (error) {
    console.error("[WhatsApp Relay] Error procesando mensaje:", error);
    return new Response("Error", { status: 500 });
  }
}

/**
 * Valida que el payload sea un mensaje de texto válido de WhatsApp
 * Ignora mensajes de status (delivered, read, etc.)
 */
function isValidWhatsAppMessage(payload) {
  try {
    const entry = payload.entry?.[0];
    const changes = entry?.changes?.[0];
    const message = changes?.value?.messages?.[0];

    if (!message) return false;
    if (message.type !== "text") return false;
    if (!message.text?.body) return false;
    if (!message.from) return false;

    return true;
  } catch {
    return false;
  }
}
