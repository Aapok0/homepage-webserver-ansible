Firewall
=========

A role that adds firewall to a server, enables/disables ipv6 and adds firewall rules.
- Doesn't remove rules yet -> need to do it manually in server

Requirements
------------

Following collections are required:
- community.general

Role Variables
--------------

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
