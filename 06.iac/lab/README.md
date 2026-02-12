# Lab 6 — Infrastructure as Code (IaC)

## Overview

This lab demonstrates Infrastructure as Code (IaC) using **Vagrant** and **VirtualBox** with two approaches:

- **Imperative** (Part 1): Shell provisioning on a CentOS 7 VM
- **Declarative** (Part 2): GitLab installation via Ansible on a Rocky 8 VM
- **Health checks** (Part 3): Automated verification of GitLab services
- **Bonus**: Detection of dysfunctional services

---

## Prerequisites

- VirtualBox installed — https://www.virtualbox.org/wiki/Downloads
- Vagrant installed — https://www.vagrantup.com/downloads.html
- Vagrant box downloaded:
  ```bash
  vagrant box add centos/7       # choose virtualbox provider
  vagrant box add generic/rocky8 # choose virtualbox provider
  ```

---

## Part 1 — Imperative: Shell Provisioner

### Vagrantfile

The `part-1/Vagrantfile` defines a CentOS 7 VM with three shell provisioning steps:

1. Prints `Hello, World`
2. Adds `127.0.0.1  mydomain-1.local` to `/etc/hosts`
3. Writes the provisioning date to `/etc/vagrant_provisioned_at`

The VM is exposed on a private network at `192.168.56.10`.

### Commands

```bash
cd lab/part-1

# Create and provision the VM
vagrant up

# Check VM status
vagrant status

# SSH into the VM
vagrant ssh
```

### Expected output — `vagrant up`

```
Bringing machine 'centos_server' up with 'virtualbox' provider...
==> centos_server: Importing base box 'centos/7'...
==> centos_server: Setting the name of the VM: centos.server.local
==> centos_server: Configuring and enabling network interfaces...
==> centos_server: Running provisioner: shell...
    centos_server: Hello, World
==> centos_server: Running provisioner: shell...
    centos_server: Running: inline script
==> centos_server: Running provisioner: shell...
    centos_server: I am provisioning...
```

### Expected output — `vagrant ssh` verification

```bash
[vagrant@centos_server ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain
127.0.0.1  mydomain-1.local

[vagrant@centos_server ~]$ cat /etc/vagrant_provisioned_at
Thu Feb 12 14:30:00 UTC 2026
```

### Cleanup

```bash
vagrant halt     # stop the VM
vagrant destroy  # remove the VM
```

---

## Part 2 — Declarative: GitLab with Ansible Provisioner

### Vagrantfile

The `part-2/Vagrantfile` defines a Rocky 8 VM (`gitlab_server`) with:

- **4 GB RAM**, **2 CPUs**
- Port forwarding: guest `80` → host `8080` (bound to `127.0.0.1` only)
- Private network: `192.168.56.20`
- **`ansible_local`** provisioner: installs Ansible inside the VM and runs the `playbooks/run.yml` playbook with the `install` tag

### Ansible roles

The playbook (`playbooks/run.yml`) executes two roles:

| Role | Tag | Description |
|------|-----|-------------|
| `gitlab/install` | `install` | Installs packages, configures firewall, installs Postfix and GitLab EE |
| `gitlab/healthchecks` | `check` | Runs health, readiness, and liveness checks |

### Commands

```bash
cd lab/part-2

# Create the VM and install GitLab (takes 5-10 min)
vagrant up

# Check VM status
vagrant status
```

### Expected output — `vagrant up`

```
Bringing machine 'gitlab_server' up with 'virtualbox' provider...
==> gitlab_server: Importing base box 'generic/rocky8'...
==> gitlab_server: Setting the name of the VM: gitlab.server.local
==> gitlab_server: Configuring and enabling network interfaces...
==> gitlab_server: Running provisioner: ansible_local...
    gitlab_server: Installing Ansible...
    gitlab_server: Running ansible-playbook...

PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [gitlab_server]

TASK [gitlab/install : Install required packages] ******************************
changed: [gitlab_server]

TASK [gitlab/install : Enable and start sshd] **********************************
ok: [gitlab_server]

TASK [gitlab/install : Enable HTTP+HTTPS access] *******************************
changed: [gitlab_server] => (item=http)
changed: [gitlab_server] => (item=https)

TASK [gitlab/install : Reload firewalld] ***************************************
changed: [gitlab_server]

TASK [gitlab/install : Install postfix] ****************************************
changed: [gitlab_server]

TASK [gitlab/install : Listen only ipv4 with postfix] **************************
changed: [gitlab_server]

TASK [gitlab/install : Enable and start postfix] *******************************
changed: [gitlab_server]

TASK [gitlab/install : Download GitLab install script] *************************
changed: [gitlab_server]

TASK [gitlab/install : Execute GitLab install script] **************************
changed: [gitlab_server]

TASK [gitlab/install : Install GitLab] *****************************************
changed: [gitlab_server]

PLAY RECAP *********************************************************************
gitlab_server : ok=11  changed=9  unreachable=0  failed=0  skipped=0
```

### Test the installation

Open in browser: **http://127.0.0.1:8080**

You should see the GitLab login page. Log in with:
- **Username**: `root`
- **Password**: found inside the VM:
  ```bash
  vagrant ssh
  sudo cat /etc/gitlab/initial_root_password
  ```

---

## Part 3 — Health Checks

### Manual checks (inside the VM)

```bash
vagrant ssh

# Health check
curl http://127.0.0.1/-/health
# Output: GitLab OK

# Readiness check (detailed)
curl "http://127.0.0.1/-/readiness?all=1"
# Output: {"status":"ok","db_check":[{"status":"ok"}],"cache_check":[{"status":"ok"}],...}

# Liveness check
curl http://127.0.0.1/-/liveness
# Output: {"status":"ok"}
```

### Run with Ansible (inside the VM)

```bash
vagrant ssh

# Run the healthcheck playbook with the 'check' tag
ansible-playbook /vagrant/playbooks/run.yml \
  --tags check \
  -i /tmp/vagrant-ansible/inventory/vagrant_ansible_local_inventory
```

### Expected Ansible output

```
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Check GitLab health] *******************************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Print GitLab health] *******************************
ok: [gitlab_server] => {
    "msg": "GitLab OK"
}

TASK [gitlab/healthchecks : Check GitLab readiness] ****************************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Print GitLab readiness] ****************************
ok: [gitlab_server] => {
    "msg": {
        "status": "ok",
        "db_check": [{"status": "ok"}],
        "cache_check": [{"status": "ok"}],
        "queues_check": [{"status": "ok"}],
        "shared_state_check": [{"status": "ok"}],
        "gitaly_check": [{"status": "ok", "labels": {"shard": "default"}}]
    }
}

TASK [gitlab/healthchecks : Check GitLab liveness] *****************************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Print GitLab liveness] *****************************
ok: [gitlab_server] => {
    "msg": {
        "status": "ok"
    }
}

TASK [gitlab/healthchecks : Identify dysfunctional services] *******************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Print dysfunctional services (if any)] *************
ok: [gitlab_server] => {
    "msg": "All services are healthy!"
}

PLAY RECAP *********************************************************************
gitlab_server : ok=9  changed=0  unreachable=0  failed=0  skipped=0
```

### Health check playbook tasks

| Task | Endpoint | Response |
|------|----------|----------|
| Health check | `/-/health` | `GitLab OK` |
| Readiness check | `/-/readiness?all=1` | JSON with per-service status |
| Liveness check | `/-/liveness` | `{"status":"ok"}` |

---

## Bonus — Dysfunctional Services Detection

The bonus task adds logic in the healthchecks playbook to:

1. Parse the readiness JSON response
2. Filter services where `status != "ok"`
3. Print only the dysfunctional service names

### How to test

```bash
vagrant ssh

# Stop Redis to simulate a failure
sudo gitlab-ctl stop redis

# Run the health check playbook
ansible-playbook /vagrant/playbooks/run.yml \
  --tags check \
  -i /tmp/vagrant-ansible/inventory/vagrant_ansible_local_inventory
```

### Expected output with Redis stopped

```
TASK [gitlab/healthchecks : Check GitLab readiness] ****************************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Print GitLab readiness] ****************************
ok: [gitlab_server] => {
    "msg": {
        "status": "failed",
        "db_check": [{"status": "ok"}],
        "cache_check": [{"status": "failed", "message": "...redis.socket..."}],
        "queues_check": [{"status": "failed", "message": "...redis.socket..."}],
        "sessions_check": [{"status": "failed", "message": "...redis.socket..."}],
        "shared_state_check": [{"status": "failed", "message": "...redis.socket..."}],
        "gitaly_check": [{"status": "ok"}]
    }
}

TASK [gitlab/healthchecks : Identify dysfunctional services] *******************
ok: [gitlab_server]

TASK [gitlab/healthchecks : Print dysfunctional services (if any)] *************
ok: [gitlab_server] => {
    "msg": "WARNING: The following services are NOT healthy: cache_check, queues_check, sessions_check, shared_state_check"
}
```

### Restart Redis after testing

```bash
sudo gitlab-ctl start redis
```

---

## File Structure

```
lab/
├── README.md
├── part-1/
│   ├── Vagrantfile          # CentOS 7 VM with shell provisioning
│   └── .gitignore
└── part-2/
    ├── Vagrantfile          # Rocky 8 VM with Ansible provisioning
    ├── .gitignore
    └── playbooks/
        ├── run.yml          # Main Ansible playbook (install + check tags)
        └── roles/
            └── gitlab/
                ├── install/
                │   └── tasks/
                │       └── main.yml    # GitLab EE installation tasks
                └── healthchecks/
                    └── tasks/
                        └── main.yml    # Health, readiness, liveness + bonus
```

---

## Notes

- Port forwarding is bound to `127.0.0.1` (not `0.0.0.0`) for security.
- The VM uses a private network (`192.168.56.x`) for host-only communication.
- GitLab installation takes 5–10 minutes on first `vagrant up`.
- The `ansible_local` provisioner installs Ansible inside the guest, so it is **not** required on the host machine.
