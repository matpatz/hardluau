# hardluau/web

Browser UI for the hardluau suite: browse, filter, search, and read every
entry in `metadata/index.json` with line numbers and Luau syntax
highlighting.

## Structure

```
web/
  index.html        page shell
  css/styles.css     theme + layout (single stylesheet, no build step)
  js/app.js          fetch, filter, search, keyboard nav, viewer
  js/highlight.js    small self-contained Luau tokenizer (window.highlightLuau)
```

No framework, no bundler, no npm dependencies at runtime. `js/highlight.js`
is a purpose-built ~150-line tokenizer rather than a vendored copy of
highlight.js/Prism — it's lighter to ship and handles Luau's edge cases
(long-bracket strings with `=` levels, backtick interpolation, compound
assignment operators, `@attributes`) directly instead of patching a generic
Lua grammar.

## How it loads data

`js/app.js` fetches two things at runtime, both by **absolute path from the
site root** (not relative to `web/`), so the app works the same whether it's
served from `/` or reached via a rewrite:

- `GET /metadata/index.json` — the suite index
- `GET /<entry.file>` — e.g. `/src/semantic-traps/metamethod-chains.luau`,
  fetched lazily the first time an entry is opened, then cached in memory

This means the app needs the **whole repo** (not just `web/`) served over
HTTP. Every suite entry — including `src/roblox/` (Roblox-only scripts)
and `src/detections/` (environment detection) — is indexed in `index.json`
and listed in the sidebar.

## Local development

Run a static file server from the **repo root** (not from inside `web/`),
since the app requests `/metadata/...` and `/src/...` as root-relative
paths:

```bash
# from the repo root
npx serve .          # or: npm run dev
# or, no npm needed:
python3 -m http.server 4173   # or: npm run dev:python
```

Then open `http://localhost:<port>/web/` (or `/web/index.html`). Opening
`index.html` directly via `file://` will not work — `fetch()` needs HTTP.

## Deploying to Vercel

The repo root deploys as-is: `vercel.json` (at the repo root) rewrites the
`/` route to `/web/index.html`, while every other path — `/metadata/...`,
`/src/...`, `/web/css/...`, `/web/js/...` — is served untouched as a static
file, so the app's root-relative fetches resolve correctly in production
too.

```bash
vercel dev      # local preview using the same routing as production
vercel deploy   # preview deploy
vercel --prod   # production deploy
```

No project settings need to be touched in the dashboard: no framework
preset, no build command, no output directory override — it's a static
deploy of the repo root.

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| `/` | Focus search |
| `↑` `↓` | Move between entries (list) / step through entries (viewer) |
| `Enter` / `Space` | Open the focused entry |
| `Esc` | Close the source viewer |
