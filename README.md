# Rapport de Lab : Infrastructure as Code (IaC)

**Sujet :** Provisionnement impératif et déclaratif avec Vagrant et Ansible  
**Auteurs :**Amedeo Louis & Benatar Arthur 
**Date :** 12 Février 2026

---

## 1. Objectifs du Lab
L’objectif de ce travail est de maîtriser la gestion d'infrastructures virtuelles via deux approches :
* **Impérative :** Configuration manuelle d'une machine CentOS 7 via des scripts Shell.
* **Déclarative :** Automatisation de l'installation de GitLab sur Rocky Linux 8 avec Ansible.
* **Monitoring :** Configuration de tests de santé (Health Checks) pour surveiller les services.

---

## 2. Préparation de l'environnement
L'environnement a été initialisé avec Vagrant version 2.4.9. La box `centos/7` a été ajoutée pour le fournisseur VirtualBox.

![Installation Vagrant et Box](image/image.png)

---

## 3. Part 1 : Approche Impérative (Vagrant & Shell)

### 3.1 Création de la VM
La machine `centos_server` a été lancée avec la commande `vagrant up`. Le provisionnement Shell a affiché le message "Hello, World".

![Vagrant Up Initial](image/image1.png)

### 3.2 Configuration du fichier hosts
Le `Vagrantfile` a été modifié pour ajouter la ligne `127.0.0.1 mydomain-1.local` dans `/etc/hosts`.

![Modification etc/hosts](image/image2.png)

### 3.3 Provisionnement de la date
Un script a été injecté pour enregistrer la date de provisionnement dans `/etc/vagrant_provisioned_at`.

![Fichier provisioned_at](image/image3.png)

---

## 4. Part 2 : Approche Déclarative (GitLab & Ansible)

### 4.1 Installation automatisée
Nous avons utilisé le provisionneur `ansible_local` pour installer GitLab sur une box Rocky Linux 8. Le Playbook Ansible a exécuté les tâches d'installation avec succès.

![Exécution Playbook GitLab](image/image4.png)

### 4.2 Test de l'interface
GitLab a été configuré sur le port 8080. Voici l'interface de connexion après le déploiement.

![Interface GitLab](image/image5.png)

---

## 5. Part 3 : Health Checks pour GitLab

### 5.1 Vérification de santé
Un test manuel via `curl` a été effectué, suivi de l'automatisation des tests de **Readiness** et **Liveness** dans le rôle Ansible.

![Tests de santé OK](image/image6.png)
![Résultats JSON Health](image/image7.png)

---

## 6. Bonus Task : Diagnostic de panne

Le but était de lister les services dysfonctionnels en cas de panne de Redis.
1. **Simulation :** Arrêt manuel de Redis avec `sudo gitlab-ctl stop redis`.
2. **Diagnostic :** Le Readiness check passe en `failed` et Ansible liste les services KO.

![Arrêt de Redis](image/image8.png)
![Analyse des logs de panne](image/image9.png)
![Affichage final du Bonus](image/image10.png)
![Récapitulatif final](image/image11.png)

---

## 7. Conclusion
Le lab a démontré l'efficacité du mode déclaratif. Ansible permet non seulement de déployer une application lourde comme GitLab, mais aussi d'assurer une surveillance précise de son état interne.

**État du projet :** Terminé ✅