import { env } from "cloudflare:workers";
import { drizzle } from "drizzle-orm/d1";
import * as schema from "./schema";

export function getDb() {
  if (!env.DB) {
    throw new Error(
      "Cloudflare D1 binding `DB` is unavailable. Check the `d1` field in config/runtime-bindings.json and the worker's D1 binding."
    );
  }

  return drizzle(env.DB, { schema });
}
