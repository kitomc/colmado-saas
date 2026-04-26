# Deploy de Convex - Configuración Manual

## El problema

El CLI de Convex requiere un proyecto creado en el dashboard y configuración interactiva que no funciona en terminals no-interactivas.

## Solución - Pasos a seguir:

### 1. Crear proyecto en Convex Dashboard

1. Ve a: https://dashboard.convex.dev
2. Inicia sesión
3. Click **"New Project"**
4. Nombre: `colmado-saas`
5. Copia el **Deployment URL** (algo como `https://happy-frog-123.convex.cloud`)

### 2. Configurar variables de entorno

Después de crear el proyecto, ejecuta:

```bash
# REEMPLAZA con tu deployment URL real
export CONVEX_DEPLOYMENT="https://tu-proyecto.convex.cloud"

# Configurar secrets (reemplaza con tus keys reales)
npx convex env set GROQ_API_KEY TU_GROQ_KEY
npx convex env set TELEGRAM_BOT_TOKEN TU_TELEGRAM_TOKEN
npx convex env set WHATSAPP_VERIFY_TOKEN colmadoai_webhook_verify
```

### 3. Deploy

```bash
npx convex deploy
```

---

## Mientras tanto, el Worker ya está desplegado:

**URL:** https://colmadoai-whatsapp-relay.kitomc-rd.workers.dev

Cuando tengas el deployment URL de Convex, actualizá:
- `workers/whatsapp-relay/index.js` (línea con CONVEX_HTTP_URL)
- Luego: `cd workers/whatsapp-relay && wrangler deploy`