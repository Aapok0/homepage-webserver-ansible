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

  vars_prompt:
    - name: server_init_admin
      prompt: Choose admin username
      private: false

    - name: server_init_admin_pass
      prompt: Enter password for the admin user
      unsafe: true
      private: true

  roles:
    - server_init
```

- Playbook will ask admin user name and a password for it
  - If first playbook run is done with root user, playbook will create admin user, but will not disable root and password login yet
    - Remember to give public ssh key with the variable `server_init_admin_pubkey`!
    - Second playbook run with the newly made admin user will disable root and password login (give the same user when prompted)
  - If you already have a user in the server with public ssh key, you can just give that user when prompted and the role will not create a new user and will disable root and password login
    - No need to run the playbook a second time unless you make changes to variables

License
-------

MIT
