#!/usr/bin/env python
import requests
from requests.sessions import Session
import time

# Use a session for connection pooling
session = Session()
session.verify = False  # Use with caution, only if you understand the security implications
# Disable warnings for SSL certificate verification skipping
requests.packages.urllib3.disable_warnings()

def get_access_token(keycloak_url, realm, admin_username, admin_password):
    auth_url = f"{keycloak_url}/realms/{realm}/protocol/openid-connect/token"
    auth_data = {
        'client_id': 'admin-cli',
        'username': admin_username,
        'password': admin_password,
        'grant_type': 'password',
    }
    response = session.post(auth_url, data=auth_data)
    response_data = response.json()
    access_token = response_data.get('access_token')
    expires_in = response_data.get('expires_in', 0)
    return access_token, expires_in, time.time()

def refresh_token_if_necessary(keycloak_url, realm, admin_username, admin_password, access_token, expires_in, last_refresh_time):
    current_time = time.time()
    if current_time - last_refresh_time >= expires_in - 60:  # Refresh if we're within 60 seconds of expiring
        return get_access_token(keycloak_url, realm, admin_username, admin_password)
    return access_token, expires_in, last_refresh_time

def create_group_if_not_exists(keycloak_url, realm, access_token, group_name):
    group_url = f"{keycloak_url}/admin/realms/{realm}/groups"
    headers = {'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'}
    response = session.get(group_url, headers=headers)
    
    existing_groups = [group['name'] for group in response.json()]
    if group_name in existing_groups:
        print(f"Group {group_name} already exists.")
        return

    group_data = {"name": group_name}
    response = session.post(group_url, headers=headers, json=group_data)
    if response.status_code in [200, 201]:
        print(f"Group {group_name} created successfully.")
    else:
        print(f"Failed to create group {group_name}. Response: {response.text}")

def create_user(keycloak_url, realm, access_token, username, email, password, groups=None):
    user_url = f"{keycloak_url}/admin/realms/{realm}/users"
    headers = {'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'}
    user_data = {
        "username": username,
        "email": email,
        "enabled": True,
        "credentials": [{"type": "password", "value": password, "temporary": False}],
        "firstName": "User",
        "lastName": username
    }
    if groups:
        user_data["groups"] = [f"/{group}" for group in groups]

    response = session.post(user_url, headers=headers, json=user_data)
    return response.status_code == 201

def main():
    keycloak_url = "https://localhost:8443"
    realm = "master"
    admin_username = "admin"
    admin_password = "qasupeR0ot"
    groups = ["admins", "operators", "limited", "moderators", "vpnusers", "proxyusers"]

    access_token, expires_in, last_refresh_time = get_access_token(keycloak_url, realm, admin_username, admin_password)
    
    if not access_token:
        print("Failed to get access token")
        return

    for group_name in groups:
        create_group_if_not_exists(keycloak_url, realm, access_token, group_name)

    total_users = 1500
    group_assign_limit = total_users - 100

    for i in range(1, total_users + 1):
        if i % 100 == 0:
            access_token, expires_in, last_refresh_time = refresh_token_if_necessary(
                keycloak_url, realm, admin_username, admin_password, access_token, expires_in, last_refresh_time
            )

        username = f"oauthuser{i}"
        email = f"{username}@domain.com"
        password = f"oauthpwd{i}"

        if i <= group_assign_limit:
            group_index = (i - 1) % len(groups)
            user_groups = [groups[group_index]]
            user_created = create_user(keycloak_url, realm, access_token, username, email, password, user_groups)
        else:
            user_created = create_user(keycloak_url, realm, access_token, username, email, password)

        if user_created:
            group_info = f" and assigned to group {user_groups[0]}" if i <= group_assign_limit else ""
            print(f"User {username} created{group_info} successfully.")
        else:
            print(f"Failed to create user {username}.")

if __name__ == "__main__":
    main()
