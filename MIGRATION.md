# This site is migrating to the unified ClearBot app

The `client.clearbot.io` portal is moving into the single Next.js
project at [`EthanSkis/clearbot.io`](https://github.com/EthanSkis/clearbot.io),
which now serves every `*.clearbot.io` host from one Vercel project.

The dashboard, projects / deliverables / invoices / messages /
settings pages were ported into that repo's `app/(client)` route
group. All Supabase reads + writes that used to live in `js/data.js`
now go through server-side Route Handlers:

- `GET/POST /api/projects`
- `GET /api/deliverables`
- `GET /api/invoices`
- `GET/POST /api/threads` + `POST /api/threads/[id]/read`
- `GET/POST /api/messages`
- `GET /api/activity`
- `GET/PATCH /api/profile`

The cross-domain chunked-cookie storage in `js/supabase.js` is gone —
`@supabase/ssr` uses standard httpOnly cookies scoped to
`.clearbot.io`, which works across subdomains because the unified app
is one origin from Vercel's edge.

The database schema in `db/schema.sql` is unchanged — the new app
reuses every table, RPC, trigger, and RLS policy it defines.

## Cutover

Don't delete this repo's `CNAME` until `client.clearbot.io` is
pointed at `cname.vercel-dns.com`. Staged order: `signup` → `login` →
`client` → `team` → apex. Keep this repo live as a rollback target
during the cutover window.

## After cutover

Once DNS is flipped, this repo can be archived.
