#!/usr/bin/env python3
"""Nine Forge — legal_dong_code loader (Python port).

Identical semantics to load_legal_dong_code.ts:
  - source file (`_dev/seeds/legal_dong_code.txt`, tab-separated) is OPTIONAL
  - EUC-KR auto-decode (UTF-8 BOM also supported)
  - 폐지 → is_deprecated = true, 존재 → false
  - idempotent upsert on `code`

Run:
  set -a; source _dev/.env.local; set +a
  python3 _dev/scripts/load_legal_dong_code.py

Env:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
  LEGAL_DONG_CODE_PATH  (optional; default _dev/seeds/legal_dong_code.txt)
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

DEFAULT_PATH = "_dev/seeds/legal_dong_code.txt"
BATCH_SIZE = 500


def log(level: str, message: str, **ctx) -> None:
    entry = {
        "level": level,
        "message": message,
        "ts": datetime.utcnow().isoformat() + "Z",
        "script": "load_legal_dong_code",
        **ctx,
    }
    stream = sys.stderr if level in ("error", "warn") else sys.stdout
    print(json.dumps(entry, ensure_ascii=False), file=stream, flush=True)


def decode_bytes(raw: bytes) -> str:
    if raw[:3] == b"\xef\xbb\xbf":
        return raw[3:].decode("utf-8")
    try:
        text = raw.decode("utf-8")
        if re.search(r"[가-힣]", text):
            return text
    except UnicodeDecodeError:
        pass
    return raw.decode("euc-kr", errors="replace")


def parse_rows(text: str):
    rows = []
    skipped = 0
    lines = text.split("\n")
    for i, raw_line in enumerate(lines):
        line = raw_line.rstrip("\r")
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            skipped += 1
            continue
        code = parts[0].strip()
        name = parts[1].strip()
        status = parts[2].strip()

        if i == 0 and not re.fullmatch(r"\d{10}", code):
            skipped += 1
            continue
        if not re.fullmatch(r"\d{10}", code):
            skipped += 1
            continue
        if not name:
            skipped += 1
            continue

        rows.append({"code": code, "name": name, "is_deprecated": status == "폐지"})
    return rows, skipped


def upsert_batch(url: str, key: str, batch):
    endpoint = f"{url}/rest/v1/dim_region?on_conflict=code"
    body = json.dumps(batch, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        endpoint,
        data=body,
        method="POST",
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        resp.read()
        return resp.status


def main() -> int:
    path = os.environ.get("LEGAL_DONG_CODE_PATH", DEFAULT_PATH)

    if not os.path.exists(path):
        log("warn", "legal_dong_code.txt not found, dim_region left empty", path=path)
        return 0

    with open(path, "rb") as f:
        raw = f.read()

    text = decode_bytes(raw)
    rows, skipped = parse_rows(text)
    log("info", "parsed legal dong code file", path=path, bytes=len(raw), rows=len(rows), skipped=skipped)

    if not rows:
        log("warn", "no valid rows parsed, skipping upsert")
        return 0

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        log("error", "missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars")
        return 1

    active = sum(1 for r in rows if not r["is_deprecated"])
    deprecated = len(rows) - active
    sido_codes = sorted({r["code"][:2] for r in rows})
    log("info", "starting upsert", total=len(rows), active=active, deprecated=deprecated, sido_codes=sido_codes)

    inserted = 0
    errors = 0
    t0 = time.time()

    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        try:
            status = upsert_batch(url, key, batch)
            if status not in (200, 201, 204):
                errors += 1
                log("error", "unexpected status", batch_start=i, status=status)
            else:
                inserted += len(batch)
        except urllib.error.HTTPError as e:
            errors += 1
            body = e.read().decode("utf-8", errors="replace")[:400]
            log("error", "batch upsert failed", batch_start=i, status=e.code, body=body)
        except Exception as e:
            errors += 1
            log("error", "batch upsert exception", batch_start=i, error=str(e))

        if (i // BATCH_SIZE) % 10 == 0:
            log("info", "batch progress", processed=i + len(batch), total=len(rows))

    dt = time.time() - t0
    log("info", "upsert complete", inserted=inserted, errors=errors, total=len(rows), seconds=round(dt, 2))

    return 2 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
