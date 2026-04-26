import { auth } from "./auth";

declare module "./_generated/server" {
  interface ActiveSession extends Record<string, any> {}
  interface Identity extends Record<string, any> {}
}

export default { auth, providers: [{ domain: "http://localhost:5173", applicationID: "convex" }] };
