Firewall
=========

A role that adds firewall to a server, enables/disables ipv6 and adds firewall rules.
- Doesn't remove rules yet -> need to do it manually in server
- SSH is allowed only on the Tailscale interface (`tailscale0`) by default; run the `tailscale` role first.

Requirements
------------

Following collections are required:
- community.general

Role Variables
--------------

```yaml
# Whether IPV6 is disables in the server, default is false
firewall_disable_ipv6: true
# SSH only over the Tailscale interface (default); false falls back to firewall_allowed_ips
firewall_ssh_over_tailscale_only: true
firewall_ssh_interface: tailscale0
# Fallback SSH allowlist (only used when firewall_ssh_over_tailscale_only is false).
# Generated from Terraform's admin_allowed_ips (see repo README), not set by hand.
firewall_allowed_ips:
  - 213.213.213.213
# Which ports are open, removing won't remove rules (need to do it manually)
firewall_ufw_rules:
  - port: 80
    proto: tcp
  - port: 443
    proto: tcp
```

Example Playbook
----------------

```yaml
---
- name: Firewall
  hosts: servers
  become: true

  roles:
    - firewall
```

License
-------

MIT
