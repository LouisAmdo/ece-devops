# LAB 8 : Orchestration avec Kubernetes

## Question : Quels étaient les objectifs du lab ?
L'objectif principal était de dépasser la simple exécution d'un conteneur Docker pour apprendre à orchestrer une application à l'échelle d'un cluster. Plus précisément :
- Apprendre à déployer des applications via des Pods et des Deployments.
- Comprendre le rôle des Services pour exposer une application de manière stable.
- Expérimenter le Scaling horizontal (multiplier les instances).
- Maîtriser le cycle de vie : mise à jour automatique (Rolling Update) et retour en arrière (Rollback).
- Passer d'une gestion manuelle (commandes) à une gestion automatisée via des fichiers YAML (Infrastructure as Code).

## Question : Quelles sont les applications dans le monde réel ou en entreprise ?
En entreprise, Kubernetes est le standard pour :
- **La Haute Disponibilité** : Si un serveur tombe, Kubernetes relance automatiquement les conteneurs sur un autre nœud.
- **La gestion des pics de charge** : Pour un site e-commerce, on peut passer de 2 à 50 instances en quelques secondes lors du Black Friday.
- **Le Zero-Downtime Deployment** : Mettre à jour une application en plein milieu de la journée sans que l'utilisateur ne s'en rende compte (Rolling Update).
- **Les Microservices** : Gérer des centaines de petits services qui communiquent entre eux de manière sécurisée et isolée.

## Question : Quelles sont les étapes dans le cycle DevOps touchées (avec justification) ?
- **DEPLOY (Déploiement)** : C'est le cœur du lab. On a utilisé Kubernetes pour installer et faire tourner notre app sur un cluster.
- **OPERATE (Exploitation)** : Via le scaling, on a ajusté les ressources en temps réel pour répondre à la demande.
- **RELEASE (Mise à jour)** : Avec le Rolling Update, on a géré le passage d'une version `v1` à une version `v2` de manière fluide.
- **CONFIGURE (Configuration)** : L'utilisation des fichiers YAML permet de définir l'infrastructure sous forme de code, ce qui est une pratique DevOps fondamentale.

## Question : Quels problèmes ont été rencontrés et comment ont-ils été résolus ?
- **Problème de visibilité du Load Balancing** : Au début, le navigateur affichait toujours le même pod à cause du "Keep-Alive" (la connexion reste ouverte sur le même tunnel). Résolu en utilisant une boucle PowerShell avec `Invoke-WebRequest -DisableKeepAlive` pour forcer chaque requête à créer une nouvelle connexion et ainsi voir les différents pods répondre.
- **Échec de mise à jour (v3)** : Tentative de déploiement d'une image inexistante, ce qui a bloqué le déploiement (`ImagePullBackOff`). Résolu en utilisant la commande `kubectl rollout undo` pour revenir instantanément à la version stable précédente sans interruption de service.
- **Conflit de configuration YAML** : Un message d'avertissement est apparu car des ressources avaient déjà été créées manuellement. Résolu via un nettoyage complet avec `kubectl delete` pour repartir sur une base propre et 100% déclarative.

## Question : Quelle est la finalité du lab et êtes-vous arrivé au bout ?
La finalité était de transformer une application isolée en un système résilient et automatisé. Oui, le lab a été réalisé en intégralité. Le résultat final est une infrastructure pilotée par des fichiers YAML, capable de gérer 3 réplicas de l'application avec un accès extérieur stable sur le port 31000. Tout le travail est sauvegardé et versionné.
