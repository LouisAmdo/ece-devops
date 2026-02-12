# Docker equivalent of the Vagrant CentOS 7 VM for Part 1
# This replaces the Vagrantfile approach since we use Docker instead of VirtualBox
# Using Rocky Linux 8 (CentOS 7 mirrors are EOL) - Rocky 8 is the same RHEL family
FROM rockylinux:8

# Install basic tools
RUN dnf install -y \
    curl \
    openssh-server \
    net-tools \
    vim \
    && dnf clean all

# Part 1 - Step 4.2: Print provisioning date
RUN echo "I am provisioning..." && \
    date > /etc/vagrant_provisioned_at

# Create an entrypoint script that handles runtime provisioning
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'echo "=== Hello, World ==="' >> /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    echo '# Part 1 - Step 4.1: Configure /etc/hosts (done at runtime)' >> /entrypoint.sh && \
    echo 'echo "127.0.0.1  mydomain-1.local" >> /etc/hosts' >> /entrypoint.sh && \
    echo 'echo "=== /etc/hosts content ==="' >> /entrypoint.sh && \
    echo 'cat /etc/hosts' >> /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    echo 'echo "=== Provisioned at ==="' >> /entrypoint.sh && \
    echo 'cat /etc/vagrant_provisioned_at' >> /entrypoint.sh && \
    echo 'echo ""' >> /entrypoint.sh && \
    echo 'echo "Container is ready. Use docker exec -it centos.server.local bash to connect."' >> /entrypoint.sh && \
    echo 'tail -f /dev/null' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
