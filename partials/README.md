# Portal layout & data notes

## Shell

Each page shares the same markup:

- **Topbar** — brand, breadcrumb, user chip
- **Sidebar** — Dashboard, Projects, Deliverables, Messages, Invoices, Settings, Sign Out
- **Main** — page-specific content

Shared assets:

- `css/styles.css` — design tokens + all component styles
- `js/supabase.js` — shared Supabase client + config constants
- `js/auth.js` — `requireSession()`, `signOut()`, identity helpers
- `js/data.js` — per-user data fetchers (fail soft if tables don't exist yet)
- `js/app.js` — bootstrap + renderers; injects the SVG logo sprite and dispatches rendering on `<body data-page="...">`
- `assets/favicon.svg`

## Auth

Every page runs `requireSession()` before rendering. On no session, the user is redirected to `https://login.clearbot.io`. The path they were trying to reach is stored in `localStorage.portal_redirect` so they land back there after signing in. Sign-out clears the session and returns to the login site.

## Per-user data

All data is keyed by the Supabase `auth.uid()` of the signed-in user. The fetchers in `js/data.js` return empty arrays when the underlying table is missing, so a brand-new Supabase project shows empty states on every view.

### Expected tables (suggested schema)

These are the shapes the portal reads. Create them in Supabase and add RLS policies so each row is only visible to its owner.

**`profiles`** — one row per user
- `user_id uuid primary key references auth.users(id)`
- `company_name text`, `primary_domain text`, `timezone text`
- `first_name text`, `last_name text`, `email text`, `role text`
- `notif_deliverables bool`, `notif_messages bool`, `notif_digest bool`, `notif_invoices bool`, `notif_slack bool`
- `updated_at timestamptz default now()`

**`projects`**
- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references auth.users(id)`
- `name text not null`, `description text`, `status text`, `progress int default 0`
- `next_milestone text`, `updated_at timestamptz default now()`

**`deliverables`**
- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references auth.users(id)`
- `project_id uuid references projects(id)`, `project_name text`
- `name text`, `file_type text`, `size_label text`, `status text`, `version text`, `url text`
- `updated_at timestamptz default now()`

**`invoices`**
- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references auth.users(id)`
- `number text`, `project_name text`, `amount_cents int`
- `issued_at timestamptz`, `due_at timestamptz`, `paid_at timestamptz`
- `status text`, `pdf_url text`

**`message_threads`**
- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references auth.users(id)`
- `title text`, `preview text`, `project_name text`
- `unread_count int default 0`, `status text`, `updated_at timestamptz default now()`

**`activity`**
- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references auth.users(id)`
- `text text`, `project_name text`, `unread bool default false`
- `created_at timestamptz default now()`

Turn on RLS and add policies like:

```sql
alter table projects enable row level security;
create policy "own projects" on projects for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

## Adding a new page

1. Copy an existing page (e.g. `projects.html`) and update `<title>`, breadcrumb `.here`, and `<body data-page="…">`.
2. Add a matching sidebar link with `data-nav="your-page.html"`.
3. Drop your markup inside `<main class="main">` with data-* attributes.
4. Wire rendering in `js/app.js` by adding a function to `RENDERERS`.
