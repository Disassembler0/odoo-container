#!/usr/bin/env python3

import os
from configparser import ConfigParser


ODOO_CONFIG_FILE = "/srv/odoo/conf/odoo.conf"


config = ConfigParser()
config.add_section("options")
config.read(ODOO_CONFIG_FILE)

options_dict = {
    "admin_passwd": os.getenv("ODOO_ADMIN_PASSWORD") or options.get("admin_passwd") or "odoo",
    "data_dir": "/srv/odoo/data",
    "db_host": os.getenv("POSTGRES_HOST") or options.get("db_host") or "localhost",
    "db_name": os.getenv("POSTGRES_DB") or options.get("db_name") or "odoo",
    "db_user": os.getenv("POSTGRES_USER") or options.get("db_user") or "odoo",
    "db_password": os.getenv("POSTGRES_PASSWORD") or options.get("db_password") or "odoo",
    "smtp_server": os.getenv("SMTP_HOST") or options.get("smtp_server") or "localhost",
    "email_from": os.getenv("SMTP_SENDER") or options.get("email_from") or "odoo@example.com",
    "http_port": "8080",
    "proxy_mode": "True",
    "list_db": "False",
}
config.read_dict({"options": options_dict})

with open(ODOO_CONFIG_FILE, "w", encoding="utf-8") as f:
    config.write(f)
