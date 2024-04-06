## What is this?
These is an extract of a test-automation project (geared towards the test environment condition) containing some bash/python scripts to set up different types of pre-provisioned (i.e including users and groups)  \
authentication servers (radius,. openldap, samba [ad - dc] , keycloak) on a Linux based environment for test automation purposes. \
The script are tested and robust using mainstream containers (openldap, radius) and methods (docker buildx instead of the deprecated docker build).

## How do I use it if I want to build the script?
- RTM, system pre-requisites and the documentation related to che container you want to build
- Run the script on a VM or on a host.

## System pre-requisites

- The VM Should have docker already setup up / runing
- The VM has systemd-timesyncd enabled by default with your timezone
- All containers are built with docker buildx instead of the deprecated docker build (make sure docker buildx is available on your system)
- openldap and jq should also be installed on the system
- Radius server automated on a docker container
- OpenLDAP server with support for both ldap and ldaps automated on a docker container
- Keycloak for Oauth2 which comes in 2 flavors 
    - Host installation (for better performance and integration) on Arch Linux
    - Docker container - in case you want it on a docker container edit arch-authentication.pkr.hcl accordingly (check provisioning section).

TODO: 
- Samba providing Active Directory and Domain controller services (plus the rest of file-sharing , etc) automated on a docker container

# Radius Server Container Details
The radius container provides the following services : 
- Radius server listening on port 1812 1813 UDP
- Radius secret is set to QZf7TesXVRGTsTKssEE4xcysOJxfAgZy
- It accepts requests from all IP's so regardless of the IP of the DUT, it will accept the requests
- It has 400 users of this format : 
  - raduser1, raduser2, raduserN  and each user has a password of this format : 
  - radpwd1, radpwd2, radpwdN
- It has 3 groups : group1, group2, group3
  - group1 has 150 users from raduser1 - raduser 150
  - group2 has 150 users from raduser151 - raduser 300
  - group3 has 10 users from raduser301 - raduser 310
- The last 90 users from the total 400 are not assigned to any group

### CLI commands to interact with the container : 
```
# "tail -f" the logs of the container
docker logs -f radius-server  

# log inside the container
docker exec -it radius-server bash 

# Test Radius functionality
docker exec radius-server radtest raduser1 radpwd1 localhost:1812 0 QZf7TesXVRGTsTKssEE4xcysOJxfAgZy

# Monitor radius traffic on the VM
sudo tcpdump -nnvvi ens18 udp and port 1812 or port 1813
```

# OpenLDAP Server container details
- Listening on port 389 (LDAP) and 636 (LDAPs) TCP
- Main credentials : admin / Ld4passw0rD
- There's a total of 5 groups (vpnusers, proxyusers, hotspotusers, group4, group5 )
- there's a total of 300 users, where the first 250 are assigned to the groups and the last are not assigned to any group
- The username / password format is ldapuserN / LdapUsrPwdN where N is the number of the user
- The provisioning is done through the import of openldap_setup.ldif

## Configuration on The Backend Side (example)
- LDAP server type : OpenLDAP
- LDAP bind DN username : cn=admin,dc=qatest,dc=local
- LDAP bind DN password : Ld4passw0rD
- LDAP user base DN : ou=People,dc=qatest,dc=local
- LDAP group base DN  : ou=Groups,dc=qatest,dc=local 

### Quick tests / container side : 
```
# "tail -f" the logs of the container
docker logs -f openldap-auth 

# log inside the container
docker exec -it openldap-auth bash 

# List all users in the 'People' organizational unit
docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=People,dc=qatest,dc=local" "(objectClass=inetOrgPerson)"

# List all groups in the 'Groups' organizational unit
docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=Groups,dc=qatest,dc=local" "(objectClass=posixGroup)"

# Search for a specific user (replace 'ldapuser1' with the desired username)
docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=People,dc=qatest,dc=local" "(uid=ldapuser1)"

# Test authentication for a user (replace 'ldapuser1' with the desired username and 'LdapUsrPwd1' with the user's password)
docker exec openldap-auth ldapwhoami -x -H ldap://localhost -D "uid=ldapuser1,ou=People,dc=qatest,dc=local" -w "LdapUsrPwd1"

# Test TLS connection 
docker exec openldap-auth ldapsearch -x -H ldaps://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "ou=People,dc=qatest,dc=local" "(objectClass=inetOrgPerson)" -Z

# Query the users of the hotspotusers group
docker exec openldap-auth ldapsearch -x -H ldap://localhost -D "cn=admin,dc=qatest,dc=local" -w "Ld4passw0rD" -b "cn=hotspotusers,ou=Groups,dc=qatest,dc=local" "(objectClass=posixGroup)" memberUid

```

# Keycloak Host and Docker Setup
Keycloak comes in 2 flavors, a host setup geared for Arch linunx which will set up also a postgresql DB, and of course also a docker container.

- The host version will be listening after the setup on port 8443 (https) and 8080 (http)
- The docker version uses 8888 for the http instead of 8080, https is 8443
- The container version is pinned on keycloak 24.02 (latest version at this moment)
- To login use admin / qasupeR0ot
- After the host or container (depnedning on your pick) is up and running you can provision using the keycloak-provisioning.py python3 script which uses the newest API (so don't use it on older versions of keycloak) and will :
    - Creae 1500 users
    - Randomly assign those users to 6 predefined groups
    - last 100 users are not assigned to any group
