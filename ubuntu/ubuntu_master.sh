#!/usr/bin/env bash
#
# ============================================================
#  UBUNTU WSL MASTER BOOTSTRAP
#  Base workstation / development / ML-ready
# ============================================================
#
# Usage:
#   chmod +x ubuntu_master.sh
#   ./ubuntu_master.sh
#
# Ne PAS lancer avec "sudo ./script".
# Le script demande sudo uniquement lorsque nécessaire.
#

set -Eeuo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

readonly SCRIPT_NAME="Ubuntu WSL Master Bootstrap"
readonly SCRIPT_VERSION="1.0.1"

LOG_DIR="${HOME}/.local/var/log"
LOG_FILE="${LOG_DIR}/ubuntu-wsl-bootstrap.log"

INSTALL_DOCKER=false
INSTALL_NODE=true
INSTALL_PYTHON_TOOLS=true
CONFIGURE_GIT=true
CONFIGURE_SSH=true

# ------------------------------------------------------------
# COULEURS
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
fi

info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}[OK]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$*"
}

die() {
    printf "${RED}[ERREUR]${RESET} %s\n" "$*" >&2
    exit 1
}

section() {
    printf "\n${CYAN}${BOLD}============================================================${RESET}\n"
    printf "${CYAN}${BOLD} %s${RESET}\n" "$*"
    printf "${CYAN}${BOLD}============================================================${RESET}\n"
}

# ------------------------------------------------------------
# ERREURS / LOGS
# ------------------------------------------------------------

on_error() {
    local exit_code=$?
    local line_no="${1:-?}"

    printf "\n${RED}[ERREUR]${RESET} Échec ligne %s (code %s)\n" \
        "$line_no" "$exit_code" >&2

    printf "Consultez le journal : %s\n" "$LOG_FILE" >&2
}

trap 'on_error $LINENO' ERR

mkdir -p "$LOG_DIR"

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

# ------------------------------------------------------------
# BANNIÈRE
# ------------------------------------------------------------

clear 2>/dev/null || true

printf "${CYAN}${BOLD}"
cat <<'EOF'

 _   _ _                 _          __        ______  _
| | | | |__  _   _ _ __ | |_ _   _ \ \      / / ___|| |
| | | | '_ \| | | | '_ \| __| | | | \ \ /\ / /\___ \| |
| |_| | |_) | |_| | | | | |_| |_| |  \ V  V /  ___) | |___
 \___/|_.__/ \__,_|_| |_|\__|\__,_|   \_/\_/  |____/|_____|

             MASTER BOOTSTRAP

EOF
printf "${RESET}"

printf "Version : %s\n" "$SCRIPT_VERSION"
printf "User    : %s\n" "$USER"
printf "Host    : %s\n\n" "$(hostname)"

# ------------------------------------------------------------
# VÉRIFICATIONS
# ------------------------------------------------------------

section "1. Vérification de l'environnement"

[[ "$(id -u)" -ne 0 ]] ||
    die "Ne lancez pas ce script directement en root."

[[ -f /etc/os-release ]] ||
    die "/etc/os-release introuvable."

# shellcheck disable=SC1091
source /etc/os-release

[[ "${ID:-}" == "ubuntu" ]] ||
    die "Ce bootstrap est prévu pour Ubuntu."

info "Distribution : ${PRETTY_NAME:-Ubuntu}"

if grep -qi microsoft /proc/version 2>/dev/null ||
   grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    success "WSL détecté."
else
    warn "WSL n'a pas été détecté."
    warn "Le script peut fonctionner, mais il est optimisé pour WSL."
fi

ARCH="$(dpkg --print-architecture)"
info "Architecture : $ARCH"

# ------------------------------------------------------------
# SUDO
# ------------------------------------------------------------

section "2. Initialisation sudo"

info "Authentification sudo..."
sudo -v

# Maintenir le ticket sudo pendant l'installation.
(
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$$" 2>/dev/null || exit
    done
) &

SUDO_KEEPALIVE_PID=$!

cleanup() {
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}

trap cleanup EXIT

success "sudo opérationnel."

# ------------------------------------------------------------
# APT
# ------------------------------------------------------------

section "3. Mise à jour Ubuntu"

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update

sudo apt-get \
    -o Dpkg::Options::="--force-confold" \
    upgrade -y

success "Système mis à jour."

# ------------------------------------------------------------
# PAQUETS DE BASE
# ------------------------------------------------------------

section "4. Installation de la base système"

BASE_PACKAGES=(
    build-essential
    ca-certificates
    curl
    wget
    git
    git-lfs
    gnupg
    lsb-release
    software-properties-common
    apt-transport-https

    unzip
    zip
    tar
    gzip
    bzip2
    xz-utils
    p7zip-full

    rsync
    openssh-client

    jq
    tree
    file
    less
    nano
    vim

    tmux
    htop
    ncdu

    ripgrep
    fd-find

    shellcheck

    dnsutils
    iproute2
    iputils-ping
    net-tools
    traceroute

    procps
    lsof

    man-db
    bash-completion

    locales
    tzdata

    make
    cmake
    pkg-config
)

sudo apt-get install -y "${BASE_PACKAGES[@]}"

success "Base système installée."

# ------------------------------------------------------------
# OUTILS DE COMPILATION
# ------------------------------------------------------------

section "5. Toolchain de développement"

DEV_PACKAGES=(
    gcc
    g++
    gdb

    autoconf
    automake
    libtool

    libssl-dev
    libffi-dev

    libbz2-dev
    libreadline-dev
    libsqlite3-dev
    liblzma-dev

    zlib1g-dev
)

sudo apt-get install -y "${DEV_PACKAGES[@]}"

success "Toolchain installée."

# ------------------------------------------------------------
# PYTHON
# ------------------------------------------------------------

if [[ "$INSTALL_PYTHON_TOOLS" == true ]]; then

    section "6. Environnement Python"

    PYTHON_PACKAGES=(
        python3
        python3-dev
        python3-venv
        python3-pip
        pipx
    )

    sudo apt-get install -y "${PYTHON_PACKAGES[@]}"

    python3 --version

    # pipx ajoute ~/.local/bin au PATH.
    pipx ensurepath || true

    success "Python configuré."

fi

# ------------------------------------------------------------
# NODE / NVM
# ------------------------------------------------------------

if [[ "$INSTALL_NODE" == true ]]; then

    section "7. Préparation Node.js"

    #
    # On évite volontairement d'installer Node globalement
    # depuis un dépôt tiers.
    #
    # NVM pourra être ajouté ensuite selon les besoins.
    #

    sudo apt-get install -y nodejs npm

    info "Node : $(node --version 2>/dev/null || echo 'N/A')"
    info "npm  : $(npm --version 2>/dev/null || echo 'N/A')"

    success "Node.js disponible."

fi

# ------------------------------------------------------------
# GIT
# ------------------------------------------------------------

if [[ "$CONFIGURE_GIT" == true ]]; then

    section "8. Configuration Git"

    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    git config --global core.fileMode true
    git config --global fetch.prune true
    git config --global pull.ff only
    git config --global rebase.autoStash true
    git config --global color.ui auto

    git config --global core.editor "nano"

    git lfs install --skip-repo 2>/dev/null || true

    success "Git configuré."

fi

# ------------------------------------------------------------
# SSH
# ------------------------------------------------------------

if [[ "$CONFIGURE_SSH" == true ]]; then

    section "9. Préparation SSH"

    mkdir -p "${HOME}/.ssh"

    chmod 700 "${HOME}/.ssh"

    touch "${HOME}/.ssh/config"

    chmod 600 "${HOME}/.ssh/config"

    success "~/.ssh sécurisé."

    if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then

        warn "Aucune clé Ed25519 personnelle détectée."
        info "Aucune clé n'est générée automatiquement."
        info "Pour en créer une ultérieurement :"
        printf "\n  ssh-keygen -t ed25519 -a 100\n\n"

    else

        success "Clé Ed25519 existante détectée."

    fi

fi

# ------------------------------------------------------------
# RÉPERTOIRES
# ------------------------------------------------------------

section "10. Structure du HOME"

mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.local/bin" \
    "${HOME}/.local/share" \
    "${HOME}/.local/var/log" \
    "${HOME}/projects" \
    "${HOME}/src" \
    "${HOME}/tmp"

chmod 700 "${HOME}/tmp"

success "Structure créée."

# ------------------------------------------------------------
# BASH
# ------------------------------------------------------------

section "11. Optimisation Bash"

BASHRC="${HOME}/.bashrc"

touch "$BASHRC"

MARKER="# >>> UBUNTU WSL MASTER BOOTSTRAP >>>"

if ! grep -Fq "$MARKER" "$BASHRC"; then

cat >> "$BASHRC" <<'EOF'

# >>> UBUNTU WSL MASTER BOOTSTRAP >>>

# User binaries
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# History
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=50000
export HISTFILESIZE=100000
shopt -s histappend

# Better directory handling
shopt -s autocd 2>/dev/null || true
shopt -s cdspell 2>/dev/null || true

# Useful defaults
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS="-R"

# Colors
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Convenience
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# System
alias ports='ss -tulpn'
alias myip='hostname -I'
alias dfh='df -h'
alias duh='du -h'

# Git
alias gs='git status'
alias gl='git log --oneline --decorate --graph'
alias gd='git diff'

# APT
alias update='sudo apt update && sudo apt upgrade'

# WSL
alias winhome='cd /mnt/c/Users'

# Safety
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'

# <<< UBUNTU WSL MASTER BOOTSTRAP <<<
EOF

    success ".bashrc configuré."

else

    info "Configuration Bash déjà présente."

fi

# ------------------------------------------------------------
# WSL
# ------------------------------------------------------------

section "12. Configuration WSL"

if grep -qi microsoft /proc/version 2>/dev/null ||
   grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then

    if [[ -f /etc/wsl.conf ]]; then
        sudo cp /etc/wsl.conf \
            "/etc/wsl.conf.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true

[automount]
enabled=true
root=/mnt/
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=true

[network]
generateHosts=true
generateResolvConf=true
EOF

    success "/etc/wsl.conf configuré."

else

    info "Configuration WSL ignorée."

fi

# ------------------------------------------------------------
# SYSTEMD
# ------------------------------------------------------------

section "13. Vérification systemd"

if [[ "$(ps -p 1 -o comm= 2>/dev/null)" == "systemd" ]]; then
    success "systemd actif."
else
    warn "systemd n'est pas actuellement PID 1."
    warn "Après le bootstrap, exécutez côté Windows :"
    printf "\n  wsl --shutdown\n\n"
    warn "Puis relancez Ubuntu."
fi

# ------------------------------------------------------------
# NETTOYAGE
# ------------------------------------------------------------

section "14. Nettoyage"

sudo apt-get autoremove -y
sudo apt-get autoclean -y

success "Nettoyage terminé."

# ------------------------------------------------------------
# DIAGNOSTIC
# ------------------------------------------------------------

section "15. Diagnostic final"

printf "\n"

printf "%-20s %s\n" \
    "Ubuntu:" \
    "${PRETTY_NAME:-unknown}"

printf "%-20s %s\n" \
    "Kernel:" \
    "$(uname -r)"

printf "%-20s %s\n" \
    "Architecture:" \
    "$(uname -m)"

printf "%-20s %s\n" \
    "Shell:" \
    "${SHELL:-unknown}"

printf "%-20s %s\n" \
    "Git:" \
    "$(git --version 2>/dev/null || echo N/A)"

printf "%-20s %s\n" \
    "Python:" \
    "$(python3 --version 2>/dev/null || echo N/A)"

printf "%-20s %s\n" \
    "Node:" \
    "$(node --version 2>/dev/null || echo N/A)"

printf "%-20s %s\n" \
    "CMake:" \
    "$(cmake --version 2>/dev/null | head -1 || echo N/A)"

printf "%-20s %s\n" \
    "systemd:" \
    "$(ps -p 1 -o comm= 2>/dev/null || echo N/A)"

printf "\n"

# ------------------------------------------------------------
# FIN
# ------------------------------------------------------------

section "BOOTSTRAP TERMINÉ"

success "Ubuntu WSL est prêt."

printf "\nJournal :\n"
printf "  %s\n" "$LOG_FILE"

printf "\n${BOLD}Étape importante :${RESET}\n"
printf "Fermez Ubuntu puis, dans PowerShell Windows, exécutez :\n\n"

printf "  ${CYAN}wsl --shutdown${RESET}\n\n"

printf "Relancez ensuite Ubuntu.\n"

printf "\nPour vérifier :\n\n"

printf "  systemctl --version\n"
printf "  git --version\n"
printf "  python3 --version\n"
printf "  gcc --version\n\n"