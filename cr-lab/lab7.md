# LAB : Docker et la Conteneurisation

## Question : Quels étaient les objectifs du lab ?
Les objectifs principaux étaient de comprendre et de maîtriser les fondamentaux de la conteneurisation. Cela incluait l'installation de Docker, la création d'images personnalisées via un `Dockerfile`, la gestion du cycle de vie des conteneurs (build, run, stop, logs), le partage d'images sur un registre public (Docker Hub) et l'orchestration de plusieurs services dépendants (Node.js et Redis) avec Docker Compose. Un point clé était aussi l'apprentissage de la persistance des données via les volumes.

## Question : Quelles sont les applications dans le monde réel ou en entreprise ?
En entreprise, Docker est utilisé pour garantir que l'application fonctionne de la même manière sur l'ordinateur du développeur, sur les serveurs de test et en production (problème du "it works on my machine"). Cela permet d'isoler les applications et leurs dépendances, facilitant ainsi les architectures en microservices. Les entreprises l'utilisent également pour accélérer les déploiements, optimiser l'utilisation des ressources serveurs et automatiser les pipelines d'intégration et de déploiement continus (CI/CD).

## Question : Quelles sont les étapes dans le cycle DevOps touchées (avec justification) ?
- **Build (Construction)** : Création de l'image via le `Dockerfile` pour packager le code et ses dépendances.
- **Release (Livraison)** : Publication de l'image sur Docker Hub pour la rendre disponible.
- **Deploy (Déploiement)** : Utilisation de Docker Compose pour instancier l'application et ses services (Redis, MySQL) dans un environnement donné.
- **Operate (Exploitation)** : Gestion de la persistance des données avec les volumes et surveillance des logs pour assurer la stabilité du service.

## Question : Quels problèmes ont été rencontrés et comment ont-ils été résolus ?
- **Erreurs de chemin (pathspec)** : Lors de l'import du dossier, une faute de frappe dans le nom du répertoire source a bloqué Git. Résolu en utilisant `git ls-tree` pour vérifier la structure exacte.
- **Syntaxe PowerShell vs Linux** : La commande `rm -rf` ne fonctionnait pas sous Windows. Résolu en utilisant la commande native `rm -Recurse -Force`.
- **Échec de connexion à la base de données (ECONNREFUSED)** : L'application cherchait Redis sur `localhost` (127.0.0.1) au lieu d'utiliser le nom du service Docker Compose. Résolu en injectant le nom du service (`redis-db`) via une variable d'environnement dans le fichier YAML.
- **Conflits de ports** : Plusieurs exercices tentaient d'utiliser les mêmes ports. Résolu en arrêtant les anciens conteneurs avec `docker stop` ou `docker-compose down`.

## Question : Quelle est la finalité du lab et êtes-vous arrivé au bout ?
La finalité était d'être capable de transformer une application locale en un système conteneurisé, portable et prêt pour la production. Le lab a été réalisé intégralement, incluant la personnalisation de l'application, la mise en ligne sur Docker Hub, la mise en place d'un environnement multi-conteneurs avec persistance de données, ainsi que la réalisation du bonus WordPress avec une base de données MySQL. Tout a été poussé sur le dépôt GitHub final.
