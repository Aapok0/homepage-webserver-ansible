# Ansibles to setup an Nginx webserver for my homepage

The main purpose of this Ansible project is to deploy and manage an Nginx webserver for my homepage. The VM that the webserver is deployed to is hosted in Azure and the resources to it are being managed with Terraforms.

The way the roles have been written is a compromise between between the needs of my project and wanting to write reusable Ansible code. The roles could have more features and configurability, but any more would be unnecessary for my needs. The way certbot works with the nginx role as a whole could be much improved and there's some extra steps that required to run it, which are explained in [Usage](#Usage).

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Azure Terraform architecture](https://github.com/Aapok0/azure-tf-architecture)

## Configuration

For the servers you want to run Ansibles to you need to create inventory file (or multiple) under inventory directory like for example `inventory/production` with the following group names (ansible_user optional, but useful):

```ini
[servers]
123.123.123.123 ansible_user=user_here
111.111.111.111 ansible_user=user_here

[nginx]
123.123.123.123 ansible_user=user_here
```

Variables for the roles can be configured in files in either host_vars or group_vars directories. The host_vars files need to be named the same as the hosts and they define variables for that host only. The group_vars are named after the inventory groups and I use them in my project. The roles have the following variables.

server_init:

```yaml
# If you want to create a new admin user, defaults to <user_home>/.ssh/id_rsa.pub
server_init_admin_pubkey: /path/to/ssh_pubkey
# Extra packages you want, by default following are installed: cron, curl, git, grep, less, rsync, unattended-upgrades and vim
server_init_extra_packages:
  - fzf
  - htop
  - ncdu
  - ripgrep
  - tmux
# Whether unattended-upgrades is enabled, default is true
server_init_auto_upgrades: true
# Swap space you need in the server in bytes
server_init_swapfile_size: 1500000000
# Tendency to move processes from physical memory to swap space
server_init_swappiness: 60
```

firewall:

```yaml
# Whether IPV6 is disables in the server, default is false
firewall_disable_ipv6: true
# Which IPs are allowed to ssh in to the server, default is any to not lose access, if variable is not set
firewall_allowed_ips:
  - 213.213.213.213
# Which ports are open, removing won't remove rules (need to do it manually)
firewall_ufw_rules:
  - port: 80
    proto: tcp
  - port: 443
    proto: tcp
```

nginx:

```yaml
---
# Configuration -> most of the following are the default values
nginx_user: nginx
nginx_worker_processes: auto

## Configuration - Events
nginx_worker_connections: 1024
nginx_events_use: epoll # if not set, nginx will set according to server's OS
nginx_events_multi_accept: 'on'

## Configuration - HTTP
### HTTP - Basic Settings
nginx_sendfile: 'on'
nginx_sendfile_max_chunk: 2m
nginx_tcp_nopush: 'on'
nginx_types_hash_max_size: 1024
nginx_server_tokens: 'on'
nginx_server_name_in_redirect: 'on'
server_names_hash_bucket_size # if not set, nginx will set default according to server
nginx_default_type: application/octet-stream

### SSL Settings
nginx_ssl_protocols: 'TLSv1.2 TLSv1.3'
nginx_ssl_prefer_server_ciphers: 'on'
nginx_ssl_ciphers: 'HIGH:!aNULL:!MD5' # if not set, nginx will set default

### Logging Settings
nginx_error_debug_level: error

### Gzip Settings
nginx_gzip: 'on'
nginx_gzip_vary: 'off'
nginx_gzip_proxied: 'off' # if not set, nginx will set default
nginx_gzip_comp_level: 1
nginx_gzip_buffers: '16 8k'
nginx_gzip_http_version: 1.1
nginx_gzip_types: 'text/html text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript'

# Vhost
nginx_certs: true # Should be set false for first run to generate valid nginx config
nginx_domains:
  - www.example.com # First in the list will be used as main domain
  - example.com # The rest of the domains will be redirected to main domain
nginx_cert_email: name@example.com
nginx_listen_ipv6: false
nginx_apps:
  - name: example
    main: true # App that will be served when using root of the domain
    repo: https://github.com/Aapok0/homepage.git
    location: example # Path of app -> www.example.com/example/
    npm: true # The tasks use pnpm
    sass: true
    php: true
    build_command: css-build # pnpm build command
  - name: example2
    main: false
    repo: https://github.com/Aapok0/homepage-bulma.git
    location: example2 # Path of app -> www.example.com/example2/
    npm: false
    sass: false
    php: true
```

## Usage

### Required collections

- ansible.posix
- community.general

```bash
ansible-galaxy collection install <collection>
```

### Steps

```bash
# Requires Ansible version 2.15.3 or above and collections above

# Clone repository, add inventory and configure to your liking

# Run server_init.yml playbook (first with check and then without, if evertyhing looks fine)
# Playbook will ask for admin user name and password (need to have admin other than root)
# If given name is the same as ansible user, then user is not created -> make sure the user has ssh public key in server already
ansible-playbook -i inventory/inventory_file server_init.yml --diff --check
ansible-playbook -i inventory/inventory_file server_init.yml --diff

# If you are adding certificates, first set nginx_certs to false
# Run nginx.yml playbook (first with check and then without, if evertyhing looks fine)
ansible-playbook -i inventory/inventory_file nginx.yml --diff --check
ansible-playbook -i inventory/inventory_file nginx.yml --diff

# If you are adding certificates, now set nginx_certs to true and run playbook again
ansible-playbook -i inventory/inventory_file nginx.yml --diff
```
