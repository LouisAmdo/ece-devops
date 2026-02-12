# Lab 6 - Infrastructure as Code (IaC)

## Overview

This lab demonstrates Infrastructure as Code (IaC) using both **imperative** and **declarative** approaches.  
Since this environment uses **Docker** instead of VirtualBox/Vagrant, we adapted all exercises to run with Docker and docker-compose.

---

## Part 1: Imperative - Shell Provisioning (Docker equivalent)

### Description

Instead of using Vagrant with a CentOS 7 VM, we use a Docker container based on the `centos:7` image.  
The Dockerfile replicates the shell provisioning steps from the Vagrantfile:

1. **Hello, World** - echoed on container start
2. **`/etc/hosts` modification** - adds `127.0.0.1 mydomain-1.local`
3. **Provisioning timestamp** - writes the date to `/etc/vagrant_provisioned_at`

### How to run

```bash
cd 06.iac/lab/part-1

# Build and start (equivalent to `vagrant up`)
docker-compose up -d --build

# Check the container is running (equivalent to `vagrant status`)
docker-compose ps

# Enter the container (equivalent to `vagrant ssh`)
docker exec -it centos.server.local bash

# Inside the container, verify provisioning:
cat /etc/hosts
# You should see: 127.0.0.1  mydomain-1.local
cat /etc/vagrant_provisioned_at
# You should see the provisioning date

# Stop the container (equivalent to `vagrant halt`)
docker-compose stop

# Destroy the container (equivalent to `vagrant destroy`)
docker-compose down
```

### Verification

```
$ docker exec centos.server.local cat /etc/hosts
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
...
127.0.0.1  mydomain-1.local

$ docker exec centos.server.local cat /etc/vagrant_provisioned_at
Wed Feb 12 13:30:00 UTC 2026
```

---

## Part 2: Declarative - GitLab Installation (Docker equivalent)

### Description

Instead of using Vagrant + Ansible to install GitLab on a Rocky 8 VM, we use the official `gitlab/gitlab-ee` Docker image.  
This achieves the same result: a running GitLab instance accessible on `http://localhost:8080`.

The `docker-compose.yml` replicates the Vagrant configuration:
- **Port forwarding**: guest 80 → host 8080 (same as Vagrantfile)
- **Resources**: 4096 MB RAM, 2 CPUs (same as Vagrantfile)
- **Ansible playbooks**: mounted at `/vagrant/playbooks` for reference

### How to run

```bash
cd 06.iac/lab/part-2

# Build and start GitLab (equivalent to `vagrant up`)
docker-compose up -d

# Check status
docker-compose ps

# Wait 5-10 minutes for GitLab to initialize, then check health:
docker exec gitlab.server.local curl -s http://127.0.0.1/-/health
# Expected: GitLab OK

# Access GitLab in browser
# Open: http://localhost:8080

# Get the initial root password:
docker exec gitlab.server.local cat /etc/gitlab/initial_root_password | grep Password:

# Stop GitLab (equivalent to `vagrant halt`)
docker-compose stop

# Destroy GitLab (equivalent to `vagrant destroy`)
docker-compose down -v
```

### Verification

```
$ curl http://localhost:8080/-/health
GitLab OK

$ curl http://localhost:8080/-/readiness
{"status":"ok","master_check":[{"status":"ok"}]}

$ curl http://localhost:8080/-/liveness
{"status":"ok"}
```

---

## Part 3: Health Checks

### Description

The health check playbook (`playbooks/roles/gitlab/healthchecks/tasks/main.yml`) implements **three** types of health checks using the Ansible `uri` module:

1. **Health check** (`/-/health`) — basic "GitLab OK" response
2. **Readiness check** (`/-/readiness`) — verifies all sub-services (db, redis, cache, etc.)
3. **Liveness check** (`/-/liveness`) — confirms the application is alive

### Running health checks manually (inside the container)

```bash
# Health check
docker exec gitlab.server.local curl -s http://127.0.0.1/-/health
# Output: GitLab OK

# Readiness check
docker exec gitlab.server.local curl -s http://127.0.0.1/-/readiness
# Output: {"status":"ok","master_check":[{"status":"ok"}]}

# Liveness check
docker exec gitlab.server.local curl -s http://127.0.0.1/-/liveness
# Output: {"status":"ok"}
```

### Running with Ansible (inside the container)

```bash
# Install Ansible inside the container
docker exec gitlab.server.local bash -c "yum install -y ansible || apt-get install -y ansible"

# Run the health check playbook
docker exec gitlab.server.local ansible-playbook /vagrant/playbooks/run.yml --tags check -c local -i "localhost,"
```

### Health check playbook tasks

| Task | Endpoint | Purpose |
|------|----------|---------|
| `Check GitLab health` | `/-/health` | Returns "GitLab OK" if the app is running |
| `Check GitLab readiness` | `/-/readiness` | JSON response with status of all sub-services |
| `Check GitLab liveness` | `/-/liveness` | JSON response confirming the app process is alive |

---

## Bonus: Dysfunctional Services Detection

### Description

The bonus task adds two extra Ansible tasks to the health check playbook:

1. **Identify dysfunctional services** — parses the readiness JSON response and filters services where `status != 'ok'`
2. **Print dysfunctional services** — displays a warning with the list of broken services, or "All services are healthy!" if everything is OK

### Testing with a stopped Redis service

```bash
# Stop Redis to simulate a failure
docker exec gitlab.server.local gitlab-ctl stop redis

# Run readiness check — should show redis as dysfunctional
docker exec gitlab.server.local curl -s http://127.0.0.1/-/readiness
# Output will show redis_check with status "failed"

# Restart Redis
docker exec gitlab.server.local gitlab-ctl start redis
```

### Expected Ansible output (bonus task)

When all services are healthy:
```
TASK [gitlab/healthchecks : Print dysfunctional services (if any)] ************
ok: [localhost] => {
    "msg": "All services are healthy!"
}
```

When Redis is stopped:
```
TASK [gitlab/healthchecks : Print dysfunctional services (if any)] ************
ok: [localhost] => {
    "msg": "WARNING: The following services are NOT healthy: redis_check"
}
```

---

## File Structure

```
lab/
├── part-1/
│   ├── Vagrantfile              # Original Vagrant config (imperative)
│   ├── Dockerfile               # Docker equivalent
│   ├── docker-compose.yml       # Docker Compose to manage the container
│   └── .gitignore
├── part-2/
│   ├── Vagrantfile              # Original Vagrant config (declarative)
│   ├── docker-compose.yml       # Docker equivalent with GitLab
│   ├── .gitignore
│   └── playbooks/
│       ├── run.yml              # Main Ansible playbook
│       └── roles/
│           └── gitlab/
│               ├── install/
│               │   └── tasks/
│               │       └── main.yml    # GitLab installation tasks
│               └── healthchecks/
│                   └── tasks/
│                       └── main.yml    # Health, readiness, liveness checks + bonus
```

---

## Tools Used

| Tool | Purpose |
|------|---------|
| Docker | Container runtime (replaces VirtualBox) |
| Docker Compose | Container orchestration (replaces Vagrant) |
| Ansible | Declarative configuration management |
| GitLab EE | Self-hosted Git platform |
| curl | HTTP health check testing |

---

## Author

ECE DevOps Lab 6 - Infrastructure as Code
