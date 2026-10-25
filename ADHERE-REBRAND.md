# AdhereOne rebrand notes

Base: CISO Assistant Community v4.1.5 (branch `adhere/rebrand`).

## What is changed (user-visible only)
- Product name in UI strings (`frontend/messages/*.json`), page titles, chat widget, MFA issuer name, export filename.
- Logo (`frontend/src/lib/assets/ciso.svg` now holds the AdhereOne logo), favicons, `frontend/static/adhereone-logo.png` (used in emails).
- Email templates and PDF footer (`backend/core/templates`, `backend/doc_management/templates`), plus `backend/locale/*.po`/`.mo`.
- Sidebar "Source code (AGPL-3.0)" link (AGPL section 13 source offer).

## What is deliberately NOT changed
- `urn:intuitem:*` identifiers, library files, Python package names, `CISO_ASSISTANT_*` environment variables, metric names, API paths.
  Renaming them would break library imports and upstream merges.
- The `enterprise/` directory is commercial intuitem code; do not build or deploy it without a licence.

## Open items
- Sidebar "Online docs" still links to intuitem's documentation.
- Confirm trademark position with intuitem in writing before launch.
- Docker images must be built from this repo, not pulled from `ghcr.io/intuitem/`.
