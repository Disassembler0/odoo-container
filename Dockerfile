FROM docker.io/alpine:3.12

RUN \
    # Update packages
    apk --no-cache upgrade && \
    # Install common packages
    apk --no-cache add libbz2 libgcc libressl libstdc++ libxml2 libxslt ncurses-libs pcre readline s6 xz-libs && \
    # Install python
    apk --no-cache add python3 py3-pip py3-wheel && \
    # Install runtime dependencies
    apk --no-cache add libffi libjpeg-turbo libpq nodejs postgresql-client ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family wkhtmltopdf && \
    # Set time zone data
    apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/UTC /etc/localtime && \
    apk --no-cache del tzdata && \
    # Set python interpret
    ln -s /usr/bin/python3 /usr/bin/python && \
    # Replace wkhtmltopdf
    # Extracted from https://github.com/Surnet/docker-wkhtmltopdf
    # wkhtmltopdf 0.12.7 is expected to support Alpine linux out of the box
    wget https://repo.spotter.cz/libwkhtmltox.tar.xz -O - | tar -xJf - -C / && \
    # Cleanup
    rm -rf /etc/crontabs/root /etc/periodic

RUN \
    # Install build dependencies
    apk --no-cache add --virtual .deps build-base git libffi-dev libjpeg-turbo-dev libxml2-dev libxslt-dev linux-headers msttcorefonts-installer openldap-dev postgresql-dev python3-dev && \
    # Update fonts
    update-ms-fonts && \
    fc-cache -f && \
    # Install Odoo
    git clone -b 14.0 --depth 1 https://github.com/odoo/odoo.git /srv/odoo && \
    cd /srv/odoo && \
    pip3 install gevent==20.9.0 --no-build-isolation && \
    pip3 install -r requirements.txt && \
    mkdir /srv/odoo/conf && \
    # Create OS user
    addgroup -S -g 8080 odoo && \
    adduser -S -u 8080 -h /srv/odoo -s /bin/false -g odoo -G odoo odoo && \
    chown -R odoo:odoo /srv/odoo && \
    # Cleanup
    apk --no-cache del .deps && \
    find /srv/odoo -name '.git*' -exec rm -rf {} + && \
    rm -rf /root/.cache

COPY image.d/srv/odoo/ /srv/odoo/
COPY image.d/etc/ /etc/
COPY image.d/entrypoint.sh /

VOLUME ["/srv/odoo/conf", "/srv/odoo/data"]
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
