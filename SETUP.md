# SETUP.md — ColmadoAI SaaS
> Guía de instalación, configuración y comandos CLI para el día a día del proyecto.
> Lee este archivo ANTES de comenzar cualquier sesión de desarrollo.

---

## 📋 Prerequisitos

```bash
# Versiones requeridas
node --version   # >= 18.x
npm --version    # >= 9.x

# Instalar Wrangler CLI (Cloudflare) globalmente
npm install -g wrangler

# Verificar instalación
wrangler --version
npx convex --version
```

---

## ⚡ CONVEX CLI — Comandos esenciales

### Setup inicial (primera vez)

```bash
# 1. Instalar dependencias del proyecto
npm install

# 2. Iniciar sesión en Convex (abre el browser)
npx convex login

# 3. Inicializar proyecto Convex en este directorio
npx convex init

# 4. Instalar skill files del agente AI (importante para OpenCode)
npx convex ai-files install
```

### Desarrollo local

```bash
# Iniciar servidor Convex en modo watch (dev)
npx convex dev

# Solo verificar tipos TypeScript sin compilar
npx tsc --noEmit

# Ver los logs en tiempo real del backend Convex
npx convex logs
```

### Deploy a producción

```bash
npx convex deploy --prod
```

### Variables de entorno (Convex)

```bash
# Ver todas las variables configuradas
npx convex env list

# ── LLM ──────────────────────────────────────────────────────────
npx convex env set GROQ_API_KEY "gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# ── Meta / WhatsApp ───────────────────────────────────────────────
npx convex env set META_APP_ID "123456789012345"
npx convex env set META_APP_SECRET "tu_app_secret_aqui"
npx convex env set WHATSAPP_VERIFY_TOKEN "colmaria_verify_secreto"

# ── Convex Site URL (para el webhook) ─────────────────────────────
npx convex env set CONVEX_SITE_URL "https://tu-proyecto.convex.site"

# ── Telegram (opcional) ───────────────────────────────────────────
npx convex env set TELEGRAM_BOT_TOKEN "123456789:AAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Eliminar una variable
npx convex env remove NOMBRE_VARIABLE
```

### Utilidades Convex

```bash
npx convex schema
npx convex dashboard
npx convex run productos:getProductosActivos '{"colmadoId": "id_aqui"}'
npx convex functions
```

---

## ☁️ CLOUDFLARE WRANGLER CLI — Comandos esenciales

### Setup inicial

```bash
wrangler login
wrangler whoami
```

### Worker de WhatsApp Relay

```bash
cd workers/
wrangler dev whatsapp-relay/index.js --remote
```

### Variables secretas del Worker

```bash
wrangler secret put CONVEX_URL
wrangler secret put VERIFY_TOKEN
wrangler secret put WHATSAPP_TOKEN
wrangler secret list
```

### Deploy

```bash
wrangler deploy workers/whatsapp-relay/index.js --name=colmado-whatsapp-relay
wrangler pages deploy build/web/ --project-name=colmado-saas-admin
```

### Logs

```bash
wrangler tail colmado-whatsapp-relay
```

---

## 🤖 LLM: Groq + Llama 3.3 70B

> Modelo: `llama-3.3-70b-versatile` | Tier gratuito: 30 req/min, 500K tokens/día

```bash
# 1. Crear cuenta en https://console.groq.com
# 2. API Keys → Create API Key (empieza con gsk_)
npx convex env set GROQ_API_KEY "gsk_xxxxxxxxxxxxxxxxxx"
```

---

## 📱 Meta Embedded Signup — Onboarding de colmados

> Cada colmado conecta su propio número WhatsApp a COLMARIA con un clic.
> Sin crear cuentas de Meta for Developers. Sin configuración técnica.
> Ver guía completa: **docs/embedded-signup.md**

### Setup inicial (solo una vez, tú como COLMARIA):

```bash
# 1. Ir a developers.facebook.com → Crear app tipo "Negocios"
# 2. Agregar producto WhatsApp
# 3. Activar Embedded Signup en WhatsApp → Configuración
# 4. Configurar webhook:
#    URL: https://tu-proyecto.convex.site/whatsapp
#    Verify token: (mismo que WHATSAPP_VERIFY_TOKEN)
# 5. Configurar variables:
npx convex env set META_APP_ID "123456789"
npx convex env set META_APP_SECRET "secret"
npx convex env set CONVEX_SITE_URL "https://xxx.convex.site"
npx convex env set WHATSAPP_VERIFY_TOKEN "colmaria_verify"
```

### Onboarding de cada colmado (lo hace el dueño del colmado):

```
1. Entra al Web Admin de COLMARIA
2. Configuración → WhatsApp → "Conectar WhatsApp"
3. Autoriza con su cuenta de Facebook Business
4. ✅ Listo — su número queda conectado automáticamente
```

---

## 🔗 URLs importantes del proyecto

| Servicio | URL |
|----------|-----|
| Dashboard Convex | https://dashboard.convex.dev |
| Dashboard Cloudflare | https://dash.cloudflare.com |
| Groq Console | https://console.groq.com |
| Meta for Developers | https://developers.facebook.com/apps |
| Groq API Endpoint | https://api.groq.com/openai/v1/chat/completions |
| Meta Graph API | https://graph.facebook.com/v20.0 |
| Cloudflare Pages Admin | https://colmado-saas-admin.pages.dev |

---

## 🔑 Variables de entorno requeridas

### Convex (backend)

| Variable | Descripción | Dónde obtenerla |
|----------|-------------|-----------------|
| `GROQ_API_KEY` | API key de Groq (Llama 3.3 70B) | console.groq.com |
| `META_APP_ID` | ID de tu Meta App COLMARIA | developers.facebook.com |
| `META_APP_SECRET` | Secret de tu Meta App | developers.facebook.com → Config básica |
| `WHATSAPP_VERIFY_TOKEN` | Token de verificación webhook Meta | Lo defines tú |
| `CONVEX_SITE_URL` | URL base de Convex site | Convex Dashboard |
| `TELEGRAM_BOT_TOKEN` | Token del bot de Telegram | @BotFather |

> ⚠️ Ya NO se necesita `WHATSAPP_TOKEN` global ni `WHATSAPP_PHONE_ID` global.
> Cada colmado tiene su propio token y phone_id guardados en la tabla `colmados`.

### Cloudflare Worker (secrets)

| Variable | Descripción |
|----------|--------------|
| `CONVEX_URL` | URL de tu proyecto Convex (`https://xxx.convex.cloud`) |
| `VERIFY_TOKEN` | Mismo valor que `WHATSAPP_VERIFY_TOKEN` |

---

## 🚀 Flujo completo de instalación desde cero

```bash
# 1. Clonar el repositorio
git clone https://github.com/kitomc/colmado-saas.git
cd colmado-saas

# 2. Instalar dependencias
npm install

# 3. Configurar variables
npx convex env set GROQ_API_KEY "gsk_xxx"
npx convex env set META_APP_ID "123456789"
npx convex env set META_APP_SECRET "abc123"
npx convex env set WHATSAPP_VERIFY_TOKEN "mi_token_secreto"
npx convex env set CONVEX_SITE_URL "https://xxx.convex.site"

# 4. Iniciar Convex dev
npx convex dev

# 5. En otra terminal: Worker
cd workers/
wrangler secret put CONVEX_URL
wrangler secret put VERIFY_TOKEN
wrangler dev whatsapp-relay/index.js --remote
```

---

## ✅ Checklist antes de cada commit

```bash
npx tsc --noEmit       # 0 errores TypeScript
npx convex dev         # 0 errores en consola
git add .
git commit -m "feat/fix: descripción"
git push origin master
```

---

## 🚨 Troubleshooting frecuente

### Error: `GROQ_API_KEY no configurada`
```bash
npx convex env list
npx convex env set GROQ_API_KEY "gsk_xxx"
```

### Error: `Groq API error: 429` (rate limit)
```bash
# Tier gratuito: 30 req/min. Esperar 1 minuto o upgradar en console.groq.com
```

### Error: `META_APP_ID o META_APP_SECRET no configurados`
```bash
npx convex env set META_APP_ID "123456789"
npx convex env set META_APP_SECRET "tu_secret"
```

### Error: `Meta webhook verification failed`
```bash
# Verifica que WHATSAPP_VERIFY_TOKEN sea exactamente igual en:
# 1. Convex:              npx convex env set WHATSAPP_VERIFY_TOKEN "xxx"
# 2. Cloudflare Worker:  wrangler secret put VERIFY_TOKEN → "xxx"
# 3. Meta for Developers: campo "Verify token" del webhook
```

### Error: `Cannot find module 'convex/...'`
```bash
npm install convex@latest
npx convex ai-files install
```
