# Checklist Fase 1 — Fundamentos del Backend (Convex)

> Marca cada ítem con [x] SOLO si verificaste manualmente que funciona.
> NO marques un ítem basándote en suposiciones.

---

## Nano 1.1 — Schema: tabla `colmados`
- [x] El archivo `convex/schema.ts` existe
- [x] La tabla `colmados` tiene los campos: `nombre`, `telefono_whatsapp`, `telegram_chat_id`, `whatsapp_token`, `activo`, `created_at`
- [x] Todos los campos tienen su tipo `v.` correcto
- [ ] `npx convex dev` corre sin errores de TypeScript
- [ ] La tabla aparece en el dashboard de Convex

## Nano 1.2 — Schema: tabla `productos`
- [x] La tabla `productos` tiene: `colmado_id`, `nombre`, `precio`, `disponible`, `categoria`, `imagen_url`
- [x] `colmado_id` es de tipo `v.id("colmados")`
- [x] Índice `by_colmado_id` creado sobre `colmado_id`
- [ ] `npx convex dev` sin errores

## Nano 1.3 — Schema: tabla `clientes`
- [x] La tabla `clientes` tiene: `colmado_id`, `telefono`, `nombre`, `total_ordenes`, `ultima_orden`
- [x] Índice `by_colmado_telefono` creado sobre `["colmado_id", "telefono"]`
- [x] Índice `by_colmado_id` creado sobre `colmado_id`

## Nano 1.4 — Schema: tabla `chats`
- [x] La tabla `chats` tiene: `colmado_id`, `cliente_telefono`, `historial`, `bot_activo`, `ultima_actividad`
- [x] `historial` es array de objetos `{role, content}`
- [x] Índice `by_colmado_telefono` creado

## Nano 1.5 — Schema: tabla `ordenes`
- [x] La tabla `ordenes` tiene: `colmado_id`, `cliente_id`, `productos`, `total`, `estado`, `direccion`, `metodo_pago`, `created_at`
- [x] `estado` usa `v.union(v.literal("confirmada"), v.literal("lista_para_imprimir"), v.literal("impresa"), v.literal("entregada"), v.literal("cancelada"))`
- [x] Índice `by_estado` creado
- [x] Índice `by_colmado_id` creado

## Nano 1.6 — Convex Auth
- [x] `convex/auth.ts` configurado (sistema built-in de Convex)
- [ ] `AUTH_SECRET` configurado en variables de entorno de Convex
- [x] El campo `userId` está disponible en el contexto de mutations (via `ctx.auth.getUserId()`)
- [ ] Test: crear un usuario de prueba desde el dashboard → OK

## Nano 1.7 — Query: `getProductosActivos`
- [x] Archivo `convex/productos.ts` existe
- [x] La query filtra por `colmado_id` Y `disponible == true`
- [x] Retorna array tipado de productos
- [ ] Probada desde el dashboard de Convex con un `colmado_id` real → retorna resultados

## Nano 1.8 — Mutation: `crearProducto`
- [x] Valida todos los campos con `v.`
- [ ] Verifica que el `colmado_id` sea el del usuario autenticado
- [x] Retorna el `_id` del producto creado
- [ ] Test: llamar desde dashboard → producto aparece en tabla

## Nano 1.9 — Mutation: `actualizarPrecio`
- [x] Recibe `productoId` y `precio` (número positivo)
- [x] Valida que `precio > 0`
- [ ] Verifica que el producto pertenece al colmado del usuario autenticado
- [ ] Test: llamar con precio 150 → campo actualizado en dashboard

## Nano 1.10 — Mutation: `toggleDisponibilidad`
- [x] Recibe `productoId`
- [x] Invierte el valor de `disponible` (true→false, false→true)
- [ ] Verifica ownership del colmado
- [ ] Test: llamar dos veces → estado vuelve al original

---

## ✅ Verificación Final Fase 1
- [ ] `npx convex dev` corre limpio sin errores ni warnings
- [ ] Las 5 tablas aparecen en el dashboard de Convex
- [ ] Todas las queries y mutations aparecen en el dashboard
- [ ] Se puede hacer CRUD completo de productos desde el dashboard
- [ ] **SOLO cuando todo lo anterior esté marcado → Pasar a Fase 2**
