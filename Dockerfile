# Mautic for Railway — patches the official image so it deploys headlessly.
#
# Two fixes over mautic/mautic:*-apache:
#   1. Apache fails to boot on some hosts with "More than one MPM loaded";
#      we force a single MPM (mod_php needs prefork).
#   2. The stock web entrypoint only installs Mautic when loading test data,
#      otherwise it waits for the manual web wizard. We replace the web
#      entrypoint with one that installs headlessly from env vars on first boot.
FROM mautic/mautic:7.2.2-apache

USER root

# Ensure exactly one Apache MPM is enabled.
RUN a2dismod mpm_event 2>/dev/null || true; \
    a2dismod mpm_worker 2>/dev/null || true; \
    a2enmod mpm_prefork 2>/dev/null || true

# Headless install on first boot (keeps the stock cron/worker entrypoints).
COPY entrypoint_mautic_web.sh /entrypoint_mautic_web.sh
RUN chmod 755 /entrypoint_mautic_web.sh
