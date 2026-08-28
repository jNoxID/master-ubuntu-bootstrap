# Ubuntu WSL Master Bootstrap

Bootstrap automatisé pour préparer une installation **Ubuntu sous Windows Subsystem for Linux 2 (WSL 2)** avec une base système propre, cohérente et prête pour le développement.

Le projet fournit un socle reproductible destiné à être installé avant les couches spécialisées telles que le développement Python avancé, Docker, CUDA/NVIDIA, PyTorch, Jupyter ou les environnements Machine Learning.

---

## Objectif

`Ubuntu WSL Master Bootstrap` transforme une installation Ubuntu WSL fraîche en environnement de travail disposant notamment de :

* mises à jour système ;
* outils GNU/Linux essentiels ;
* environnement de compilation C/C++ ;
* Git et Git LFS ;
* Python 3 ;
* `pip`, `venv` et `pipx` ;
* Node.js et npm ;
* SSH ;
* outils réseau et diagnostic ;
* outils CLI courants ;
* configuration Bash ;
* structure standardisée du `$HOME` ;
* configuration WSL ;
* activation de `systemd` ;
* journalisation du bootstrap.

L'objectif est de conserver une **couche système de base stable** sur laquelle pourront ensuite être installés des environnements spécialisés.

---

# Architecture

Le projet suit une approche en couches :

```text
Windows
   │
   └── WSL 2
        │
        └── Ubuntu
             │
             ├── Ubuntu WSL Master Bootstrap
             │      ├── Base système
             │      ├── Toolchain
             │      ├── Git
             │      ├── SSH
             │      ├── Python
             │      ├── Node.js
             │      ├── CLI
             │      └── systemd
             │
             └── Couches spécialisées
                    ├── Development
                    ├── Docker
                    ├── ML / AI
                    ├── NVIDIA / CUDA
                    ├── PyTorch
                    └── Jupyter
```

Le bootstrap maître doit rester aussi indépendant que possible des workloads spécialisés.

---

# Prérequis

## Windows

Configuration recommandée :

* Windows 11, ou une version récente et compatible de Windows 10 ;
* WSL 2 ;
* Ubuntu installé sous WSL ;
* virtualisation matérielle activée lorsque nécessaire ;
* accès Internet pendant l'installation.

Vérifier WSL depuis PowerShell :

```powershell
wsl --status
wsl -l -v
```

Ubuntu doit idéalement apparaître avec :

```text
NAME      STATE      VERSION
Ubuntu    Running    2
```

Si nécessaire :

```powershell
wsl --set-version Ubuntu 2
```

---

# Installation

## 1. Récupérer le script

Placez :

```text
ubuntu-wsl-master-bootstrap.sh
```

dans votre `$HOME`.

Exemple :

```bash
~/ubuntu-wsl-master-bootstrap.sh
```

---

## 2. Rendre le script exécutable

```bash
chmod 700 ~/ubuntu-wsl-master-bootstrap.sh
```

---

## 3. Exécuter le bootstrap

```bash
~/ubuntu-wsl-master-bootstrap.sh
```

> **Ne pas lancer le script avec `sudo ./script`.**

Le bootstrap est conçu pour être exécuté avec votre utilisateur Linux normal.

Il demande `sudo` uniquement lorsque des opérations système nécessitent les privilèges `root`.

---

# Ce que le bootstrap configure

## Base système

Installation d'outils tels que :

```text
curl
wget
git
git-lfs
gnupg
jq
tree
vim
nano
tmux
htop
ncdu
ripgrep
fd-find
shellcheck
rsync
unzip
zip
7zip
```

ainsi que différents outils d'administration et de diagnostic.

---

## Réseau

Le bootstrap installe notamment :

```text
iproute2
iputils-ping
dnsutils
net-tools
traceroute
lsof
```

Ces outils permettent d'effectuer les diagnostics réseau de base directement depuis WSL.

---

## Toolchain

Une chaîne de compilation est installée avec notamment :

```text
gcc
g++
gdb
make
cmake
pkg-config
autoconf
automake
libtool
```

ainsi que plusieurs bibliothèques nécessaires à la compilation de logiciels et d'extensions Python.

---

## Python

Le socle Python comprend :

```text
python3
python3-dev
python3-venv
python3-pip
pipx
```

Le bootstrap n'a pas vocation à installer globalement toutes les bibliothèques Python nécessaires aux futurs projets.

Les dépendances applicatives devront être isolées dans des environnements dédiés.

---

## Node.js

Node.js et npm sont disponibles dans la version actuelle du bootstrap.

Pour des environnements nécessitant plusieurs versions de Node.js, une future couche Development pourra utiliser un gestionnaire de versions dédié.

---

## Git

Le bootstrap configure plusieurs valeurs par défaut, notamment :

```text
init.defaultBranch = main
core.autocrlf = input
fetch.prune = true
pull.ff = only
rebase.autoStash = true
```

Git LFS est également initialisé.

Le nom et l'adresse e-mail Git ne sont volontairement pas configurés automatiquement.

Ils peuvent être définis manuellement :

```bash
git config --global user.name "Votre Nom"
git config --global user.email "adresse@example.com"
```

---

# SSH

Le répertoire :

```text
~/.ssh
```

est créé avec des permissions restrictives.

Configuration attendue :

```text
700 ~/.ssh
600 ~/.ssh/config
```

Aucune clé privée n'est générée automatiquement.

Pour créer une clé Ed25519 :

```bash
ssh-keygen -t ed25519 -a 100
```

Les clés privées ne doivent jamais être ajoutées au dépôt Git.

---

# Configuration Bash

Le bootstrap ajoute une section dédiée dans :

```text
~/.bashrc
```

Elle configure notamment :

* `$PATH` utilisateur ;
* historique Bash ;
* couleurs ;
* alias ;
* raccourcis Git ;
* raccourcis système ;
* quelques protections sur les opérations de fichiers.

La configuration est délimitée par :

```text
# >>> UBUNTU WSL MASTER BOOTSTRAP >>>
...
# <<< UBUNTU WSL MASTER BOOTSTRAP <<<
```

Cela permet de distinguer facilement les réglages du bootstrap des personnalisations manuelles.

---

# Structure utilisateur

Le bootstrap prépare notamment :

```text
$HOME/
├── bin/
├── projects/
├── src/
├── tmp/
└── .local/
    ├── bin/
    ├── share/
    └── var/
        └── log/
```

Les projets peuvent par exemple être stockés sous :

```bash
~/projects
```

ou :

```bash
~/src
```

Pour les workloads Linux intensifs, il est généralement préférable de travailler dans le système de fichiers Linux de WSL plutôt que directement sous `/mnt/c`.

---

# systemd

Le bootstrap configure `/etc/wsl.conf` afin d'activer `systemd`.

Configuration principale :

```ini
[boot]
systemd=true
```

Après une première installation ou une modification de `wsl.conf`, arrêtez complètement WSL depuis **PowerShell Windows** :

```powershell
wsl --shutdown
```

Puis relancez Ubuntu.

Vérification :

```bash
ps -p 1 -o comm=
```

Résultat attendu :

```text
systemd
```

On peut également tester :

```bash
systemctl is-system-running
```

---

# Journalisation

Le bootstrap conserve son journal dans :

```text
~/.local/var/log/ubuntu-wsl-bootstrap.log
```

Pour consulter les dernières lignes :

```bash
tail -50 ~/.local/var/log/ubuntu-wsl-bootstrap.log
```

Pour consulter le journal complet :

```bash
less ~/.local/var/log/ubuntu-wsl-bootstrap.log
```

Quitter `less` avec :

```text
q
```

---

# Vérification

Après installation et redémarrage de WSL, quelques contrôles rapides peuvent être effectués.

### WSL

```bash
grep -i microsoft /proc/sys/kernel/osrelease
```

### systemd

```bash
ps -p 1 -o comm=
```

### Git

```bash
git --version
```

### Python

```bash
python3 --version
```

### GCC

```bash
gcc --version
```

### CMake

```bash
cmake --version
```

### Node.js

```bash
node --version
npm --version
```

### SSH

```bash
stat -c '%a %n' ~/.ssh ~/.ssh/config
```

---

# Sécurité

Le bootstrap suit plusieurs principes simples.

### Pas d'exécution permanente en root

Le script doit être lancé depuis un utilisateur Linux standard.

Les privilèges élevés sont obtenus avec `sudo` uniquement lorsque nécessaire.

### Permissions SSH restrictives

Les fichiers SSH sensibles utilisent des permissions adaptées.

### Pas de clé privée automatique

Le bootstrap ne crée, ne copie et ne transmet aucune clé privée.

### Pas de secrets dans le script

Ne placez jamais directement dans le bootstrap :

* mots de passe ;
* tokens API ;
* clés privées ;
* secrets cloud ;
* identifiants Git ;
* credentials Docker ;
* clés d'accès à des services tiers.

Utilisez des mécanismes appropriés de gestion des secrets.

---

# Sauvegarde WSL

Avant une modification majeure du système, il peut être utile d'exporter la distribution depuis PowerShell.

Commencez par identifier son nom exact :

```powershell
wsl -l -v
```

Puis exportez-la, par exemple :

```powershell
wsl --export Ubuntu ubuntu-wsl-backup.tar
```

Le fichier obtenu constitue une sauvegarde exportable de la distribution.

Consultez la documentation WSL correspondant à votre version avant toute opération de restauration ou de remplacement d'une distribution existante.

---

# Ce qui n'appartient pas au Bootstrap Base

Le bootstrap maître ne doit pas devenir une installation monolithique.

Les composants suivants sont destinés à des couches séparées :

```text
Docker
Docker Compose
NVIDIA / CUDA
PyTorch
TensorFlow
JupyterLab
Transformers
LLM tooling
Kubernetes
Rust
Go
IDE / VS Code tooling
outils cloud
```

Cette séparation simplifie :

* la maintenance ;
* les mises à jour ;
* le diagnostic ;
* les sauvegardes ;
* les restaurations ;
* la reproductibilité.

---

# Couche ML / AI

L'évolution prévue est un bootstrap spécialisé :

```text
Ubuntu WSL ML Bootstrap
```

Il pourra compléter le socle avec une architecture de type :

```text
Ubuntu WSL Master Bootstrap
          │
          ▼
      Python tooling
          │
          ▼
   NVIDIA / CUDA WSL
          │
          ▼
       PyTorch
          │
          ▼
      JupyterLab
          │
          ▼
   ML / AI Toolchain
```

La gestion du GPU sous WSL devra tenir compte du modèle spécifique de pilotes NVIDIA/Windows et ne devra pas simplement reproduire une installation CUDA destinée à une machine Ubuntu native.

---

# Dépannage

## systemd n'est pas actif

Depuis PowerShell :

```powershell
wsl --shutdown
```

Relancez ensuite Ubuntu et vérifiez :

```bash
ps -p 1 -o comm=
```

---

## Vérifier la configuration WSL

```bash
cat /etc/wsl.conf
```

---

## Vérifier les erreurs du bootstrap

```bash
grep -iE 'error|erreur|failed|failure' \
    ~/.local/var/log/ubuntu-wsl-bootstrap.log
```

Puis inspectez le journal complet si nécessaire.

---

## Un paquet est manquant

Actualisez APT :

```bash
sudo apt update
```

Puis relancez le bootstrap ou installez explicitement le paquet concerné après avoir identifié la cause.

---

# Arborescence recommandée du projet

```text
ubuntu-wsl-bootstrap/
├── README.md
├── ubuntu-wsl-master-bootstrap.sh
├── docs/
│   ├── troubleshooting.md
│   └── validation.md
└── scripts/
    └── diagnostics.sh
```

À terme :

```text
ubuntu-wsl-bootstrap/
├── README.md
├── bootstrap/
│   ├── base.sh
│   ├── dev.sh
│   ├── docker.sh
│   └── ml.sh
├── scripts/
│   ├── diagnostics.sh
│   └── backup.sh
└── docs/
    ├── installation.md
    ├── security.md
    ├── troubleshooting.md
    └── ml-stack.md
```

---

# Philosophie du projet

Le principe est :

> **Une base minimale, stable et vérifiable ; des couches spécialisées indépendantes.**

Le Bootstrap Base prépare Ubuntu.

Il ne doit pas imposer l'ensemble de la stack applicative future.

Cette approche permet de conserver un environnement WSL plus propre et de faire évoluer indépendamment les composants Development, Docker et Machine Learning.

---

# Roadmap

Évolutions envisagées :

* [x] Bootstrap Ubuntu WSL de base
* [x] Configuration `systemd`
* [x] Toolchain C/C++
* [x] Python de base
* [x] Git / Git LFS
* [x] SSH
* [x] CLI et outils réseau
* [x] Logging
* [ ] Script de diagnostic autonome
* [ ] Mode réellement idempotent complet
* [ ] Gestionnaire Python moderne (`uv`)
* [ ] Gestion Node.js versionnée
* [ ] Bootstrap Docker
* [ ] Bootstrap NVIDIA/CUDA
* [ ] Bootstrap ML/AI
* [ ] PyTorch
* [ ] JupyterLab
* [ ] Validation GPU automatisée
* [ ] Sauvegarde/restauration assistée
* [ ] CI / ShellCheck automatique

---

# Licence

Définissez une licence avant toute distribution publique du projet.

Pour un projet open source, des licences courantes incluent notamment MIT, Apache-2.0 et GPL-3.0.

---

## Statut

**Ubuntu WSL Master Bootstrap — Base opérationnelle**

Le socle est destiné à servir de point de départ aux futures couches **Development**, **Docker** et **ML/AI**.
