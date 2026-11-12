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

# Force exactly one Apache MPM (mod_php needs prefork). Some builds end up with
# more than one MPM referenced, which makes apache2 fail to start with
# "More than one MPM loaded". Print the state, then hard-reset to prefork only.
RUN set -x; \
    echo "=== mods-enabled MPM ==="; ls -la /etc/apache2/mods-enabled/ | grep -i mpm || true; \
    echo "=== explicit LoadModule mpm anywhere ==="; grep -rniE "LoadModule .*mpm" /etc/apache2/ 2>/dev/null || true; \
    rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf \
          /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf; \
    grep -rlniE "LoadModule mpm_(event|worker)_module" /etc/apache2/ 2>/dev/null | xargs -r sed -i -E "/LoadModule mpm_(event|worker)_module/d"; \
    ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.load; \
    ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf 2>/dev/null || true; \
    echo "=== after fix ==="; ls -la /etc/apache2/mods-enabled/ | grep -i mpm || true; \
    APACHE_DOCUMENT_ROOT=/var/www/html/docroot apache2ctl -t 2>&1 | head -5 || true

# Headless install on first boot (keeps the stock cron/worker entrypoints).
COPY entrypoint_mautic_web.sh /entrypoint_mautic_web.sh
RUN chmod 755 /entrypoint_mautic_web.sh
