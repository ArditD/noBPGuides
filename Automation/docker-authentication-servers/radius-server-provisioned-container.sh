#!/bin/bash
# This script will create a radius server docker container populated with users and groups.
# the radius "secret" is QZf7TesXVRGTsTKssEE4xcysOJxfAgZy 

mkdir radiusconfig
cd radiusconfig || exit

# Generate users file
for i in {1..400}; do
    username="raduser$i"
    password="radpwd$i"
    echo "$username Cleartext-Password := \"$password\"" >> users
done

# Generate groups file
echo "group1" >> groups
for i in {1..150}; do
    username="raduser$i"
    echo "    $username" >> groups
done

echo "group2" >> groups
for i in {151..300}; do
    username="raduser$i"
    echo "    $username" >> groups
done

echo "group3" >> groups
for i in {301..310}; do
    username="raduser$i"
    echo "    $username" >> groups
done

# Generate clients.conf file
cat > clients.conf <<EOL
client any {
    ipaddr = 0.0.0.0/0
    secret = QZf7TesXVRGTsTKssEE4xcysOJxfAgZy
}
EOL

# Generate Dockerfile
cat > Dockerfile <<EOL
FROM freeradius/freeradius-server:latest

# Copy your custom configuration files
COPY users /etc/raddb/users
COPY clients.conf /etc/raddb/clients.conf
COPY groups /etc/raddb/groups

# Expose the necessary ports
EXPOSE 1812/udp 1813/udp

# Start the RADIUS server
CMD ["radiusd", "-f", "-l", "stdout"]
EOL

# Build and load the image using buildx
docker buildx build --load -t radius-server .

docker run -d --restart=unless-stopped --name radius-server -p 1812:1812/udp -p 1813:1813/udp radius-server

sleep 10s
# Test Radius functionality
docker exec radius-server radtest raduser1 radpwd1 localhost:1812 0 QZf7TesXVRGTsTKssEE4xcysOJxfAgZy

# Remove setup files
cd - || exit 
rm -rf radiusconfig
