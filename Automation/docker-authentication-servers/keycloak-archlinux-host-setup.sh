#!/bin/bash
set -e

#Variables
# Get the IP address of the VM
ip_var=$(ip route | grep default | awk '{print $9}')
admin_pwd="qasupeR0ot"

# Make sure we are up to date
pacman -Syu --noconfirm
# Install Keycloak and PostgreSQL
pacman -Sy --noconfirm keycloak postgresql

# Initialize the PostgreSQL data directory as the postgres user
sudo -u postgres initdb --locale "$LANG" -E UTF8 -D '/var/lib/postgres/data/'

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Set up PostgreSQL user and database for Keycloak
sudo -u postgres psql -c "CREATE USER keycloak WITH PASSWORD 'pgsqlpwd';"
sudo -u postgres psql -c "CREATE DATABASE keycloak OWNER keycloak;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;"

# Generate server cert
keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 \
 -dname "CN=$ip_var" -alias server -ext "SAN=DNS:localhost,IP:$ip_var" \
 -keystore /etc/keycloak/server.keystore

# Create systemd service dir
mkdir -p /etc/systemd/system/keycloak.service.d/

# Configure admin user / password and database settings
cat <<EOT > /etc/systemd/system/keycloak.service.d/admin.conf
[Service]
Environment="KEYCLOAK_ADMIN=admin"
Environment="KEYCLOAK_ADMIN_PASSWORD=$admin_pwd"
Environment="KC_HOSTNAME_STRICT=false"
Environment="KC_HTTPS_KEY_STORE_FILE=/etc/keycloak/server.keystore"
Environment="KC_HTTPS_KEY_STORE_PASSWORD=password"
Environment="KC_DB=postgres"
Environment="KC_DB_URL=jdbc:postgresql://localhost/keycloak"
Environment="KC_DB_USERNAME=keycloak"
Environment="KC_DB_PASSWORD=pgsqlpwd"
Environment="KC_HTTPS_PORT=8443"
Environment="KC_HTTP_PORT=8080"
Environment="KC_HTTP_ENABLED=true"
EOT

# Enable and start Keycloak
systemctl daemon-reload
systemctl enable keycloak
systemctl restart keycloak

exit 0
