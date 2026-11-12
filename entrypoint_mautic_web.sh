#!/bin/bash
# Patched Mautic web entrypoint: install headlessly from env on first boot,
# otherwise run migrations, then start Apache. Replaces the stock script that
# only installs under DOCKER_MAUTIC_LOAD_TEST_DATA.
#
# "Installed" is detected by looking for a core Mautic table in the database,
# NOT by local.php — local.php is regenerated (without site_url) on every boot
# when config is not on a persistent volume, so it cannot be the signal.
source /startup/logger.sh

INSTALLED=$(php -r '
try {
  $host = getenv("MAUTIC_DB_HOST");
  $port = getenv("MAUTIC_DB_PORT") ?: 3306;
  $db   = getenv("MAUTIC_DB_DATABASE");
  $user = getenv("MAUTIC_DB_USER");
  $pass = getenv("MAUTIC_DB_PASSWORD");
  $pdo  = new PDO("mysql:host={$host};port={$port};dbname={$db}", $user, $pass,
                  [PDO::ATTR_TIMEOUT => 5]);
  $pdo->query("SELECT 1 FROM users LIMIT 1");
  echo "yes";
} catch (Throwable $e) {
  echo "no";
}
')

if [ "$INSTALLED" = "yes" ]; then
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
