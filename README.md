# Ansibles to setup an Nginx webserver for my homepage

The VM that the webserver is deployed to is hosted in Azure (**azure-tf-architecture**) on **Ubuntu 24.04 LTS** with **PHP 8.3** (php-fpm). Pin the image version in Terraform; PHP package names are set in the nginx role defaults (`nginx_php_fpm_package`).

The way the roles have been written is a compromise between between the needs of my project and wanting to write reusable Ansible code. The roles could have more features and configurability, but any more would be unnecessary for my needs. The way certbot works with the nginx role as a whole could be much improved and there's some extra steps that required to run it, which are explained in [Usage](#Usage).

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Azure Terraform architecture](https://github.com/Aapok0/azure-tf-architecture)

## Configuration

Committed templates (copy and edit locally; real files stay gitignored):

| Template | Copy to |
|----------|---------|
| `inventory/production.example` | `inventory/production` |
| `group_vars/servers.example.yml` | `group_vars/servers.yml` |
| `group_vars/nginx.example.yml` | `group_vars/nginx.yml` |

### Terraform handoff

After `terraform apply` in the **azure-tf-architecture** repository:

> **Placeholders:** IP addresses like `203.0.113.x` in this README and in `*.example` files are [RFC 5737 documentation addresses](https://datatrfc.ietf.org/doc/html/rfc5737) — not real public IPs. Replace them with your VM IP and home IP after deploy.

1. **VM IP** — in **azure-tf-architecture**, run `terraform output public_ip_info_out` (e.g. `webserver: 203.0.113.20` in docs only → use your actual IP in **homepage-webserver-ansible** `inventory/production`).
2. **ansible_user** — generated per VM; run `terraform output admin_user_out` or use `./scripts/sync-ansible-inventory.sh` after apply (reads **azure-tf-architecture** `ansible_hosts_out`).
3. **SSH allowlist** — `firewall_allowed_ips` in **homepage-webserver-ansible** `group_vars/servers.yml` must match NSG `source_address_prefixes` for `ssh` and `ping` in **azure-tf-architecture** `project.auto.tfvars`.
4. **DNS** — **azure-tf-architecture** creates the Azure DNS zone and A records; point your registrar nameservers at Azure if not already done.
5. **Certificates** — `nginx_cert_email` in **homepage-webserver-ansible** `group_vars/nginx.yml`; domains must resolve to the VM before `nginx_certs: true`.

After `terraform apply`, sync inventory from the **azure-tf-architecture** repository (rewrites managed inventory files; removes hosts no longer in state):

```bash
cd azure-tf-architecture
./scripts/sync-ansible-inventory.sh
./scripts/sync-ssh-config.sh   # optional: replaces terraform-managed ~/.ssh/config blocks only
```

`sync-ansible-inventory.sh` regenerates `inventory/development`, `inventory/test`, and `inventory/production` every run. `sync-ssh-config.sh` strips blocks between `# BEGIN terraform-managed:` / `# END terraform-managed:` markers and rewrites them from state; other SSH config entries are left alone.

Set `ANSIBLE_REPO` if **homepage-webserver-ansible** is not a sibling directory.

### Inventory

For the servers you want to run Ansible against, create an inventory file under `inventory/` (for example `inventory/production`) with these groups. Use your real VM IP — not the placeholder below:

```ini
[servers]
203.0.113.20 ansible_user=your_admin_user

[nginx]
203.0.113.20 ansible_user=your_admin_user
```

Variables for the roles go in `group_vars/` named after inventory groups (`servers`, `nginx`). See the `*.example.yml` files for a working homepage setup. The roles also support the following variables.

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
nginx_server_tokens: 'off'
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
nginx_security_headers_enabled: true
nginx_security_headers_hsts: 'max-age=31536000; includeSubDomains'
nginx_security_headers_csp: "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; font-src 'self'; frame-ancestors 'none'"
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

Install pinned collections from `requirements.yml`:

```bash
ansible-galaxy collection install -r requirements.yml
```

Collections: `ansible.posix`, `community.general`

### Steps

```bash
# Requires Ansible version 2.15.3 or above and collections above

# Clone repository, install collections, copy *.example files (see Configuration)

cp inventory/production.example inventory/production
cp group_vars/servers.example.yml group_vars/servers.yml
cp group_vars/nginx.example.yml group_vars/nginx.yml
# Edit inventory IP, firewall_allowed_ips, nginx_cert_email

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
