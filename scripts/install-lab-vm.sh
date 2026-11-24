#!/usr/bin/env bash
# Installe sur la VM de lab (Ubuntu) : Ansible, VirtualBox, Vagrant, Docker, Terraform
set -euo pipefail
cd "$(dirname "$0")/.."

sudo apt update
sudo apt install -y ansible sshpass virtualbox docker.io docker-compose-v2 python3-docker \
  git unzip curl wget gnupg lsb-release ca-certificates
sudo usermod -aG docker "$USER"

# Dépôt HashiCorp (Vagrant + Terraform). Repli sur "noble" si la version n'est pas encore publiée.
CODENAME=$(lsb_release -cs)
if ! curl -fsI "https://apt.releases.hashicorp.com/dists/${CODENAME}/Release" >/dev/null 2>&1; then
  CODENAME=noble
fi
wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt update
sudo apt install -y vagrant terraform

# Collections Ansible utilisées par les rôles
ansible-galaxy collection install -r requirements.yml

echo "---------------- Vérifications ----------------"
ansible --version | head -1
vagrant --version
VBoxManage --version
terraform version | head -1
docker --version
N=$(grep -Ec '(vmx|svm)' /proc/cpuinfo || true)
echo "Extensions de virtualisation (vmx|svm) : $N"
[ "$N" -gt 0 ] || echo "ATTENTION : virtualisation imbriquée non activée (voir README)."
echo "Déconnecte-toi puis reconnecte-toi (exit / ssh) pour que le groupe docker soit pris en compte."
