/**
 * ColmadoAI WhatsApp Relay Worker
 * Cloudflare Worker que:
 * 1. Verifica el challenge de Meta (GET)
 * 2. Reenvía mensajes entrantes a Convex (POST)
 * 
 * @version 1.1.0
 */

// @ts-check

const VERIFY_TOKEN = "colmadoai_webhook_verify";

// ⚠️ REEMPLAZAR ESTA URL con la de tu deployment de Convex después de ejecutar `npx convex dev`
// Ejemplo: https://happy-frog-123.convex.cloud/whatsapp
const CONVEX_HTTP_URL = "https://TU_PROYECTO.convex.cloud/whatsapp";

/**
 * Maneja las requests entrantes
 */
async function handler(request) {
  const url = new URL(request.url);

  if (request.method === "GET") {
    return handleVerify(request, url);
  } else if (request.method === "POST") {
    return handleMessage(request);
  }

  return new Response("Method not allowed", { status: 405 });
}

// Exportar como fetch handler para Cloudflare Workers
export { handler as default };

// Alternativamente, para algunos casos
export async function fetch(request, env, ctx) {
  return handler(request);
}