Nginx
=========

A role that installs nginx webserver with configurations and adds apps to be hosted.
- Creates nginx user and changes ownership of all needed files and directories for nginx
- Installs nginx and its dependencies, app dependencies like nodejs, pnpm and php and certbot
- Clones apps with git, installs npm packages (if needed), builds app with npm (if needed) and copies app files to nginx vhost path
- Disables default vhost file and adds templated vhost configuration of apps to sites-available and enables the apps by creating symlink to sites-enabled
- Runs certbot to add certificate for give domains and sets up auto renewal
- Backs up default configuration file, adds templated configuration file and checks validity
- Starts nginx service

Requirements
------------

Following collections are required:
- ansible.posix
- community.general

Role Variables
--------------

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

Example Playbook
----------------

```yaml
---
- name: Nginx
  hosts: nginx
  become: true

  roles:
    - nginx
```

- If you are adding certificates, first set nginx_certs to false.
- Run nginx.yml playbook (first with check and then without, if evertyhing looks fine).
- If you are adding certificates, now set nginx_certs to true and run playbook again.

License
-------

MIT
