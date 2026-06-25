# Toy Marketplace

A peer-to-peer toy marketplace built with React, TypeScript, and Supabase. Sellers can list toys for sale; buyers can browse, save, and message sellers directly.

## Demo

![Sign up and sell a product](video/demo-sign-up-and-sell-product.gif)

## Tech Stack

- **Frontend:** React 18 + TypeScript + Vite
- **UI:** Tailwind CSS + shadcn/ui (Radix primitives)
- **Data fetching:** TanStack Query v5
- **Forms:** React Hook Form + Zod
- **Routing:** React Router v6
- **Backend:** Supabase (Auth, Postgres, Realtime, Storage)

## Features

- Email sign-up / sign-in with profile management
- Create, edit, and delete toy listings with up to 5 images
- Browse and search products by category
- Save / unsave products to a wishlist
- Real-time buyer–seller messaging with read receipts
- Online presence indicator via Supabase Realtime

## Local Development

### Prerequisites

- Node.js 18+
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Docker (for local Supabase stack)

### Setup

```bash
# Install dependencies
npm install

# Start local Supabase (requires Docker)
supabase start

# Start the dev server
npm run dev
```

App runs at `http://localhost:8080`. Supabase Studio at `http://localhost:54323`.

### Test accounts (available after `supabase db reset`)

| Email | Password |
|---|---|
| user001@gmail.com | Test1234! |
| user002@gmail.com | Test1234! |

### Database

```bash
supabase db reset        # wipe and re-apply all migrations + seed data
supabase migration up    # apply only new migrations (keeps existing data)
supabase db push         # deploy migrations to remote Supabase project
```

## Database Schema

![Local Supabase database schema](imgs/loca-supabase-database.png)

Key tables: `profiles`, `products`, `product_images`, `conversations`, `participants`, `messages`, `message_status`, `saved_products`.

## Local Docker Containers

![Docker containers running local Supabase](imgs/local-docker-container.png)

## Commands

```bash
npm run dev        # start dev server (localhost:8080)
npm run build      # production build
npm run lint       # ESLint
npm run preview    # preview production build
```
