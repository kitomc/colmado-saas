import { auth } from "./_generated/server";
import { Document } from "./_generated/dataModel";

// Your app's authentication configuration.
// See https://docs.convex.dev/auth

declare module "./_generated/server" {
  interface ActiveSession extends Document<"sessions"> {}

  interface Identity extends Document<"users"> {}
}

export default auth;