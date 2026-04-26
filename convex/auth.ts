import { convexAuth } from "@convex-dev/auth";
import { Password } from "@convex-dev/auth/providers/Password";

export default convexAuth({
  providers: [
    Password({
      params: {
        email: "email",
        password: "password",
      },
      queries: {
        // You can add custom queries here
      },
      mutations: {
        // You can add custom mutations here
      },
    }),
  ],
});