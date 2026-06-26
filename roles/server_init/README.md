Server init
=========

A role that initializes server, when first taken into use.
- Adds admin user with ssh key, disables root password, password login and root login
  - Only adds admin user, if run as root or given admin name is different than ansible user
  - Does the disable tasks only when running as user other than root
  - If using existing admin user, make sure the user already has public ssh key in the server
- Updates apt cache and upgrades packages, enables/disables unattended upgrades and checks if reboot is needed
- Adds swap space, modifies it and the swappiness setting
- Sets vim as default editor

Requirements
------------

Following collections are required:
- ansible.posix
- community.general

Role Variables
--------------

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

Example Playbook
----------------

```yaml
---
- name: Server init
  hosts: servers

  roles:
    - server_init
```

Admin user/password are variables; the role prompts interactively only when needed:

- `server_init_admin` — set it in `group_vars` (recommended). If unset anywhere, the role prompts for it once.
- `server_init_admin_pass` — only used to **create** a new user. The role prompts for it **only** when a new user must be created and none was supplied. Provide it via a variable (ideally Ansible Vault) for unattended runs.
- The user is created only when you are **not** already connected as `server_init_admin` (so re-runs, or connecting as an existing key-enabled user, skip creation and never prompt for a password).
- Remember to provide the public SSH key via `server_init_admin_pubkey` when a user is created.
- Root/password login are disabled whenever you connect as a non-root user (also via the `00-hardening.conf` sshd drop-in, so it survives cloud-image defaults).

License
-------

MIT
