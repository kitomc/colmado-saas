# Checklist Fase 4 — App Android (FlutterFlow)

> Cada nano-tarea es verificable de forma independiente.

---

## Nano 4.1 — Conectar Convex SDK en FlutterFlow
- [ ] FlutterFlow proyecto creado (manual)
- [ ] Convex SDK agregado en Settings (manual)
- [ ] Credentials configuradas (manual)
- [x] Backend queries ya existen en convex/ordenes.ts

## Nano 4.2 — Stream Query: ordenes lista_para_imprimir
- [x] Query `getOrdenPorEstado` existe en convex/ordenes.ts
- [x] Filter por estado disponible
- [x] Ordena por created_at descendente

## Nano 4.3 — Custom Action: conectar impresora Bluetooth
- [ ] Custom Code Action (manual en FlutterFlow)
- [x] Guía documentada en docs/flutterflow-android-guide.md

## Nano 4.4 — Custom Action: construir ticket ESC/POS
- [ ] Custom Code Action (manual en FlutterFlow)
- [x] Guía documentada con comandos ESC/POS

## Nano 4.5 — Custom Action: imprimir y confirmar en Convex
- [ ] Custom Code + Mutation (manual en FlutterFlow)
- [x] Mutation `actualizarEstadoOrden` existe en convex/ordenes.ts

## Nano 4.6 — Pantalla principal con lista de órdenes
- [ ] UI en FlutterFlow (manual)
- [x] Guía documentada en docs/flutterflow-android-guide.md

---

## ✅ Verificación Final Fase 4
- [ ] App se conecta a Convex correctamente
- [ ] Lista de órdenes se actualiza en tiempo real
- [ ] Impresora se conecta por Bluetooth
- [ ] Ticket se imprime correctamente
- [ ] Estado se actualiza en Convex tras imprimir
- [ ] **SOLO cuando todo esté marcado → Pasar a Fase 5**