// Nine Forge P0 — query filter → SQL WHERE fragment builder.
//
// query-* Edge Functions accept a filter object from the client (regions,
// categories, tags, period, source). This helper turns that into a set of
// Supabase PostgREST `.in()`/`.gte()`/`.lte()`/`.contains()` calls, keeping
// the query logic consistent across fact_event, fact_metric, and dim_venue.

import type { PostgrestFilterBuilder } from "https://esm.sh/@supabase/postgrest-js@1";
import type { PeriodGranularity, SourceCode } from "./types.ts";

export interface CommonFilters {
  sources?: SourceCode[];
  region_codes?: string[];
  categories?: string[];
  tags?: string[];
  period_start_gte?: string;   // ISO date
  period_end_lte?: string;     // ISO date
  period_granularities?: PeriodGranularity[];
}

export function applyCommonFilters<T extends PostgrestFilterBuilder<any, any, any>>(
  query: T,
  filters: CommonFilters,
): T {
  let q: PostgrestFilterBuilder<any, any, any> = query;

  if (filters.sources?.length) {
    q = q.in("source", filters.sources);
  }
  if (filters.region_codes?.length) {
    q = q.in("region_code", filters.region_codes);
  }
  if (filters.categories?.length) {
    // `.overlaps()` matches if the row's categories[] shares any element with filter
    q = q.overlaps("categories", filters.categories);
  }
  if (filters.tags?.length) {
    q = q.overlaps("tags", filters.tags);
  }
  if (filters.period_start_gte) {
    q = q.gte("period_start", filters.period_start_gte);
  }
  if (filters.period_end_lte) {
    q = q.lte("period_end", filters.period_end_lte);
  }
  if (filters.period_granularities?.length) {
    q = q.in("period_granularity", filters.period_granularities);
  }

  return q as T;
}

// Convenience: warn when mixing incompatible granularities
export function detectGranularityMismatch(
  granularities: PeriodGranularity[],
): { mismatch: boolean; present: PeriodGranularity[] } {
  const unique = Array.from(new Set(granularities));
  return { mismatch: unique.length > 1, present: unique };
}
