#!/bin/bash
# Patched Mautic web entrypoint: install headlessly from env on first boot,
# otherwise run migrations, then start Apache. Replaces the stock script that
# only installs under DOCKER_MAUTIC_LOAD_TEST_DATA.
source /startup/logger.sh

# "Installed" is determined by site_url being present in local.php (db_driver is
# always set by the template, so it can't be the signal).
if php -r "include('${MAUTIC_VOLUME_CONFIG}/local.php'); exit(!empty(\$parameters['site_url']) ? 0 : 1);"; then
  log "[${DOCKER_MAUTIC_ROLE}]: Mautic is already installed, running migrations..."
  su -s /bin/bash "$MAUTIC_WWW_USER" -c "php $MAUTIC_CONSOLE doctrine:migrations:migrate -n" || \
    log "[${DOCKER_MAUTIC_ROLE}]: migrations returned non-zero (continuing)."
else
  log "[${DOCKER_MAUTIC_ROLE}]: Mautic is not installed — running headless install..."
  su -s /bin/bash "$MAUTIC_WWW_USER" -c "php $MAUTIC_CONSOLE mautic:install -n --force \
    --admin_email \"${MAUTIC_ADMIN_EMAIL:-admin@example.com}\" \
    --admin_firstname \"${MAUTIC_ADMIN_FIRSTNAME:-Admin}\" \
    --admin_lastname \"${MAUTIC_ADMIN_LASTNAME:-User}\" \
    --admin_username \"${MAUTIC_ADMIN_USERNAME:-admin}\" \
    --admin_password \"${MAUTIC_ADMIN_PASSWORD}\" \
    \"${MAUTIC_URL}\"" \
    && log "[${DOCKER_MAUTIC_ROLE}]: Headless install complete." \
    || log "[${DOCKER_MAUTIC_ROLE}]: Install command returned non-zero (continuing)."
fi

if [ "${FLAVOUR}" = "apache" ]; then
  apache2-foreground
elif [ "${FLAVOUR}" = "fpm" ]; then
  php-fpm
else
  log "[${DOCKER_MAUTIC_ROLE}]: FLAVOUR not set correctly, exiting."
  exit 1
fi
