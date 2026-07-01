# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Skills Usage Priority

**CRITICAL**: Before starting ANY task, check if a skill is relevant and invoke it IMMEDIATELY as the first action.

### Workflow
```
User request → Identify skills needed → Invoke skill(s) FIRST → Follow skill instructions
```

NOT:
```
User request → Start planning/exploring → Mention skill later ❌
```

If unsure whether a skill applies, invoke it anyway - the skill will provide specialized guidance.


## Commands

```bash
npm run dev          # start dev server (Vite, localhost:8080)
npm run build        # production build
npm run build:dev    # dev-mode build
npm run lint         # ESLint
npm run preview      # preview production build locally
```

There is no test suite configured.

## Supabase Local Development

The Supabase client auto-detects `localhost`/`127.0.0.1` and switches to the local instance (`http://127.0.0.1:54321`). The local Studio runs at `http://localhost:54323`.

```bash
supabase start          # start local Supabase stack
supabase db reset       # re-apply all migrations + seed.sql

# Add a migration
supabase migration new <migration_name>
# edit the generated SQL file
supabase db reset

# Deploy to remote
supabase link --project-ref <PROJECT_REF>
supabase db push
```

MCP server credentials go in `.mcp.json` (copy from `.mcp.json.example`). Required fields: `PROJECT_REF`, `SUPABASE_ACCESS_TOKEN`.

## Architecture

**Stack:** React 18 + TypeScript + Vite, Tailwind CSS + shadcn/ui (Radix primitives), TanStack Query v5, React Hook Form + Zod, React Router v6, Supabase (auth, database, realtime, storage).

**Routing** (`src/App.tsx`): The root route (`/`) renders `Categories`. All routes are wrapped in `QueryClientProvider → TooltipProvider → PresenceProvider`.

**Data layer pattern:** All Supabase calls go through custom hooks in `src/hooks/`. Hooks use TanStack Query for fetching/caching. Mutations call Supabase directly and invalidate relevant queries. Most read operations call Supabase RPC functions (defined in `src/integrations/supabase/types.ts` under `Functions`) rather than querying tables directly — this keeps RLS logic server-side.

Key RPC functions:
- `get_public_products` — product listing with search/sort
- `get_public_product_detail` — single product with joined seller/images
- `get_user_conversations` / `get_conversation_details` / `get_conversation_messages_with_read_status` — messaging
- `create_conversation` — idempotently creates a conversation for a product
- `toggle_saved_product` / `get_user_saved_products` — save/unsave
- `mark_conversation_read` — bulk read receipt

**Auth** (`src/hooks/useAuth.tsx`): Thin hook over `supabase.auth`, returns `{ user, session, loading }`. No context — consumers call the hook directly.

**Presence** (`src/contexts/PresenceProvider.tsx`): Supabase Realtime presence channel (`global-presence`) tracks online users app-wide. Exposed via `usePresence()` hook. Goes offline after 5 s of hidden tab.

**Database schema** (key tables):
- `profiles` — linked 1:1 to `auth.users` via `user_id`
- `products` — seller's listings; toy-specific fields: `color`, `leather`, `stamp`, `year_purchased`
- `product_images` — multiple images per product
- `conversations` → `participants` → `messages` → `message_status` — buyer/seller messaging with per-message read receipts
- `saved_products` — user wishlist

**Image handling** (`src/lib/imageUtils.ts`): `resizeImage()` uses the Canvas API to resize uploads to max 400×400 before uploading to Supabase Storage.

**UI components:** `src/components/ui/` contains shadcn/ui primitives — do not edit these manually; regenerate with `npx shadcn add <component>`. Custom components live directly in `src/components/`.

**Path alias:** `@/` maps to `src/`.

## Pending Work

- Image upload in conversations (see `README_TODO.md`)
