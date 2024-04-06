#!/bin/bash
# Admin PWD var 
admin_pwd="qasupeR0ot"

# Create the Dockerfile
cat <<EOT > Dockerfile
FROM quay.io/keycloak/keycloak:24.0.2 as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" \
-keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:24.0.2
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
EOT

# Create the docker-compose.yml
cat <<EOT > docker-compose.yml
services:
  postgres:
    restart: always
    image: postgres:14
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  keycloak:
    restart: always
    build:
      context: .
      dockerfile: Dockerfile
    image: keycloak-custom:24.0.2
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: "$admin_pwd"
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
      KC_HOSTNAME_STRICT: false
      KC_HTTPS_KEY_STORE_FILE: /opt/keycloak/conf/server.keystore
      KC_HTTPS_KEY_STORE_PASSWORD: password
      KC_HTTPS_PORT: 8443
      KC_HTTP_PORT: 8888
      KC_HTTP_ENABLED: true

    command: start --optimized
    ports:
      - 8443:8443
      - 8888:8888
    depends_on:
      - postgres
    volumes:
      - keycloak_data:/opt/keycloak/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8888/health"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  postgres_data:
  keycloak_data:
EOT
# Build the images with Docker Buildx
docker buildx bake -f docker-compose.yml

# Start the build
docker compose up -d

# Remove setup files
rm Dockerfile docker-compose.yml
