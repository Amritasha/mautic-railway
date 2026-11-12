# Mautic on Railway

[Mautic](https://www.mautic.org) is an open-source marketing-automation platform
(a self-hosted HubSpot alternative). This image patches the official
`mautic/mautic` apache image so it deploys on Railway with **no manual install
wizard**:

- **Headless install** — the first admin and the database schema are created on
  first boot from `MAUTIC_ADMIN_*` and `MAUTIC_DB_*` environment variables.
- **Apache MPM fix** — forces a single MPM so Apache doesn't fail to start with
  "More than one MPM loaded".

The stock cron and worker entrypoints are untouched, so the same image runs the
`mautic_web`, `mautic_cron`, and `mautic_worker` roles via `DOCKER_MAUTIC_ROLE`.

## Required environment

- `DOCKER_MAUTIC_ROLE` — `mautic_web`, `mautic_cron`, or `mautic_worker`
- `MAUTIC_DB_HOST`, `MAUTIC_DB_PORT`, `MAUTIC_DB_DATABASE`, `MAUTIC_DB_USER`, `MAUTIC_DB_PASSWORD`
- `MAUTIC_URL` — public URL of the instance
- `MAUTIC_ADMIN_EMAIL`, `MAUTIC_ADMIN_USERNAME`, `MAUTIC_ADMIN_PASSWORD`
