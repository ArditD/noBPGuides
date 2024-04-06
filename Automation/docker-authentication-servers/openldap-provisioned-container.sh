#!/bin/bash

# Set up the variables
LDAP_ORGANISATION="QATOM"
DC_X="qatest"
DC_Y="local"
LDAP_DOMAIN="${DC_X}.${DC_Y}"
LDAP_ADMIN_PASSWORD="Ld4passw0rD"

# Initialize the group ID counter
gid_counter=1000

# Create a single LDIF file for both groups and users in the root directory
cat > openldap_setup.ldif <<EOL
dn: ou=Groups,dc=${DC_X},dc=${DC_Y}
objectClass: organizationalUnit
ou: Groups

dn: ou=People,dc=${DC_X},dc=${DC_Y}
objectClass: organizationalUnit
ou: People
EOL

# Add LDIF entries for groups
for group in proxyusers vpnusers hotspotusers group4 group5; do
  cat >> openldap_setup.ldif <<EOL

dn: cn=$group,ou=Groups,dc=${DC_X},dc=${DC_Y}
objectClass: posixGroup
cn: $group
gidNumber: $gid_counter
EOL
  # Increment the group ID counter
  gid_counter=$(( gid_counter + 1 ))

  # Assign users to groups based on the specified distribution
  case $group in
    proxyusers)
      start_index=1
      end_index=50
      ;;
    vpnusers)
      start_index=51
      end_index=100
      ;;
    hotspotusers)
      start_index=101
      end_index=150
      ;;
    group4)
      start_index=151
      end_index=200
      ;;
    group5)
      start_index=201
      end_index=250
      ;;
  esac

  for (( i = start_index; i <= end_index; i++ )); do
    user="ldapuser$i"
    echo "memberUid: $user" >> openldap_setup.ldif
  done
done

# Add LDIF entries for users
for i in $(seq 1 300); do
  user="ldapuser$i"
  cat >> openldap_setup.ldif <<EOL

dn: uid=$user,ou=People,dc=${DC_X},dc=${DC_Y}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $user
sn: $user
uid: $user
userPassword: $(slappasswd -s "LdapUsrPwd$i")
homeDirectory: /home/users/$user
loginShell: /bin/bash
gidNumber: 1000
uidNumber: $(( 1000 + i ))
EOL
done

# Pull the OpenLDAP Docker image
docker pull osixia/openldap:latest

# Create a Docker volume
docker volume create openldap-data

# Run the OpenLDAP Docker container without interactive mode for LDAP operations
docker run --detach --restart=unless-stopped --name openldap-auth --volume openldap-data:/var/lib/ldap --env LDAP_ORGANISATION="$LDAP_ORGANISATION" \
    --env LDAP_DOMAIN="$LDAP_DOMAIN" --env LDAP_ADMIN_PASSWORD="$LDAP_ADMIN_PASSWORD" -p 389:389 -p 636:636 osixia/openldap:latest

# Wait for the LDAP server to initialize (adjust sleep time as needed)
sleep 10

# Copy the LDIF file into the Docker container
docker cp openldap_setup.ldif openldap-auth:/tmp/openldap_setup.ldif

# Add the users and groups to the OpenLDAP directory without prompting for a password
docker exec openldap-auth ldapadd -x -H ldap://localhost -D "cn=admin,dc=${DC_X},dc=${DC_Y}" -w "$LDAP_ADMIN_PASSWORD" -f "/tmp/openldap_setup.ldif"

echo "OpenLDAP Docker container has been set up and populated with users and groups."

# Remove the LDIF file
rm openldap_setup.ldif
#-------------------------------------#
# If you want to test : 
#-------------------------------------#
# List all users in the 'People' organizational unit
# docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=People,dc=qatest,dc=local" "(objectClass=inetOrgPerson)"

# List all groups in the 'Groups' organizational unit
# docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=Groups,dc=qatest,dc=local" "(objectClass=posixGroup)"

# Search for a specific user (replace 'ldapuser1' with the desired username)
# docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=People,dc=qatest,dc=local" "(uid=ldapuser1)"

# Test authentication for a user (replace 'ldapuser1' with the desired username and 'LdapUsrPwd1' with the user's password)
docker exec openldap-auth ldapwhoami -x -H ldap://localhost -D "uid=ldapuser1,ou=People,dc=qatest,dc=local" -w "LdapUsrPwd1"

# Test TLS connection 
# docker exec openldap-auth ldapsearch -x -H ldaps://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=People,dc=qatest,dc=local" "(objectClass=inetOrgPerson)" -Z

# Query the users of the hotspotusers group
# docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "cn=hotspotusers,ou=Groups,dc=qatest,dc=local" "(objectClass=posixGroup)" memberUid
#-------------------------------------#
