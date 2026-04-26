/**
 * embeddedSignup.ts
 * Maneja el flujo de Meta Embedded Signup para conectar
 * el número de WhatsApp de cada colmado a COLMARIA SaaS.
 *
 * Flujo:
 * 1. El admin del colmado hace clic en "Conectar WhatsApp" en el Web Admin
 * 2. Se abre el popup de Facebook Login con permisos de WhatsApp
 * 3. El popup retorna un `code` de autorización OAuth
 * 4. El frontend llama a esta action con el `code`
 * 5. Esta action intercambia el code por un token de usuario
 * 6. Obtiene los WABAs y Phone Numbers del negocio
 * 7. Registra el webhook en el número seleccionado
 * 8. Guarda waba_id, phone_id y token en la tabla colmados
 */

import { action, mutation, query } from "./_generated/server";
import { v } from "convex/values";

// ─── TYPES ─────────────────────────────────────────────────────────────────

interface MetaTokenResponse {
  access_token: string;
  token_type: string;
}

interface WABAInfo {
  id: string;
  name: string;
  phone_numbers?: { data: PhoneNumberInfo[] };
}

interface PhoneNumberInfo {
  id: string;
  display_phone_number: string;
  verified_name: string;
  status: string;
}

// ─── PASO 1: Intercambiar code por access_token ─────────────────────────────

/**
 * Action: exchangeCodeForToken
 * Recibe el code del popup de Facebook y lo intercambia por
 * un token de usuario. Luego obtiene sus WABAs y números.
 *
 * Llamar desde el frontend después del popup:
 * await convex.action(api.embeddedSignup.exchangeCodeForToken, { code, colmadoId })
 */
export const exchangeCodeForToken = action({
  args: {
    code: v.string(),          // code retornado por el popup de Meta
    colmadoId: v.id("colmados"), // ID del colmado en COLMARIA
  },
  handler: async (ctx, args): Promise<{ success: boolean; phoneNumber?: string; error?: string }> => {
    const appId = process.env.META_APP_ID;
    const appSecret = process.env.META_APP_SECRET;
    const webhookUrl = process.env.CONVEX_SITE_URL; // URL del webhook de Convex

    if (!appId || !appSecret || !webhookUrl) {
      throw new Error("META_APP_ID, META_APP_SECRET o CONVEX_SITE_URL no configurados");
    }

    // 1. Intercambiar code por user access token
    const tokenRes = await fetch(
      `https://graph.facebook.com/v20.0/oauth/access_token` +
      `?client_id=${appId}` +
      `&client_secret=${appSecret}` +
      `&code=${args.code}`,
      { method: "GET" }
    );

    if (!tokenRes.ok) {
      const err = await tokenRes.text();
      console.error("[EmbeddedSignup] Token exchange error:", err);
      return { success: false, error: "No se pudo obtener el token de Meta" };
    }

    const tokenData: MetaTokenResponse = await tokenRes.json();
    const userToken = tokenData.access_token;

    // 2. Obtener WABAs del usuario
    const wabasRes = await fetch(
      `https://graph.facebook.com/v20.0/me/businesses?fields=whatsapp_business_accounts{id,name,phone_numbers{id,display_phone_number,verified_name,status}}&access_token=${userToken}`
    );

    const wabasData = await wabasRes.json();
    const wabas: WABAInfo[] = wabasData?.data?.[0]?.whatsapp_business_accounts?.data || [];

    if (wabas.length === 0) {
      return { success: false, error: "No se encontró ninguna cuenta de WhatsApp Business" };
    }

    // Tomar el primer WABA y primer número (en producción mostrar selector)
    const waba = wabas[0];
    const phoneNumbers = waba.phone_numbers?.data || [];

    if (phoneNumbers.length === 0) {
      return { success: false, error: "El WABA no tiene números de teléfono registrados" };
    }

    const phone = phoneNumbers[0];

    // 3. Suscribir el número al webhook de COLMARIA
    // Esto registra el webhook en el WABA del colmado
    const webhookPath = `${webhookUrl}/whatsapp`;
    const subscribeRes = await fetch(
      `https://graph.facebook.com/v20.0/${waba.id}/subscribed_apps`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({
          subscribed_fields: ["messages"],
        }),
      }
    );

    if (!subscribeRes.ok) {
      const err = await subscribeRes.text();
      console.error("[EmbeddedSignup] Webhook subscribe error:", err);
      // No detenemos el flujo — el webhook ya está configurado en la app globalmente
    }

    // 4. Guardar en la tabla colmados
    await ctx.runMutation("embeddedSignup:saveWhatsAppConnection" as any, {
      colmadoId: args.colmadoId,
      wabaId: waba.id,
      phoneId: phone.id,
      phoneNumber: phone.display_phone_number,
      token: userToken,
    });

    console.log(`[EmbeddedSignup] ✅ Colmado ${args.colmadoId} conectado: ${phone.display_phone_number}`);

    return {
      success: true,
      phoneNumber: phone.display_phone_number,
    };
  },
});

// ─── PASO 2: Guardar conexión en la DB ─────────────────────────────────────

export const saveWhatsAppConnection = mutation({
  args: {
    colmadoId: v.id("colmados"),
    wabaId: v.string(),
    phoneId: v.string(),
    phoneNumber: v.string(),
    token: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.colmadoId, {
      waba_id: args.wabaId,
      whatsapp_phone_id: args.phoneId,
      telefono_whatsapp: args.phoneNumber,
      whatsapp_token: args.token,
      meta_conectado: true,
      meta_connected_at: Date.now(),
    });
  },
});

// ─── PASO 3: Desconectar WhatsApp de un colmado ─────────────────────────────

export const desconectarWhatsApp = mutation({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.colmadoId, {
      meta_conectado: false,
      whatsapp_token: "",
      waba_id: undefined,
    });
  },
});

// ─── QUERY: Estado de conexión de un colmado ────────────────────────────────

export const getEstadoConexion = query({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    const colmado = await ctx.db.get(args.colmadoId);
    if (!colmado) return null;
    return {
      meta_conectado: colmado.meta_conectado ?? false,
      telefono_whatsapp: colmado.telefono_whatsapp,
      waba_id: colmado.waba_id,
      meta_connected_at: colmado.meta_connected_at,
    };
  },
});
