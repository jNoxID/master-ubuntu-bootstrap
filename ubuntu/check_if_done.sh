#!/bin/bash

echo "========== UBUNTU / WSL =========="
cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_ID)='
echo "Kernel : $(uname -r)"
grep -qi microsoft /proc/sys/kernel/osrelease && echo "WSL : OK" || echo "WSL : NON DÉTECTÉ"

echo
echo "========== SYSTEMD =========="
echo "PID 1 : $(ps -p 1 -o comm=)"
systemctl is-system-running 2>/dev/null || true

echo
echo "========== WSL.CONF =========="
cat /etc/wsl.conf

echo
echo "========== OUTILS =========="
for cmd in git git-lfs curl wget gcc g++ make cmake python3 pip3 pipx node npm jq rg shellcheck tmux htop ssh; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf "%-12s [OK]  %s\n" "$cmd" "$(command -v "$cmd")"
    else
        printf "%-12s [MANQUANT]\n" "$cmd"
    fi
done

echo
echo "========== VERSIONS =========="
git --version
python3 --version
gcc --version | head -1
g++ --version | head -1
cmake --version | head -1
node --version
npm --version

echo
echo "========== GIT =========="
git config --global --get init.defaultBranch
git config --global --get core.autocrlf
git config --global --get pull.ff

echo
echo "========== SSH =========="
stat -c '%a %n' ~/.ssh ~/.ssh/config 2>/dev/null || true

echo
echo "========== RÉPERTOIRES =========="
for d in ~/bin ~/.local/bin ~/projects ~/src ~/tmp; do
    [[ -d "$d" ]] && echo "[OK] $d" || echo "[MANQUANT] $d"
done

echo
echo "========== PATH =========="
echo "$PATH" | tr ':' '\n'

echo
echo "========== LOG BOOTSTRAP =========="
tail -30 ~/.local/var/log/ubuntu-wsl-bootstrap.log 2>/dev/null || echo "Log introuvable"

echo
echo "========== FIN DU DIAGNOSTIC =========="