import { action } from "./_generated/server";
import { v } from "convex/values";

// Credenciales hardcodeadas para testing
// REMOVER en producción
const DEMO_USERS = [
  { email: "admin@colmado.com", password: "colmado123", name: "Admin Colmado" },
  { email: "test@colmado.com", password: "test123", name: "Test User" },
];

export const demoSignIn = action({
  args: {
    email: v.string(),
    password: v.string(),
  },
  handler: async (ctx, args) => {
    const user = DEMO_USERS.find(
      (u) => u.email === args.email && u.password === args.password
    );

    if (!user) {
      throw new Error("Credenciales incorrectas");
    }

    // En un sistema real, aquí generaríamos un JWT
    // Por ahora retornamos un objeto de sesión simulada
    return {
      success: true,
      user: {
        email: user.email,
        name: user.name,
      },
      // Token simulado (en producción usar auth.generateToken)
      token: `demo_token_${Date.now()}`,
    };
  },
});

export const demoCheckSession = action({
  args: {},
  handler: async (ctx) => {
    // En testing siempre retornar un usuario
    return {
      email: "admin@colmado.com",
      name: "Admin Colmado",
    };
  },
});

export const demoSignOut = action({
  args: {},
  handler: async (ctx) => {
    return { success: true };
  },
});