// Nine Forge P0 — region code resolution.
// Given a list of 법정동코드 (any level), optionally expand to include
// child regions (sido → sigungu → eupmyeondong). Used by query-* to turn
// user-selected regions into the exact region_code set to filter on.

import type { SupabaseClient } from "./supabase-client.ts";

export interface ResolveOptions {
  includeChildren?: boolean;  // default true
}

export interface ResolvedRegion {
  region_code: string;
  region_name: string;
  level: string | null;
  sido_code: string | null;
  sigungu_code: string | null;
}

export async function resolveRegionCodes(
  client: SupabaseClient,
  codes: string[],
  options: ResolveOptions = {},
): Promise<ResolvedRegion[]> {
  const { includeChildren = true } = options;

  if (codes.length === 0) return [];

  if (!includeChildren) {
    const { data, error } = await client
      .from("dim_region")
      .select("region_code, region_name, level, sido_code, sigungu_code")
      .in("region_code", codes);
    if (error) throw error;
    return data ?? [];
  }

  // Recursive descent via parent_code. Batched at each depth.
  const seen = new Map<string, ResolvedRegion>();
  let frontier = codes;

  while (frontier.length > 0) {
    const { data, error } = await client
      .from("dim_region")
      .select("region_code, region_name, level, sido_code, sigungu_code, parent_code")
      .or(
        `region_code.in.(${frontier.join(",")}),parent_code.in.(${frontier.join(",")})`,
      );
    if (error) throw error;

    const nextFrontier: string[] = [];
    for (const row of data ?? []) {
      if (seen.has(row.region_code)) continue;
      seen.set(row.region_code, {
        region_code: row.region_code,
        region_name: row.region_name,
        level: row.level,
        sido_code: row.sido_code,
        sigungu_code: row.sigungu_code,
      });
      nextFrontier.push(row.region_code);
    }

    // Only descend further through rows that were *newly* discovered via parent match.
    frontier = nextFrontier.filter((c) => !codes.includes(c));
  }

  return Array.from(seen.values());
}

export function containsAtLeastOneCode(resolved: ResolvedRegion[], codes: string[]): boolean {
  const set = new Set(resolved.map((r) => r.region_code));
  return codes.some((c) => set.has(c));
}
