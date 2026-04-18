# Checklist Fase 2 — Webhook y Agente LLM

> Cada nano-tarea es verificable de forma independiente.
> Usa las herramientas indicadas para probar antes de marcar.

---

## Nano 2.1 — Cloudflare Worker: verificación challenge Meta
- [x] Archivo `workers/whatsapp-relay/index.js` existe
- [x] Maneja GET con `hub.mode == "subscribe"` → responde `hub.challenge`
- [x] Maneja GET con token incorrecto → responde 403
- [ ] Test local: `wrangler dev` → curl GET con parámetros correctos → retorna challenge
- [ ] Test local: curl GET con token incorrecto → retorna 403

## Nano 2.2 — Cloudflare Worker: relay a Convex
- [x] Maneja POST → extrae el body JSON
- [x] Valida header `x-hub-signature-256` de Meta (log)
- [x] Reenvía via POST a la URL de la HTTP Action de Convex
- [x] Responde 200 a Meta inmediatamente (antes de esperar Convex)
- [ ] Test: `wrangler dev` → curl POST con payload de prueba → Convex recibe el request
- [ ] Desplegado en Cloudflare (`wrangler deploy`) → URL pública activa

## Nano 2.3 — Convex HTTP Action: parser payload WhatsApp
- [x] Archivo `convex/http.ts` existe
- [x] Parsea el payload de Meta correctamente: extrae `from`, `text.body`, `timestamp`
- [x] Ignora mensajes de status (delivered, read) — solo procesa `type == "text"`
- [x] Retorna objeto `{telefono, mensaje, timestamp}` limpio

## Nano 2.4 — Convex HTTP Action: llamada a DeepSeek V3.2
- [ ] `DEEPSEEK_API_KEY` configurada en variables de entorno de Convex
- [x] Construye el array `messages` con system prompt + historial + mensaje nuevo
- [x] Llama a `https://api.deepseek.com/v1/chat/completions` con `model: "deepseek-chat"`
- [x] Timeout manejado (usa fetch estándar con timeout implícito)
- [x] Respuesta parseada correctamente
- [ ] Test: enviar mensaje de prueba → recibir respuesta de DeepSeek en < 8s

## Nano 2.5 — Convex HTTP Action: guardar mensaje en chats
- [x] Busca el chat existente por `colmado_id + cliente_telefono`
- [x] Si no existe, crea uno nuevo con `bot_activo: true`
- [x] Agrega el mensaje del usuario Y la respuesta del LLM al historial
- [x] Actualiza `ultima_actividad` con timestamp actual

## Nano 2.6 — Convex HTTP Action: responder por WhatsApp API
- [ ] `WHATSAPP_TOKEN` y `WHATSAPP_PHONE_ID` configurados en variables de entorno
- [x] Llama a `https://graph.facebook.com/v20.0/{phone_id}/messages`
- [x] Body correcto: `{messaging_product: "whatsapp", to: telefono, type: "text", text: {body: respuesta}}`
- [x] Maneja errores de la API de Meta con logging
- [ ] Test end-to-end: mensaje real desde WhatsApp → bot responde en < 5 segundos

## Nano 2.7 — Convex Mutation: `insertarOrden`
- [x] Detecta cuando la respuesta del LLM es un JSON de orden válido
- [x] Parsea el JSON: `{productos, nombre, direccion, metodo_pago, total}`
- [ ] Crea o actualiza el cliente en tabla `clientes`
- [x] Inserta la orden con `estado: "lista_para_imprimir"`
- [x] Mutation `crearOrdenDesdeChat` disponible

## Nano 2.8 — System Prompt dinámico con catálogo
- [x] Función `buildSystemPrompt(colmadoId)` que consulta productos disponibles
- [x] El catálogo se inyecta en el prompt de forma legible para el LLM
- [x] El prompt incluye: nombre colmado, catálogo, reglas de negocio
- [x] El prompt NO supera 3000 tokens (diseño limpio)

---

## ✅ Verificación Final Fase 2
- [ ] URL del Worker está configurada como webhook en Meta Developer Portal
- [ ] El challenge de verificación fue aceptado por Meta
- [ ] Test end-to-end completo:
  - [ ] Mensaje "hola" → respuesta amigable del bot
  - [ ] Preguntar por un producto → bot da precio correcto del catálogo
  - [ ] Dar nombre + dirección + productos → bot genera orden JSON
  - [ ] Orden aparece en tabla `ordenes` con estado `lista_para_imprimir`
- [ ] **SOLO cuando todo esté marcado → Pasar a Fase 3**
