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
![Vagrant Up](images-screens/Vagrant%20Up.jpg)
![Vagrant Provision](images-screens/Vagrant%20Provision.jpg)

# Check VM status
vagrant status
![Vagrant Status](images-screens/Vagrant%20Status.jpg)

# SSH into the VM
vagrant ssh
![Vagrant SSH](images-screens/Vagrant%20ssh.jpg)
```

![Cat Etc Hosts](images-screens/cat%20etc%20hosts.jpg)


### Cleanup

```bash
vagrant halt     # stop the VM
vagrant destroy  # remove the VM
```

![Vagrant Halt](images-screens/vagrant%20halt.jpg)
![Vagrant Destroy](images-screens/Vagrant%20Destroy.jpg)


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

# Upload playbooks (if needed)
# vagrant upload playbooks
![Vagrant Upload Playbooks](images-screens/vagrant%20upload%20playbooks.jpg)

# Create the VM and install GitLab (takes 5-10 min)
vagrant up
![Vagrant Provision 2](images-screens/vagrant%20provision-2.jpg)

# Check VM status
vagrant status
![Vagrant Status 2](images-screens/Vagrant%20status%202.jpg)
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
  ![Vagrant SSH 2](images-screens/vagrant%20ssh%202.jpg)

![GitLab UI](images-screens/GitLab%20UI%20Proof%20Working.png)


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
![Curl Health](images-screens/curl%20health.jpg)

### Run with Ansible (inside the VM)

```bash
vagrant ssh

# Run the healthcheck playbook with the 'check' tag
ansible-playbook /vagrant/playbooks/run.yml \
  --tags check \
  -i /tmp/vagrant-ansible/inventory/vagrant_ansible_local_inventory
```

![Vagrant Provision 3](images-screens/vagrant%20provision%203.jpg)

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
![Ansible Playbook Tag](images-screens/ansible%20playbook%20tag.jpg)

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
