# Embedded Signup de Meta — COLMARIA SaaS
> Guía técnica para que cada colmado conecte su propio número de WhatsApp
> a COLMARIA sin crear una cuenta de Meta for Developers.

---

## ¿Qué es Embedded Signup?

Es el flujo oficial de Meta que permite a plataformas SaaS (como COLMARIA)
actar como **Tech Provider**: un solo Meta App que gestiona múltiples
WhatsApp Business Accounts (WABAs), una por cada cliente/colmado.

```
Meta App COLMARIA (una sola, tuya)
         │
   ┌─────┼─────────────────────┐
   │     │                     │
WABA_A   WABA_B            WABA_C
Colmado  Colmado           Colmado
Don Pepe La Esquina        El Buen Sabor
+1809... +1809...          +1829...
```

---

## Paso 1 — Setup inicial en Meta (solo una vez)

### 1.1 Crear la Meta App de COLMARIA

1. Ir a [developers.facebook.com/apps](https://developers.facebook.com/apps)
2. Clic en **Crear app** → Tipo: **Negocios**
3. Nombre: `COLMARIA SaaS`
4. Agregar cuenta de Business Manager
5. Clic en **Crear app**

### 1.2 Agregar el producto WhatsApp

1. En el dashboard de la app → **Agregar productos** → **WhatsApp**
2. Ir a **WhatsApp → Configuración**
3. Copiar el **App ID** y el **App Secret** → guardar en Convex:

```bash
npx convex env set META_APP_ID "123456789012345"
npx convex env set META_APP_SECRET "tu_app_secret_aqui"
npx convex env set CONVEX_SITE_URL "https://tu-proyecto.convex.site"
```

### 1.3 Activar Embedded Signup

1. Ir a **WhatsApp → Configuración → Embedded Signup**
2. Activar: **Enable Embedded Signup**
3. En **Valid OAuth redirect URIs** agregar:
   ```
   https://colmado-saas-admin.pages.dev/whatsapp-callback
   https://localhost:3000/whatsapp-callback  ← para desarrollo
   ```
4. En **Deauthorize callback URL**:
   ```
   https://tu-proyecto.convex.site/meta-deauth
   ```

### 1.4 Crear System User Token permanente

El token que obtiene el usuario durante el signup dura 60 días.
Para producción debes convertirlo a un token permanente de System User:

1. Ir a **Business Manager → Configuración → System Users**
2. Crear un System User: `COLMARIA Bot`
3. Asignar rol: **Administrador**
4. Generar token con permisos:
   - `whatsapp_business_messaging`
   - `whatsapp_business_management`
5. Guardar el token → este es el que se usa en producción

---

## Paso 2 — Configurar el Webhook global

Meta requiere configurar un webhook en tu app. Este webhook único recibe
los mensajes de **todos** los colmados conectados.

### 2.1 En Meta for Developers:

1. Ir a **WhatsApp → Configuración → Webhook**
2. **URL de callback**:
   ```
   https://tu-proyecto.convex.site/whatsapp
   ```
3. **Verify token**: (cualquier string secreto que tú elijas)
   ```bash
   npx convex env set WHATSAPP_VERIFY_TOKEN "colmaria_verify_2024"
   ```
4. Clic en **Verificar y guardar**
5. Suscribir campo: **messages** ✅

---

## Paso 3 — Botón de Embedded Signup en el Web Admin

Este es el código HTML/JS que va en la pantalla de **Configuración → WhatsApp**
del Web Admin (FlutterFlow usará un WebView o WebviewWidget para esto).

### Código del botón (HTML + JS):

```html
<!-- Cargar SDK de Facebook -->
<script>
  window.fbAsyncInit = function() {
    FB.init({
      appId: 'TU_META_APP_ID',   // ← reemplazar con META_APP_ID real
      autoLogAppEvents: true,
      xfbml: true,
      version: 'v20.0'
    });
  };
</script>
<script async defer src="https://connect.facebook.net/es_ES/sdk.js"></script>

<!-- Botón oficial de Meta -->
<button
  onclick="launchWhatsAppSignup()"
  style="background-color:#1877f2; border:0; border-radius:4px; color:#fff;
         cursor:pointer; font-size:16px; padding:12px 24px;">
  🔗 Conectar WhatsApp Business
</button>

<script>
function launchWhatsAppSignup() {
  FB.login(function(response) {
    if (response.authResponse) {
      const code = response.authResponse.code;
      // Enviar el code a Convex para completar el flujo
      conectarWhatsApp(code);
    } else {
      console.log('El usuario canceló el login');
    }
  }, {
    config_id: 'TU_CONFIG_ID',  // ← ID del flujo de Embedded Signup en Meta
    response_type: 'code',
    override_default_response_type: true,
    extras: {
      sessionInfoVersion: 3,
    }
  });
}

// Llama a la action de Convex para completar el proceso
async function conectarWhatsApp(code) {
  const colmadoId = 'ID_DEL_COLMADO_ACTUAL'; // obtener del contexto del admin

  const response = await fetch('/api/embedded-signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code, colmadoId })
  });

  const result = await response.json();

  if (result.success) {
    alert(`✅ WhatsApp conectado: ${result.phoneNumber}`);
    // Recargar la UI para mostrar el estado "Conectado"
    window.location.reload();
  } else {
    alert(`❌ Error: ${result.error}`);
  }
}
</script>
```

### Para FlutterFlow (WebView approach):

En FlutterFlow, usa un `WebView` widget que cargue una URL que sirva
este HTML. Cuando la conexión sea exitosa, usa JavaScript Channels
para notificar a Flutter:

```dart
// En el WebView de FlutterFlow
javascriptChannels: {
  JavascriptChannel(
    name: 'WhatsAppConnected',
    onMessageReceived: (msg) {
      // msg.message = phoneNumber conectado
      setState(() => phoneConnected = msg.message);
    }
  )
}
```

---

## Paso 4 — HTTP Action para recibir el code desde el frontend

Agregar esta ruta al `convex/http.ts` para que el frontend pueda
llamar al flujo de Embedded Signup:

```typescript
// En convex/http.ts — agregar esta ruta
http.route({
  path: "/embedded-signup",
  method: "POST",
  handler: httpAction(async (ctx, request) => {
    const { code, colmadoId } = await request.json();

    const result = await ctx.runAction(
      "embeddedSignup:exchangeCodeForToken",
      { code, colmadoId }
    );

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  }),
});
```

---

## Variables de entorno requeridas

| Variable | Descripción | Dónde obtenerla |
|---|---|---|
| `META_APP_ID` | ID de tu Meta App COLMARIA | developers.facebook.com → tu app |
| `META_APP_SECRET` | Secret de tu Meta App | developers.facebook.com → tu app → Configuración básica |
| `CONVEX_SITE_URL` | URL base de Convex (`https://xxx.convex.site`) | Convex Dashboard |
| `WHATSAPP_VERIFY_TOKEN` | Token de verificación del webhook | Lo defines tú |

```bash
npx convex env set META_APP_ID "123456789012345"
npx convex env set META_APP_SECRET "abc123secret"
npx convex env set CONVEX_SITE_URL "https://tu-proyecto.convex.site"
npx convex env set WHATSAPP_VERIFY_TOKEN "colmaria_verify_secret"
```

---

## Flujo completo de onboarding de un colmado

```
Dueño del colmado (Web Admin)
         │
         │  1. Clic en "Conectar WhatsApp"
         ▼
  Popup de Facebook Login
  (Meta Embedded Signup)
         │
         │  2. El dueño inicia sesión con Facebook
         │     y autoriza su WhatsApp Business
         ▼
  Meta retorna `code` al frontend
         │
         │  3. Frontend envía code a /embedded-signup
         ▼
  Convex Action: exchangeCodeForToken
  ├── Intercambia code por token
  ├── Obtiene WABA_ID y Phone_ID
  ├── Suscribe el webhook de COLMARIA
  └── Guarda en DB: waba_id, phone_id, token
         │
         │  4. Responde: "✅ Conectado: +1809XXXXXXX"
         ▼
  Web Admin muestra estado: 🟢 WhatsApp Conectado
         │
  A partir de aquí, todos los mensajes de ese
  número llegan al webhook /whatsapp de COLMARIA
  y el LLM responde automáticamente
```

---

## Diagrama de un solo webhook para N colmados

```
Cliente A  →  WhatsApp  →  Webhook /whatsapp (Convex)
Cliente B  →  WhatsApp  ↗       │
Cliente C  →  WhatsApp  ↗       │
                                │
                     parseWhatsAppPayload()
                                │
                     ¿display_phone_number?
                    ┌──────────┴──────────┐
               +1809XXX1          +1809XXX2
                    │                    │
             Colmado A            Colmado B
             LLM responde         LLM responde
             con su catálogo      con su catálogo
```

---

## Notas importantes

- ❗ **Nunca hardcodear** `META_APP_SECRET` en el código frontend
- ✅ El App Secret solo se usa en Convex (backend)
- ⚠️ El token de usuario dura **60 días** — para producción convertir a System User Token permanente
- ✅ Un mismo webhook URL sirve a **todos** los colmados — el `display_phone_number` los distingue
- 📱 El dueño del colmado solo necesita una cuenta de **Facebook Business** para conectar
