# Deploying AdhereOne on Render

One stack = `adhereone` (Caddy, public) -> `adhereone-frontend` + `adhereone-backend` (private) -> `adhereone-db` (Postgres).
The task worker (Huey) runs inside the backend container (`RUN_HUEY=true`), because upstream's queue is a SQLite file.

## Before you start
1. **HIPAA decision.** If this stack will hold PHI (evidence uploads can), create it in a HIPAA-enabled Render workspace
   (Scale plan, BAA signed) and sign a BAA with your S3/email providers. Do this *before* the first sync; enabling later redeploys everything.
2. **Hostname.** `render.yaml` assumes `app.adheresystems.com`. Change it in the three places it appears if you want another.

## Steps
1. GitHub: enable Actions on the fork, then push to `adhere/rebrand` (or run "AdhereOne images" manually).
   Wait for both jobs to finish.
2. GitHub > Your profile > Packages: open `adhere-one/backend` and `adhere-one/frontend`, then Package settings >
   Change visibility > Public (or give Render registry credentials). The images contain only AGPL code.
3. Render: New > Blueprint > pick this repo and branch. Enter `DJANGO_SUPERUSER_EMAIL` and `DJANGO_SUPERUSER_PASSWORD` when prompted.
4. Render > `adhereone` service > Settings > Custom Domains: add the hostname. In Zoho DNS add the CNAME Render shows.
5. Open the site, sign in as the superuser, and change that password.
6. Optional auto-deploy: add `RENDER_DEPLOY_HOOK_BACKEND` and `RENDER_DEPLOY_HOOK_FRONTEND` as GitHub repository secrets
   (each service > Settings > Deploy Hook).

## Before real client data
- Evidence storage: set `USE_S3=True` plus `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_STORAGE_BUCKET_NAME`, `AWS_S3_REGION_NAME`.
- Configure outgoing email in the app's settings.
- Confirm Postgres backups and test one restore.

## Known limits
- Backend image is large (PyTorch and embedding models are baked in for the AI features). Expect a long first pull.
- Backend plan `1c-2g` runs gunicorn (2 workers) and Huey (2 workers); watch memory and raise the plan if it restarts.
- Upstream's Qdrant (AI vector DB) and MCP server are not deployed.
- Untested here: Docker builds, the Render Blueprint, and the Caddy config (no Docker daemon or Render access in the build sandbox).
