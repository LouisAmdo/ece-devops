# LAB : Infrastructure as Code (IaC) avec Vagrant & Ansible

## Question : Quels étaient les objectifs du lab ?
Comprendre et pratiquer l'IaC en comparant deux approches : impérative (Vagrant + Shell) et déclarative (Vagrant + Ansible). Les objectifs incluaient le provisioning de VMs, le déploiement automatisé de GitLab et la mise en place de health checks.

## Question : Quelles sont les applications dans le monde réel ou en entreprise ?
- **Vagrant** : Standardisation des environnements de développement locaux (fini le "ça marche sur ma machine").
- **Ansible** : Déploiement à grande échelle en production (utilisé par NASA, Red Hat, etc.).
- **GitLab on-premise** : Hébergement interne du code et des pipelines CI/CD sans dépendance cloud.
- **IaC en général** : Traçabilité de l'infrastructure via Git, reproductibilité et suppression des "serveurs fantômes".

## Question : Quelles sont les étapes dans le cycle DevOps touchées (avec justification) ?
Principalement les phases **Plan, Code, Deploy & Operate** :
- **Plan/Code** : Vagrantfile et playbooks Ansible = infrastructure versionnée comme du code.
- **Deploy** : `vagrant up` provisionne automatiquement l'environnement complet.
- **Operate/Monitor** : Health checks (readiness, liveness) pour surveiller l'état de GitLab.

**Justification** : L'accent est mis sur le **Deploy** car le lab démontre qu'une infrastructure entière peut être reproduite de zéro avec une seule commande, comme en production.

## Question : Quels problèmes ont été rencontrés et comment ont-ils été résolus ?
- **Conflit de port 8080** : Port déjà occupé sur la machine hôte — résolu en modifiant le `forwarded_port` dans le Vagrantfile puis en relançant `vagrant reload`.
- **Tag Ansible introuvable** : Le bon tag pour `--tags TAG` n'était pas évident — résolu en lisant attentivement le fichier `main.yml` du rôle healthcheck pour identifier le tag correct.
- **Playbook qui échoue sur SELinux** : Certaines tâches Ansible bloquaient à cause des permissions SELinux sur Rocky Linux 8 — résolu en passant temporairement en mode permissif via `setenforce 0`.

## Question : Quelle est la finalité du lab et êtes-vous arrivé au bout ?
Oui, terminé avec succès, bonus inclus. GitLab est accessible sur `http://localhost:8080`, les trois health checks (health, readiness, liveness) sont fonctionnels. Le bonus est complété : en arrêtant Redis via `sudo gitlab-ctl stop redis`, le playbook détecte automatiquement les services défaillants via l'attribut JSON de la réponse et affiche un message personnalisé listant uniquement les services en échec, grâce aux filtres Jinja2 dans Ansible.
