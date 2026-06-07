#!/bin/sh

# Init data directory
mkdir -p /app/data

# Check and generate keys
if [ ! -f "/app/data/private.key" ] || [ ! -f "/app/data/publickey.pem" ]; then
    echo "Keys not found. Generating keys (2048bit PKCS#8)..."
    # Generate PKCS#8 Private Key
    openssl genpkey -algorithm RSA -out /app/data/private.key -pkeyopt rsa_keygen_bits:2048
    # Extract Public Key
    openssl rsa -pubout -in /app/data/private.key -out /app/data/publickey.pem
    echo "Keys generated in /app/data."
else
    echo "Keys found in /app/data."
fi

# DB Initialization
MARKER_FILE="/app/data/.db_initialized"
if [ ! -f "$MARKER_FILE" ]; then
    echo "DB Initialization marker not found. Attempting to initialize DB..."

    if [ -n "$SPRING_DATASOURCE_URL" ] && [ -n "$SPRING_DATASOURCE_USERNAME" ]; then
        # Parse Host and Port from JDBC URL (jdbc:mysql://host:port/db?params)
        # Remove protocol
        PROTO_REMOVED=${SPRING_DATASOURCE_URL#jdbc:mysql://}

        # Extract Host: take substring before first ':', '/', or '?'
        DB_HOST=$(echo "$PROTO_REMOVED" | sed -e 's|:.*||' -e 's|/.*||' -e 's|?.*||')

        # Extract Port: find digits after first ':'
        # If no port specified, sed returns empty
        DB_PORT=$(echo "$PROTO_REMOVED" | sed -n 's|.*:\([0-9]*\).*|\1|p')
        if [ -z "$DB_PORT" ]; then DB_PORT=3306; fi

        # Extract DB Name
        if echo "$PROTO_REMOVED" | grep -q "/"; then
             DB_NAME_EXTRACTED=$(echo "$PROTO_REMOVED" | cut -d/ -f2- | cut -d? -f1)
        fi
        export DB_NAME="${DB_NAME_EXTRACTED:-dnf_service}"

        echo "Connecting to MySQL at $DB_HOST:$DB_PORT (User: $SPRING_DATASOURCE_USERNAME, DB: $DB_NAME)..."

        # Generate init.sql from template
        envsubst '${DB_NAME}' < /app/init.sql.template > /app/init.sql

        # Run init.sql
        # Note: We assume password is provided via env, if empty it prompts or error
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$SPRING_DATASOURCE_USERNAME" -p"$SPRING_DATASOURCE_PASSWORD" < /app/init.sql

        if [ $? -eq 0 ]; then
            echo "Database initialized successfully."
            touch "$MARKER_FILE"
        else
            echo "WARNING: Database initialization failed. Please check logs above."
            echo "Connection params: Host=$DB_HOST, Port=$DB_PORT, User=$SPRING_DATASOURCE_USERNAME"
        fi
    else
        echo "Skipping DB init: Missing SPRING_DATASOURCE_URL or USERNAME."
    fi
else
    echo "DB already initialized."
fi

# Substitute env vars in Nginx config
# We use only specific vars to avoid replacing $uri or other nginx variables
envsubst '${NGINX_PORT} ${SERVER_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start Nginx
echo "Starting Nginx..."
service nginx start

# Start Java App
echo "Starting Java Application..."
# Pass system properties if needed, though ENV vars usually suffice for Spring Boot
exec java -jar /app/app.jar
