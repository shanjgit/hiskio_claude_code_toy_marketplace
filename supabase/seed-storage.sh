#!/usr/bin/env bash
# Upload seed images to local Supabase Storage after `supabase db reset`.
# Usage: bash supabase/seed-storage.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_KEY=$(supabase status --output json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['SERVICE_ROLE_KEY'])" 2>/dev/null)

if [ -z "$SERVICE_KEY" ]; then
  echo "Could not get service role key from supabase status. Is the local stack running?"
  exit 1
fi

upload() {
  local file="$1" path="$2"
  curl -s -X POST \
    "http://127.0.0.1:54321/storage/v1/object/product-images/$path" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Content-Type: image/png" \
    --data-binary "@$file"
  echo " -> $path"
}

upload "$SCRIPT_DIR/../src/assets/toy_bear.png" \
       "bbbbbbbb-0000-0000-0000-000000000001/toy_bear.png"

echo "Done."
