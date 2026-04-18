# Checklist Fase 3 — Telegram Bot

> Cada nano-tarea es verificable de forma independiente.

---

## Nano 3.1 — Convex Action: enviar mensaje Telegram al colmadero
- [x] `notificarTelegram` función disponible (internalAction)
- [x] Usa API `https://api.telegram.org/bot{TOKEN}/sendMessage`
- [x] Body correcto: `{chat_id, text, parse_mode}`
- [x] Maneja errores con logging

## Nano 3.2 — Convex Webhook: recibir comandos de Telegram
- [x] Archivo `convex/telegram.ts` con httpAction
- [x] Parsea payload de Telegram: `{message: {chat: {id}, text}}`
- [x] Detecta comandos: `/precio`, `/deshabilitar`, `/habilitar`, etc.

## Nano 3.3 — Handler comando `/precio`
- [x] Responde con lista de productos y precios
- [x] Formato legible (emoji + nombre + precio)
- [x] Incluye solo productos disponibles

## Nano 3.4 — Handlers `/deshabilitar` y `/habilitar`
- [x] Parsea argumento: nombre del producto
- [x] Busca producto en catálogo del colmado
- [x] Actualiza disponibilidad en tabla `productos`
- [x] Confirma con mensaje al colmadero

## Nano 3.5 — Handler botones inline (confirmar/cancelar orden)
- [x] Detecta callback queries de Telegram
- [x] Botones: "confirmar:ordenId" / "cancelar:ordenId"
- [x] Actualiza estado de orden según callback
- [x] Responde al callback query

## Nano 3.6 — Handlers `/tomar_chat` y `/liberar_chat`
- [x] `/tomar_chat` - marca bot_activo: false para que el colmadero responda manualmente
- [x] `/liberar_chat` - marca bot_activo: true para reanudar agente
- [x] Muestra lista de chats activos para seleccionar

## Nano 3.7 — Convex Cron: notificación resumen diario
- [x] Archivo `convex/telegram.ts` con `resumenDiario` internalAction
- [x] Query: órdenes del día agrupadas por estado
- [x] Envía resumen por Telegram al colmadero
- [ ] Configurable: hora de envío (default 8 PM)

---

## ✅ Verificación Final Fase 3
- [ ] Bot de Telegram responde a comandos `/precio`, `/deshabilitar`, `/habilitar`
- [ ] Botones inline funcionan para confirmar/cancelar órdenes
- [ ] `/tomar_chat` y `/liberar_chat` funcionan
- [ ] Resumen diario se envía correctamente
- [ ] **SOLO cuando todo esté marcado → Pasar a Fase 4**