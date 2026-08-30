# netbox-deploy

No Terraform for this one — you create the VM in Proxmox yourself
(clone your VM9000 template, set IP/VLAN by hand), then run one script.
That script bootstraps Ansible and triggers the first pull; the pull
itself installs a systemd timer so the box owns its own recurring
schedule from then on — you never touch this VM's automation again after
the first run.

## Repo layout

Push everything under here to a new GitHub repo (`config-mgmt` or
similar) — public, per your call, no per-host git auth needed:

- `bootstrap.sh` — the one-time script you run on a fresh VM
- `local.yml` — the ansible-pull entrypoint (runs `bootstrap` role, then `netbox`)
- `roles/bootstrap/` — installs the self-recurring systemd timer
- `roles/netbox/` — the actual NetBox install (Docker + netbox-docker + vaulted secrets)
- `group_vars/all/vars.yml` — non-secret config (repo URL, NetBox settings)
- `group_vars/all/vault.yml.example` — template for the secrets file

## One-time setup (do this before touching any VM)

1. Generate your vault password and remember it — you'll type it into
   every new host's bootstrap run:
   ```
   openssl rand -base64 32
   ```
2. Create the real secrets file and encrypt it:
   ```
   cp group_vars/all/vault.yml.example group_vars/all/vault.yml
   # edit vault.yml — SECRET_KEY via `openssl rand -base64 45`, real passwords
   ansible-vault encrypt group_vars/all/vault.yml
   # (it'll prompt for the password — use the one from step 1)
   ```
3. Edit `group_vars/all/vars.yml` — set `config_repo_url` to your real repo URL.
4. Push it all to GitHub.

## Per-VM flow, from here on

1. Clone VM9000 in Proxmox, set hostname/IP/VLAN by hand, boot it.
2. SSH in as root, run:
   ```
   curl -fsSL https://raw.githubusercontent.com/<you>/config-mgmt/main/bootstrap.sh | bash
   ```
   It'll prompt for the vault password once — type it, hit enter, done.
3. Confirm the timer's running: `systemctl status ansible-pull.timer`
4. NetBox should be reachable at `http://<vm-ip>:8000` a minute or two later.

That's the whole loop. New service later = new role in this repo + a line
in `local.yml`; existing hosts pick it up on their next scheduled pull
automatically, no re-running anything by hand.

## Still not in here

- No TLS/reverse proxy — raw HTTP on :8000 for now, put it behind Traefik
  when ready.
- No Healthchecks.io ping in the timer yet — worth adding once you're
  confident in the base loop; the service unit is the natural place to
  append the ping command.
