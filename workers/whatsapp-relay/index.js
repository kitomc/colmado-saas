/**
 * ColmadoAI WhatsApp Relay Worker
 * Cloudflare Worker que:
 * 1. Verifica el challenge de Meta (GET)
 * 2. Reenvía mensajes entrantes a Convex (POST)
 * 
 * @version 1.0.0
 */

// @ts-check

/** @type {string} */
const VERIFY_TOKEN = "colmadoai_webhook_verify";

/** @type {string} URL de la HTTP Action de Convex */
const CONVEX_HTTP_URL = "https://<tu-proyecto>.convex.cloud/whatsapp";

/**
 * Maneja las requests entrantes
 * @param {Request} request
 * @returns {Promise<Response>}
 */
export default async function handler(request) {
  const url = new URL(request.url);

  // Solo aceptamos POST y GET
  if (request.method === "GET") {
    return handleVerify(request, url);
  } else if (request.method === "POST") {
    return handleMessage(request);
  }

  return new Response("Method not allowed", { status: 405 });
}

/**
 * Nano 2.1: Verificación del challenge de Meta
 * GET ?hub.mode=subscribe&hub.verify_token=xxx&hub.challenge=xxx
 */
function handleVerify(request, url) {
  const mode = url.searchParams.get("hub.mode");
  const token = url.searchParams.get("hub.verify_token");
  const challenge = url.searchParams.get("hub.challenge");

  // Verificar que sea una solicitud de verificación
  if (mode !== "subscribe") {
    return new Response("Invalid mode", { status: 403 });
  }

  // Verificar el token
  if (token !== VERIFY_TOKEN) {
    return new Response("Invalid token", { status: 403 });
  }

  // Responder con el challenge
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
async function handleMessage(request) {
  try {
    // Parsear el body
    const payload = await request.json();

    // Validar que sea un mensaje de WhatsApp (no status updates)
    if (!isValidWhatsAppMessage(payload)) {
      console.log("[WhatsApp Relay] Ignorando mensaje de status");
      return new Response("OK", { status: 200 });
    }

    // Log del mensaje recibido
    console.log("[WhatsApp Relay] Mensaje recibido:", JSON.stringify(payload, null, 2));

    // Verificar signature (opcional - para producción)
    const signature = request.headers.get("x-hub-signature-256");
    if (signature) {
      console.log("[WhatsApp Relay] Signature:", signature);
    }

    // Reenviar a Convex (fire and forget - responder inmediatamente a Meta)
    // No esperamos la respuesta de Convex para no bloquear
    fetch(CONVEX_HTTP_URL, {
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

    // Debe tener un mensaje
    if (!message) return false;

    // Solo procesamos mensajes de tipo "text"
    if (message.type !== "text") return false;

    // Debe tener texto
    if (!message.text?.body) return false;

    // Debe tener teléfono del remitente
    if (!message.from) return false;

    return true;
  } catch {
    return false;
  }
}

// Para testing local con wrangler
export const port = 8787;
export const hostname = "0.0.0.0";