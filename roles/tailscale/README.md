Tailscale
=========

Installs Tailscale and joins the host to your tailnet, so SSH can be reached
over the private mesh instead of a public IP. Pairs with the `firewall` role,
which (by default) only allows SSH on the `tailscale0` interface.

Requirements
------------

- A key for joining the tailnet. Use an **OAuth client secret** (admin console →
  Settings → OAuth clients) if you want a node whose key never expires — plain
  auth keys always expire. Store it in Key Vault.
- OAuth client secrets require advertised **tags**, so set `tailscale_tags`, and
  define/grant that tag in the tailnet ACL policy.

Role Variables
--------------

```yaml
# Pull the key from Key Vault via the az CLI when set; else use $TAILSCALE_AUTHKEY
tailscale_kv_name: ''
tailscale_secret_name: homepage-tailscale-oauthkey
tailscale_authkey: "<resolved from KV or env, see defaults/main.yml>"
# REQUIRED for OAuth client secrets, e.g. ['tag:server']
tailscale_tags: []
# MagicDNS hostname; empty uses the machine hostname
tailscale_hostname: ''
# Extra `tailscale up` flags (list), e.g. ['--ssh']
tailscale_up_extra_args: []
# apt repo codename (24.04 = noble)
tailscale_ubuntu_codename: noble
```

The key is pulled on the control node with `az keyvault secret show` (you must be
`az login`'d), avoiding a manual export and the heavier `azure.azcollection`.

Example Playbook
----------------

```yaml
---
- name: Tailscale
  hosts: servers
  become: true

  roles:
    - tailscale
```

Notes
-----

- The role is idempotent: it only runs `tailscale up` when the host is not
  already connected.
- After the first join, disable key expiry for the node in the admin console so
  it does not drop off the tailnet.
- Recovery if the tailnet is unreachable: use the Azure Serial Console or
  `az vm run-command invoke`.

License
-------

MIT
