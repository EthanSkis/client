# Layout notes

Each page in the portal shares the same shell:

- **Topbar** — brand mark, breadcrumb, user menu
- **Sidebar** — primary nav (Dashboard, Projects, Deliverables, Messages, Invoices, Settings)
- **Main** — page-specific content

Shared assets:

- `css/styles.css` — design tokens + all component styles
- `js/app.js` — injects the SVG logo sprite, marks the active nav item, wires the user menu
- `assets/favicon.svg` — portal favicon

## Adding a new page

1. Copy the shell from any existing page (e.g. `projects.html`).
2. Update `<title>`, `.page-head`, and the `data-nav="…"` attribute on the matching sidebar link.
3. Add a new `<a class="nav-item" data-nav="your-page.html" href="your-page.html">…</a>` entry to the sidebar in **every** page (the sidebar is not yet a template — it is duplicated).
4. Drop your page-specific markup inside `<main class="main">`.

## Conventions

- Typography: Fraunces for display text, JetBrains Mono for UI.
- Accent: pure white, used sparingly.
- Surface cards use `.panel` (with optional `.bracketed` for the corner ticks).
- Status badges: `.badge`, `.badge.ok`, `.badge.warn`, `.badge.bad`, `.badge.accent`.

When the sidebar markup starts to drift, lift it into a shared partial via a tiny static-site build step (Eleventy / Astro / plain includes).
