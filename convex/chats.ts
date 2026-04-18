import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============ QUERIES ============

// Query: getChatsActivos
export const getChatsActivos = query({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    // Chats con actividad en las últimas 24 horas
    const hace24h = Date.now() - 24 * 60 * 60 * 1000;
    return await ctx.db
      .query("chats")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .filter((q) => q.gte("ultima_actividad", hace24h))
      .order("desc")
      .collect();
  },
});

// Query: getChatByTelefono
export const getChatByTelefono = query({
  args: {
    colmadoId: v.id("colmados"),
    telefono: v.string(),
  },
  handler: async (ctx, args) => {
    const chats = await ctx.db
      .query("chats")
      .withIndex("by_colmado_telefono", (q) => 
        q.eq("colmado_id", args.colmadoId).eq("cliente_telefono", args.telefono)
      )
      .collect();
    return chats[0] || null;
  },
});

// Query: getChatById
export const getChatById = query({
  args: {
    chatId: v.id("chats"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.chatId);
  },
});

// Query: getTodosLosChats
export const getTodosLosChats = query({
  args: {
    colmadoId: v.id("colmados"),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("chats")
      .withIndex("by_colmado_id", (q) => q.eq("colmado_id", args.colmadoId))
      .order("desc")
      .collect();
  },
});

// ============ MUTATIONS ============

// Mutation: crearOActualizarChat
export const crearOActualizarChat = mutation({
  args: {
    colmadoId: v.id("colmados"),
    clienteTelefono: v.string(),
    mensaje: v.object({
      role: v.union(v.literal("user"), v.literal("assistant")),
      content: v.string(),
    }),
  },
  handler: async (ctx, args) => {
    // Buscar chat existente
    const chatsExistentes = await ctx.db
      .query("chats")
      .withIndex("by_colmado_telefono", (q) => 
        q.eq("colmado_id", args.colmadoId).eq("cliente_telefono", args.clienteTelefono)
      )
      .collect();

    if (chatsExistentes.length > 0) {
      // Actualizar chat existente
      const chat = chatsExistentes[0];
      await ctx.db.patch(chat._id, {
        historial: [...chat.historial, args.mensaje],
        ultima_actividad: Date.now(),
      });
      return chat._id;
    } else {
      // Crear nuevo chat
      const chatId = await ctx.db.insert("chats", {
        colmado_id: args.colmadoId,
        cliente_telefono: args.clienteTelefono,
        historial: [args.mensaje],
        bot_activo: true,
        ultima_actividad: Date.now(),
        created_at: Date.now(),
      });
      return chatId;
    }
  },
});

// Mutation: agregarMensajeChat
export const agregarMensajeChat = mutation({
  args: {
    chatId: v.id("chats"),
    mensaje: v.object({
      role: v.union(v.literal("user"), v.literal("assistant"), v.literal("system")),
      content: v.string(),
    }),
  },
  handler: async (ctx, args) => {
    const chat = await ctx.db.get(args.chatId);
    if (!chat) {
      throw new Error("Chat no encontrado");
    }

    await ctx.db.patch(args.chatId, {
      historial: [...chat.historial, args.mensaje],
      ultima_actividad: Date.now(),
    });

    return args.chatId;
  },
});

// Mutation: toggleBotActivo
export const toggleBotActivo = mutation({
  args: {
    chatId: v.id("chats"),
  },
  handler: async (ctx, args) => {
    const chat = await ctx.db.get(args.chatId);
    if (!chat) {
      throw new Error("Chat no encontrado");
    }

    await ctx.db.patch(args.chatId, {
      bot_activo: !chat.bot_activo,
    });

    return !chat.bot_activo;
  },
});

// Mutation: reiniciarChat
export const reiniciarChat = mutation({
  args: {
    chatId: v.id("chats"),
  },
  handler: async (ctx, args) => {
    const chat = await ctx.db.get(args.chatId);
    if (!chat) {
      throw new Error("Chat no encontrado");
    }

    await ctx.db.patch(args.chatId, {
      historial: [],
      bot_activo: true,
      ultima_actividad: Date.now(),
    });

    return { success: true };
  },
});