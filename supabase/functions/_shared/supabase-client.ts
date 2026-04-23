// Nine Forge P0 — Supabase client factory.
// Returns either a service_role client (for ingest-*) or an anon client
// (for query-*/export-*). Edge Functions receive these env vars from
// Supabase automatically.

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type ClientMode = "service_role" | "anon";

function requireEnv(key: string): string {
  const value = Deno.env.get(key);
  if (!value) {
    throw new Error(`Missing required env var: ${key}`);
  }
  return value;
}

export function getSupabaseClient(mode: ClientMode = "service_role"): SupabaseClient {
  const url = requireEnv("SUPABASE_URL");
  const key = mode === "service_role"
    ? requireEnv("SUPABASE_SERVICE_ROLE_KEY")
    : requireEnv("SUPABASE_ANON_KEY");

  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { "x-client-info": "nine-forge/edge" } },
  });
}

export type { SupabaseClient };
