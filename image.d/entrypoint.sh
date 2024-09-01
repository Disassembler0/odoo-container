#!/bin/sh
set -e

if [ "$*" != "" ]; then
    exec "$@"
fi

echo "Starting Odoo..."

# Fix volume permissions
chown -R odoo:odoo /srv/odoo/conf /srv/odoo/data

# Configure Odoo
python3 /srv/odoo/conf-from-env-vars.py

# Populate database
export PGPASSWORD=${POSTGRES_PASSWORD}
DB_EXISTS=$(psql -h "${POSTGRES_HOST}" -Atc "SELECT 1 FROM res_users" "${POSTGRES_DB}" "${POSTGRES_USER}" 2>/dev/null || true)
if [ -z "${DB_EXISTS}" ]; then
    echo "Populating database..."
    su - odoo -s /bin/sh -c '/srv/odoo/odoo-bin -c /srv/odoo/conf/odoo.conf -i base --without-demo all --load-language cs_CZ' >/tmp/odoo.log 2>&1 &
    ODOO_PID=$!
    until grep -q 'odoo.modules.loading: Modules loaded.' /tmp/odoo.log; do
        if ! kill -0 ${ODOO_PID} 2>/dev/null; then
            cat /tmp/odoo.log >&2
            echo "Odoo database population process ended unexpectedly." >&2
            exit 1
        fi
        sleep 1
    done
    kill ${ODOO_PID}
    psql -h "${POSTGRES_HOST}" -Atc "UPDATE res_lang SET active = true WHERE code = 'cs_CZ'" "${POSTGRES_DB}" "${POSTGRES_USER}" >/dev/null
    psql -h "${POSTGRES_HOST}" -Atc "UPDATE res_partner SET lang = 'cs_CZ', tz = 'Europe/Prague' WHERE id = 3" "${POSTGRES_DB}" "${POSTGRES_USER}" >/dev/null
fi
# Update admin
if [ -n "${ODOO_ADMIN_PASSWORD}" ]; then
    ODOO_ADMIN_HASH=$(python3 -c "from passlib.hash import pbkdf2_sha512;print(pbkdf2_sha512.hash('${ODOO_ADMIN_PASSWORD}'))")
    psql -h "${POSTGRES_HOST}" -Atc "UPDATE res_users SET password = '${ODOO_ADMIN_HASH}' WHERE login = 'admin'" "${POSTGRES_DB}" "${POSTGRES_USER}" >/dev/null
fi
unset PGPASSWORD

# Exec into s6 supervisor
exec /bin/s6-svscan /etc/services.d
