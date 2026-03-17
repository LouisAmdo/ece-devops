# Compte Rendu — TP 08 : Container Orchestration avec Kubernetes

## Informations

- **Module** : DevOps
- **TP** : 08 — Container Orchestration with Kubernetes
- **Outils** : Minikube, kubectl, Docker

---

## Objectifs du TP

1. Installer Minikube
2. Apprendre les commandes `kubectl`
3. Exposer un service Kubernetes vers l'extérieur
4. Scaler (augmenter / diminuer) un déploiement Kubernetes
5. Exécuter une application multi-pod dans Kubernetes
6. Déployer une application à l'aide de fichiers YAML manifest

---

## 1. Installation et démarrage de Minikube

### Installation

```bash
# Installation de Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Installation de kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
```

### Démarrage

```bash
$ minikube start --driver=docker --force
```

### Vérification

```bash
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

> ✅ Minikube est correctement installé et le cluster est opérationnel. Le Control Plane, le kubelet et l'API server sont tous en état `Running`.

---

## 2. Utilisation des commandes `kubectl`

### 2.1 Création d'un déploiement

```bash
$ kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp created
```

L'image `gcr.io/google-samples/kubernetes-bootcamp:v1` est une application web Node.js basique.

### 2.2 Lister les pods

```bash
$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-67fbdd6b79-kvjqs   1/1     Running   0          44s
```

> Le pod est en état `Running` avec `1/1` conteneur prêt.

### 2.3 Afficher les logs du pod

```bash
$ kubectl logs kubernetes-bootcamp-67fbdd6b79-kvjqs
Kubernetes Bootcamp App Started At: 2026-03-17T10:13:00.319Z | Running On:  kubernetes-bootcamp-67fbdd6b79-kvjqs
```

### 2.4 Exécuter une commande dans le pod

```bash
$ kubectl exec kubernetes-bootcamp-67fbdd6b79-kvjqs -- cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 8 (jessie)"
NAME="Debian GNU/Linux"
VERSION_ID="8"
VERSION="8 (jessie)"
ID=debian
```

> Le conteneur utilise Debian Jessie comme système d'exploitation de base.

### 2.5 Trouver le code source JavaScript

```bash
$ kubectl exec $POD_NAME -- ls /
bin  boot  core  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  server.js  srv  sys  tmp  usr  var
```

Le fichier source JavaScript est **`/server.js`**. En l'examinant :

```javascript
var www = http.createServer(handleRequest);
www.listen(8080, function () { ... });
```

> L'application écoute sur le **port 8080**.

### 2.6 Requête depuis l'intérieur du pod

```bash
$ kubectl exec $POD_NAME -- curl -s http://localhost:8080
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-kvjqs | v=1
```

> ✅ L'application répond correctement depuis l'intérieur du pod.

### 2.7 Peut-on accéder à l'application depuis l'extérieur du pod ?

**Non**, l'application n'est pas encore exposée. Les pods ont un réseau interne à Kubernetes et ne sont pas accessibles depuis l'extérieur du cluster sans un Service.

---

## 3. Exposition d'un service Kubernetes

### 3.1 Exposer le déploiement

```bash
$ kubectl expose deployments/kubernetes-bootcamp --type="NodePort" --port 8080
service/kubernetes-bootcamp exposed
```

### 3.2 Vérifier le port attribué

```bash
$ kubectl get services
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP          3m20s
kubernetes-bootcamp   NodePort    10.106.20.126   <none>        8080:32422/TCP   14s
```

> Le service est exposé sur le **NodePort 32422**.

### 3.3 Obtenir l'IP de Minikube

```bash
$ minikube ip
192.168.49.2
```

### 3.4 Accéder au service

Avec le driver Docker, on utilise `minikube service` pour créer un tunnel :

```bash
$ minikube service kubernetes-bootcamp --url
http://192.168.49.2:32422

$ curl -s http://192.168.49.2:32422
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-kvjqs | v=1
```

> ✅ Le service est maintenant accessible depuis l'extérieur du cluster via le NodePort.

---

## 4. Scaling (mise à l'échelle) du déploiement

### 4.1 Scale up à 5 réplicas

```bash
$ kubectl scale deployments/kubernetes-bootcamp --replicas=5
deployment.apps/kubernetes-bootcamp scaled
```

### 4.2 Vérification avec `kubectl get pods`

```bash
$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-67fbdd6b79-f6j78   1/1     Running   0          10s
kubernetes-bootcamp-67fbdd6b79-jkj6l   1/1     Running   0          10s
kubernetes-bootcamp-67fbdd6b79-kvjqs   1/1     Running   0          3m22s
kubernetes-bootcamp-67fbdd6b79-rxgnt   1/1     Running   0          10s
kubernetes-bootcamp-67fbdd6b79-xhwc5   1/1     Running   0          10s
```

> ✅ 5 pods sont bien en état `Running`. La commande utilisée pour vérifier est `kubectl get pods`.

### 4.3 Load balancing

En rafraîchissant plusieurs fois le navigateur (ou en faisant des requêtes curl), on observe que **les requêtes sont réparties entre les différents pods** :

```
Request 1: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-f6j78 | v=1
Request 2: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-rxgnt | v=1
Request 3: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-xhwc5 | v=1
Request 4: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-rxgnt | v=1
Request 5: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-xhwc5 | v=1
```

> **Explication** : Le Service Kubernetes fait office de **load balancer** et distribue les requêtes entre tous les pods du déploiement. Chaque requête peut être traitée par un pod différent, ce qui est visible par le nom du pod qui change dans la réponse.

### 4.4 Scale down à 2 réplicas

```bash
$ kubectl scale deployments/kubernetes-bootcamp --replicas=2
deployment.apps/kubernetes-bootcamp scaled

$ kubectl get pods
NAME                                   READY   STATUS        RESTARTS   AGE
kubernetes-bootcamp-67fbdd6b79-f6j78   1/1     Terminating   0          46s
kubernetes-bootcamp-67fbdd6b79-jkj6l   1/1     Terminating   0          46s
kubernetes-bootcamp-67fbdd6b79-kvjqs   1/1     Running       0          3m58s
kubernetes-bootcamp-67fbdd6b79-rxgnt   1/1     Running       0          46s
kubernetes-bootcamp-67fbdd6b79-xhwc5   1/1     Terminating   0          46s
```

> ✅ 3 pods passent en état `Terminating` et il ne reste que **2 pods en Running**. Kubernetes gère automatiquement l'arrêt gracieux des pods en excès.

---

## 5. Mise à jour d'image et rollback

### 5.1 Mise à jour vers v2

```bash
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
deployment.apps/kubernetes-bootcamp image updated
```

Résultat après mise à jour :

```
Request 1: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-9c9cdbbfc-cfx75 | v=2
Request 2: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-9c9cdbbfc-cfx75 | v=2
Request 3: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-9c9cdbbfc-6zqrb | v=2
```

> La page affiche maintenant **v=2**. Kubernetes a effectué un **rolling update** : les anciens pods (v1) sont progressivement remplacés par les nouveaux pods (v2) sans interruption de service.

### 5.2 Mise à jour vers v3 (image inexistante)

```bash
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v3
deployment.apps/kubernetes-bootcamp image updated

$ kubectl get pods
NAME                                  READY   STATUS         RESTARTS   AGE
kubernetes-bootcamp-8f54f8c98-kkvns   0/1     ErrImagePull   0          10s
kubernetes-bootcamp-9c9cdbbfc-6zqrb   1/1     Running        0          38s
kubernetes-bootcamp-9c9cdbbfc-cfx75   1/1     Running        0          36s
```

> **Observation** : Le nouveau pod est en état `ErrImagePull` car l'image `v3` n'existe pas sur le registre Docker. Les anciens pods (v2) continuent de fonctionner, garantissant la disponibilité du service. Kubernetes empêche le déploiement d'une image invalide de casser l'application.

### 5.3 Rollback vers v2

```bash
$ kubectl rollout undo deployments/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp rolled back

$ curl -s http://192.168.49.2:32422
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-9c9cdbbfc-cfx75 | v=2
```

> ✅ Le rollback a restauré le déploiement vers l'image v2.

### 5.4 Retour à l'image originale v1

```bash
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v1
deployment.apps/kubernetes-bootcamp image updated

$ curl -s http://192.168.49.2:32422
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-67fbdd6b79-2k44h | v=1
```

> ✅ L'application est de retour à la version v1, comme initialement déployée dans la partie 2.

---

## 6. Déploiement avec des fichiers YAML manifest

### 6.1 Nettoyage

```bash
$ kubectl delete service kubernetes-bootcamp
service "kubernetes-bootcamp" deleted

$ kubectl delete deployment kubernetes-bootcamp
deployment.apps "kubernetes-bootcamp" deleted
```

### 6.2 Fichier `deployment.yaml` complété

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubernetes-bootcamp
  labels:
    app: kubernetes-bootcamp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kubernetes-bootcamp
  template:
    metadata:
      labels:
        app: kubernetes-bootcamp
    spec:
      containers:
      - name: kubernetes-bootcamp
        image: gcr.io/google-samples/kubernetes-bootcamp:v1
        ports:
        - containerPort: 8080
```

**Modifications apportées :**
- **`TO COMPLETE #1`** → `image: gcr.io/google-samples/kubernetes-bootcamp:v1` et `ports: - containerPort: 8080` — on utilise la même image que dans la partie 2 et on expose le port 8080 sur lequel l'app écoute.
- **`TO COMPLETE #2`** → `replicas: 3` — on crée 3 réplicas de l'application pour la haute disponibilité.

### 6.3 Application du déploiement

```bash
$ kubectl apply -f lab/deployment.yaml
deployment.apps/kubernetes-bootcamp created

$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-6b8bd7c8db-5ndws   1/1     Running   0          10s
kubernetes-bootcamp-6b8bd7c8db-kq6dg   1/1     Running   0          10s
kubernetes-bootcamp-6b8bd7c8db-snp9r   1/1     Running   0          10s
```

> ✅ Les 3 pods sont en état `Running`.

### 6.4 Fichier `service.yaml` complété

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-bootcamp-service
spec:
  type: NodePort
  selector:
    app: kubernetes-bootcamp
  ports:
    - port: 8080
      targetPort: 8080
```

**Modifications apportées :**
- **`app: # TO COMPLETE`** → `app: kubernetes-bootcamp` — le sélecteur doit correspondre au label défini dans le déploiement.
- **`port: # TO COMPLETE`** → `port: 8080` et ajout de `targetPort: 8080` — le service écoute sur le port 8080 et redirige vers le port 8080 des conteneurs.

### 6.5 Application du service

```bash
$ kubectl apply -f lab/service.yaml
service/kubernetes-bootcamp-service created

$ kubectl get services
NAME                          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes                    ClusterIP   10.96.0.1      <none>        443/TCP          7m40s
kubernetes-bootcamp-service   NodePort    10.97.90.243   <none>        8080:30652/TCP   0s
```

### 6.6 Test du load balancing avec 3 réplicas

```bash
$ minikube service kubernetes-bootcamp-service --url
http://192.168.49.2:30652

Request 1: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-6b8bd7c8db-5ndws | v=1
Request 2: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-6b8bd7c8db-snp9r | v=1
Request 3: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-6b8bd7c8db-5ndws | v=1
Request 4: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-6b8bd7c8db-kq6dg | v=1
Request 5: Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-6b8bd7c8db-5ndws | v=1
```

> ✅ Les requêtes sont bien réparties entre les 3 réplicas (3 noms de pods différents apparaissent). Le load balancing fonctionne correctement.

### 6.7 Nettoyage final

```bash
$ kubectl delete service kubernetes-bootcamp-service
$ kubectl delete deployment kubernetes-bootcamp
$ minikube stop
✋  Stopping node "minikube"  ...
🛑  1 node stopped.
```

---

## Conclusion

Ce TP nous a permis de découvrir et maîtriser les concepts fondamentaux de l'orchestration de conteneurs avec **Kubernetes** :

| Concept | Ce que nous avons appris |
|---|---|
| **Pods** | Unité de base d'exécution, abstraction d'un ou plusieurs conteneurs |
| **Deployments** | Gestion déclarative des pods avec rolling updates |
| **Services** | Exposition réseau des pods avec load balancing automatique |
| **Scaling** | Augmentation/diminution dynamique du nombre de réplicas |
| **Rolling Updates** | Mise à jour sans interruption de service |
| **Rollback** | Retour à une version précédente en cas de problème |
| **Manifests YAML** | Configuration déclarative et reproductible du cluster |

Les points clés à retenir :
- Kubernetes assure la **haute disponibilité** grâce au mécanisme de réplicas
- Le **load balancing** est automatique via les Services
- Les **rolling updates** permettent des mises à jour zero-downtime
- Le **rollback** protège contre les déploiements défaillants (comme l'image v3 inexistante)
- L'approche **déclarative avec YAML** est la méthode recommandée pour les projets en production
