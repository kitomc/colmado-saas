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
# Esto despliega en tu proyecto dev y escucha cambios en tiempo real
npx convex dev

# Solo verificar tipos TypeScript sin compilar (cero errores antes de commit)
npx tsc --noEmit

# Ver los logs en tiempo real del backend Convex
npx convex logs
```

### Deploy a producción

```bash
# Deploy de todas las funciones Convex a producción
npx convex deploy

# Deploy con confirmación explícita (recomendado)
npx convex deploy --prod
```

### Variables de entorno (Convex)

```bash
# Ver todas las variables configuradas
npx convex env list

# Configurar variables (reemplaza los valores con los reales)
npx convex env set GROQ_API_KEY "gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
npx convex env set WHATSAPP_TOKEN "EAAxxxxxxxxxxxxxxxxxxxxxxxx"
npx convex env set WHATSAPP_PHONE_ID "1234567890"
npx convex env set WHATSAPP_VERIFY_TOKEN "tu_token_secreto_de_verificacion"
npx convex env set TELEGRAM_BOT_TOKEN "123456789:AAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Eliminar una variable
npx convex env remove NOMBRE_VARIABLE
```

### Utilidades Convex

```bash
# Ver el schema actual desplegado
npx convex schema

# Abrir el Dashboard de Convex en el browser
npx convex dashboard

# Ejecutar una función manualmente (para testing)
npx convex run productos:getProductosActivos '{"colmadoId": "id_aqui"}'

# Ver todas las funciones disponibles
npx convex functions
```

---

## ☁️ CLOUDFLARE WRANGLER CLI — Comandos esenciales

### Setup inicial (primera vez)

```bash
# Iniciar sesión en Cloudflare (abre el browser)
wrangler login

# Verificar que estás autenticado
wrangler whoami
```

### Worker de WhatsApp Relay

```bash
# Entrar al directorio del Worker
cd workers/

# Desarrollo local del Worker (con hot reload)
wrangler dev whatsapp-relay/index.js

# Desarrollo con acceso público (para probar webhook de Meta)
wrangler dev whatsapp-relay/index.js --remote
```

### Variables secretas del Worker

```bash
# Configurar secrets en el Worker (no quedan en el código)
wrangler secret put CONVEX_URL
# → ingresa: https://tu-proyecto.convex.cloud

wrangler secret put VERIFY_TOKEN
# → ingresa: tu_token_secreto_de_verificacion

wrangler secret put WHATSAPP_TOKEN
# → ingresa: EAAxxxxxxxxxxxxxxxxxxxxxxxx

# Ver los secrets configurados (solo nombres, no valores)
wrangler secret list
```

### Deploy del Worker

```bash
# Deploy del Worker de WhatsApp relay
wrangler deploy workers/whatsapp-relay/index.js \
  --name=colmado-whatsapp-relay

# Deploy del Worker de Telegram relay
wrangler deploy workers/telegram-relay/index.js \
  --name=colmado-telegram-relay

# Ver Workers desplegados
wrangler deployments list
```

### Deploy del Panel Web Admin (Cloudflare Pages)

```bash
# Primero exporta desde FlutterFlow y compila:
flutter build web --release
# → Output: build/web/

# Luego despliega en Cloudflare Pages
wrangler pages deploy build/web/ \
  --project-name=colmado-saas-admin

# Ver el estado del proyecto Pages
wrangler pages project list
```

### Logs y monitoreo

```bash
# Ver logs en tiempo real del Worker en producción
wrangler tail colmado-whatsapp-relay

# Ver logs del Worker de Telegram
wrangler tail colmado-telegram-relay
```

---

## 🔗 URLs importantes del proyecto

| Servicio | URL |
|----------|-----|
| Dashboard Convex | https://dashboard.convex.dev |
| Dashboard Cloudflare | https://dash.cloudflare.com |
| Groq Console (API Keys) | https://console.groq.com |
| Groq API Endpoint | https://api.groq.com/openai/v1/chat/completions |
| Meta WhatsApp Cloud API | https://graph.facebook.com/v20.0 |
| Telegram Bot API | https://api.telegram.org/bot{TOKEN} |
| Cloudflare Pages Admin | https://colmado-saas-admin.pages.dev |

---

## 🔑 Variables de entorno requeridas

### Convex (backend)

| Variable | Descripción | Dónde obtenerla |
|----------|-------------|-----------------|
| `GROQ_API_KEY` | API key de Groq (Llama 3.3 70B) | console.groq.com → API Keys |
| `WHATSAPP_TOKEN` | Token permanente de Meta | Meta for Developers |
| `WHATSAPP_PHONE_ID` | ID del número de WhatsApp | Meta for Developers |
| `WHATSAPP_VERIFY_TOKEN` | Token de verificación webhook Meta | Lo defines tú (string aleatorio) |
| `TELEGRAM_BOT_TOKEN` | Token del bot de Telegram | @BotFather en Telegram |

### Cloudflare Worker (secrets)

| Variable | Descripción |
|----------|--------------|
| `CONVEX_URL` | URL de tu proyecto Convex (`https://xxx.convex.cloud`) |
| `VERIFY_TOKEN` | Mismo valor que `WHATSAPP_VERIFY_TOKEN` en Convex |
| `WHATSAPP_TOKEN` | Token de Meta (mismo que en Convex) |

---

## 🤖 LLM: Groq + Llama 3.3 70B

> El proyecto usa **Groq** como proveedor LLM por su velocidad (tokens/seg más rápidos del mercado).
> Modelo: `llama-3.3-70b-versatile`

```bash
# 1. Ir a https://console.groq.com
# 2. Crear cuenta gratuita
# 3. API Keys → Create API Key
# 4. Copiar la key (empieza con gsk_)
# 5. Configurar en Convex:
npx convex env set GROQ_API_KEY "gsk_xxxxxxxxxxxxxxxxxx"
```

**Tier gratuito de Groq:**
- 30 req/min en llama-3.3-70b-versatile
- 500K tokens/día
- Suficiente para desarrollo y testing

---

## 🚀 Flujo completo de instalación desde cero

```bash
# 1. Clonar el repositorio
git clone https://github.com/kitomc/colmado-saas.git
cd colmado-saas

# 2. Instalar dependencias
npm install

# 3. Configurar variables de entorno de Convex
npx convex env set GROQ_API_KEY "gsk_xxx"
npx convex env set WHATSAPP_TOKEN "EAAxxx"
npx convex env set WHATSAPP_PHONE_ID "123456"
npx convex env set WHATSAPP_VERIFY_TOKEN "mi_token_secreto"
npx convex env set TELEGRAM_BOT_TOKEN "123:AAAxxx"

# 4. Iniciar Convex en modo dev
npx convex dev

# 5. En otra terminal: iniciar el Worker de WhatsApp
cd workers/
wrangler secret put CONVEX_URL   # pega tu URL de Convex
wrangler secret put VERIFY_TOKEN # mismo que WHATSAPP_VERIFY_TOKEN
wrangler dev whatsapp-relay/index.js --remote
```

---

## ✅ Checklist antes de cada commit

```bash
# 1. Verificar tipos TypeScript (0 errores)
npx tsc --noEmit

# 2. Verificar que Convex compila sin errores
npx convex dev  # observa la consola, no debe haber errores en rojo

# 3. Marcar el ítem en el checklist correspondiente
# → checklists/fase[N].md

# 4. Commit con mensaje descriptivo
git add .
git commit -m "feat/fix: [descripción breve de lo implementado]"
git push origin master
```

---

## 🚨 Troubleshooting frecuente

### Error: `GROQ_API_KEY no configurada`
```bash
# Verifica que la variable esté seteada
npx convex env list
# Si no aparece, configura:
npx convex env set GROQ_API_KEY "gsk_xxx"
```

### Error: `Groq API error: 429`
```bash
# Rate limit alcanzado (30 req/min en tier gratuito)
# Soluciones:
# 1. Esperar 1 minuto
# 2. Reducir la frecuencia de mensajes en testing
# 3. Upgradar a tier pago en console.groq.com
```

### Error: `Cannot find module 'convex/...'`
```bash
npm install convex@latest
npx convex ai-files install
```

### Error: `Wrangler: No config file found`
```bash
# Especifica el archivo JS directamente:
wrangler deploy workers/whatsapp-relay/index.js --name=colmado-whatsapp-relay
```

### Error: `Meta webhook verification failed`
```bash
# Verifica que WHATSAPP_VERIFY_TOKEN sea exactamente igual en:
# 1. Convex:              npx convex env set WHATSAPP_VERIFY_TOKEN "xxx"
# 2. Cloudflare Worker:  wrangler secret put VERIFY_TOKEN → "xxx"
# 3. Meta for Developers: campo "Verify token" del webhook
```
