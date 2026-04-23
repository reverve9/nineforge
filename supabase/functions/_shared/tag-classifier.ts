// Nine Forge P0 — tag classifier (R3: controlled vocabulary enforcement).
//
// Workflow when an adapter encounters a raw tag string:
//   1. normalize(raw)            → trim + casefold + strip whitespace
//   2. match dim_tag.code or dim_tag.display_name or any synonym
//   3. if match → return resolved
//   4. if miss  → upsert dim_tag_pending (increment seen_count) and return null
//
// Admin later reviews dim_tag_pending and either promotes to dim_tag or rejects.

import type { SupabaseClient } from "./supabase-client.ts";
import type { SourceCode, TagResolution } from "./types.ts";

function normalize(raw: string): string {
  return raw.trim().toLowerCase().replace(/\s+/g, "");
}

interface TagRow {
  id: string;
  group_code: string;
  code: string;
  display_name: string;
  synonyms: string[];
}

let tagCache: TagRow[] | null = null;
let tagCacheLoadedAt = 0;
const TAG_CACHE_TTL_MS = 60_000;

async function loadTags(client: SupabaseClient): Promise<TagRow[]> {
  const now = Date.now();
  if (tagCache && now - tagCacheLoadedAt < TAG_CACHE_TTL_MS) return tagCache;

  const { data, error } = await client
    .from("dim_tag")
    .select("id, group_code, code, display_name, synonyms")
    .eq("is_active", true);
  if (error) throw error;

  tagCache = data ?? [];
  tagCacheLoadedAt = now;
  return tagCache;
}

export function clearTagCache(): void {
  tagCache = null;
  tagCacheLoadedAt = 0;
}

export async function classifyTag(
  client: SupabaseClient,
  rawValue: string,
  sourceHint: SourceCode,
  suggestedGroup?: string,
): Promise<TagResolution> {
  const norm = normalize(rawValue);
  if (norm.length === 0) {
    return { resolved: null, pending_queued: false, raw_value: rawValue };
  }

  const tags = await loadTags(client);

  for (const tag of tags) {
    const candidates = [tag.code, tag.display_name, ...tag.synonyms];
    for (const candidate of candidates) {
      if (normalize(candidate) === norm) {
        return {
          resolved: {
            group_code: tag.group_code,
            code: tag.code,
            display_name: tag.display_name,
          },
          pending_queued: false,
          raw_value: rawValue,
        };
      }
    }
  }

  // miss → queue to dim_tag_pending
  const { error } = await client
    .from("dim_tag_pending")
    .upsert(
      {
        raw_value: rawValue,
        seen_in_source: sourceHint,
        suggested_group: suggestedGroup ?? null,
        seen_count: 1,
      },
      { onConflict: "raw_value,seen_in_source", ignoreDuplicates: false },
    );

  // increment seen_count on conflict (two-step: upsert then RPC would be cleaner;
  // for P0 we rely on the upsert to insert-or-noop, and P1 will add a RPC to bump count).
  if (error) {
    // non-fatal: log but don't throw — tag miss shouldn't blow up ingest
    console.warn(JSON.stringify({
      level: "warn",
      message: "dim_tag_pending upsert failed",
      error: error.message,
      raw_value: rawValue,
      source: sourceHint,
    }));
  }

  return { resolved: null, pending_queued: !error, raw_value: rawValue };
}
