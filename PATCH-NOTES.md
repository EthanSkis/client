# Patch notes — claude/audit-clearbot-user-flow-Tbzl4

The following additions are prepared locally and will land in a
follow-up commit on this branch. They are additive and don't modify
any existing selectors or functions.

## `css/styles.css` — append after `.tile .delta { ... }`

```css
.tile-skel {
  display: inline-block;
  width: 56px;
  height: 28px;
  border-radius: 2px;
  background:
    linear-gradient(90deg,
      rgba(243, 241, 234, 0.05) 0%,
      rgba(243, 241, 234, 0.12) 50%,
      rgba(243, 241, 234, 0.05) 100%);
  background-size: 200% 100%;
  animation: tileSkelShimmer 1.3s linear infinite;
}

@keyframes tileSkelShimmer {
  from { background-position: 100% 0; }
  to   { background-position: -100% 0; }
}

.tile .val.val-error {
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.14em;
  color: var(--bad);
  text-transform: uppercase;
}

.tile .val.val-empty { color: var(--ink-dim); }

.data-error-banner {
  margin: 0 0 20px;
  padding: 14px 16px;
  border: 1px solid rgba(216, 140, 124, 0.28);
  background: rgba(216, 140, 124, 0.06);
  color: var(--bad);
  font-size: 12px;
  letter-spacing: 0.02em;
  border-radius: 2px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.data-error-banner strong {
  font-weight: 500;
  color: var(--ink);
  margin-right: 4px;
}

.onboarding-card[hidden] { display: none; }
```

## `js/app.js` — additions near `renderDashboard`

Before `renderDashboard(user)`, add the helpers:

```js
function firstDataError(...lists) {
  for (const list of lists) {
    if (list && Array.isArray(list) && list._error) return list._error;
  }
  return null;
}

function renderDataErrorBanner(target, err) {
  if (!target || !err) return;
  const banner = document.createElement('div');
  banner.className = 'data-error-banner';
  banner.setAttribute('role', 'alert');
  banner.innerHTML =
    '<strong>Couldn\u2019t load everything.</strong>' +
    (err === 'rls'
      ? ' Your account doesn\u2019t have permission to read some of this data. If this is wrong, message us and we\u2019ll sort it.'
      : ' We hit an error talking to the backend. Refresh to try again \u2014 if it keeps failing, ping support.');
  target.parentNode.insertBefore(banner, target);
}

function showOnboardingIfEmpty(projects) {
  const card = document.querySelector('[data-onboarding-card]');
  if (!card) return;
  let dismissed = false;
  try { dismissed = localStorage.getItem('portal:onboarding-dismissed') === '1'; } catch (_) {}
  card.hidden = dismissed || (projects && projects.length > 0);
  const closeBtn = card.querySelector('[data-onboarding-close]');
  if (closeBtn && !closeBtn.dataset.bound) {
    closeBtn.dataset.bound = '1';
    closeBtn.addEventListener('click', () => {
      card.hidden = true;
      try { localStorage.setItem('portal:onboarding-dismissed', '1'); } catch (_) {}
    });
  }
}
```

Inside `renderDashboard`, right after the `Promise.all` call that
destructures `[profile, projects, activity, invoices, threads]`, add:

```js
const err = firstDataError(projects, activity, invoices, threads);
const tilesEl = document.querySelector('.tiles');
if (err && tilesEl && !document.querySelector('.data-error-banner')) {
  renderDataErrorBanner(tilesEl, err);
}
showOnboardingIfEmpty(projects);
```

These two edits:
- render the red banner above the tiles when any core fetcher attached a real `_error` (not a missing-table).
- show the dashboard onboarding card to new users with zero projects, with a persistent dismissal.

## Already landed in earlier commits on this branch

- `js/auth.js`: visible interstitial when bouncing admin/team users to `team.clearbot.io`.
- `js/data.js`: fetchers attach `_error` for real failures (missing-table still silent).
- `index.html`: loading skeletons on tiles + onboarding-card markup.
- `projects.html`: "Every thing" → "Everything".
- `messages.html`: subtitle reworded away from support-chat phrasing.
- `settings.html`: split into Organization / Profile / Billing / Security with bracketed cards.
