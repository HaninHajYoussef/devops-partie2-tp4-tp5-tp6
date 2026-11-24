# DevOps & Cloud – Partie 2 : Automatisation & IaC (TP4, TP5, TP6)

Auteur : **Hanin Haj Youssef** – VM de lab : `hanin@192.168.56.101` (hostname `devops`)

| TP | Dossier | Contenu |
|----|---------|---------|
| TP4 – Ansible | `tp4-ansible-bases/demo1/` | inventaire, `ansible.cfg`, `webserver_install.yml`, `docker_stack.yml` (partie 4), `site.yml` + `roles/` (partie 5), `app/Dockerfile` |
| TP5 – Vagrant | `tp5-vagrant/` | `vagrant_demo/` (Apache + dossier synchronisé + port 8080), `lab/` (2 VM + rôles du TP4) |
| TP6 – Terraform | `tp6-terraform/` | `docker-nginx/` (local + variables), `docker-remote/` (Docker via SSH), `integration/` (Vagrant + Ansible + Terraform + CV + reverse proxy) |

## 0. Préparer la VM de lab (une seule fois)

Virtualisation imbriquée (VM éteinte), sur Windows :
```powershell
# VirtualBox :
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "NOM_DE_LA_VM" --nested-hw-virt on
# Hyper-V (PowerShell admin) :
Set-VMProcessor -VMName NOM_DE_LA_VM -ExposeVirtualizationExtensions $true
```
Donner à la VM au moins 4 vCPU, 8 Go RAM, 60 Go disque. Puis dans la VM :
```bash
bash scripts/install-lab-vm.sh
exit   # puis se reconnecter : ssh hanin@192.168.56.101 (groupe docker)
```

## TP4 – Ansible (`tp4-ansible-bases/demo1`)

Prérequis : 2 nœuds gérés Ubuntu (par ex. 2 clones de la VM) en `192.168.56.102` et `192.168.56.103`, même utilisateur `hanin` avec sudo. Adapter `inventory.txt` si les IP sont différentes.

```bash
cd tp4-ansible-bases/demo1
ansible-inventory --graph
ansible all -m ping -k                                  # capture ping-pong.png
ansible-playbook webserver_install.yml --syntax-check
ansible-playbook webserver_install.yml -k -K --check --diff
ansible-playbook webserver_install.yml -k -K            # capture playbook-run.png
curl http://192.168.56.102
ansible-playbook webserver_install.yml -k -K            # changed=0 -> idempotence.png

# Partie 3 : clés SSH
ssh-keygen -t ed25519 -C "ansible-control"
ssh-copy-id hanin@192.168.56.102
ssh-copy-id hanin@192.168.56.103
ansible-playbook webserver_install.yml -K               # ssh-keys.png

# Partie 4 : image Docker + Jenkins/Docker/Portainer/conteneur
docker build -t haninhajyoussef/devops-web:latest app/
docker login && docker push haninhajyoussef/devops-web:latest
ansible-playbook docker_stack.yml -K                    # containers.png

# Partie 5 : rôles
ansible-playbook site.yml -K                            # roles-run.png
ansible-playbook site.yml -K                            # 2e passage : changed=0
```
Par défaut l'image est construite sur chaque nœud (`app_build_local: true`). Pour tirer l'image depuis Docker Hub :
`ansible-playbook site.yml -K -e app_build_local=false -e app_image=TON_COMPTE/devops-web:latest`

| Service | URL |
|---------|-----|
| Jenkins | http://NOEUD:8080 (mot de passe initial affiché par le playbook) |
| Portainer | https://NOEUD:9443 |
| App web (docker compose) | http://NOEUD:8081 |

## TP5 – Vagrant (`tp5-vagrant`)

```bash
grep -Ec '(vmx|svm)' /proc/cpuinfo && vagrant --version        # nested-virt.png
vagrant box add bento/ubuntu-24.04 --provider virtualbox

cd tp5-vagrant/vagrant_demo && vagrant up
curl http://localhost:8080          # PC : http://192.168.56.101:8080 -> vagrant-demo.png
vagrant destroy -f

cd ../lab && vagrant up             # 2 VM + provisionnement Ansible (rôles du TP4)
vagrant status                      # vagrant-status.png
vagrant provision                   # relancer Ansible
```
Accès depuis le PC (lab-services.png) :

| VM | Jenkins | Portainer | App web |
|----|---------|-----------|---------|
| lab-vm1 (192.168.60.11) | http://192.168.56.101:18080 | https://192.168.56.101:19443 | http://192.168.56.101:18081 |
| lab-vm2 (192.168.60.12) | http://192.168.56.101:28080 | https://192.168.56.101:29443 | http://192.168.56.101:28081 |

Mot de passe Jenkins : `vagrant ssh lab-vm1 -c "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"`

## TP6 – Terraform (`tp6-terraform`)

```bash
cd tp6-terraform/docker-nginx
terraform init && terraform fmt && terraform validate
terraform plan                      # terraform-plan.png
terraform apply                     # terraform-apply.png
docker ps && curl http://localhost:8001
terraform state list && terraform show
terraform apply -var external_port=8002
terraform destroy

cd ../docker-remote                 # Docker distant via SSH (clé SSH requise)
echo "192.168.56.102 devopslab" | sudo tee -a /etc/hosts
ssh hanin@devopslab docker ps       # doit marcher sans mot de passe
terraform init && terraform apply   # terraform-remote.png
terraform destroy

cd ../integration                   # Vagrant + Ansible + Terraform
docker build -t haninhajyoussef/cv-onepage:latest cv/
docker push haninhajyoussef/cv-onepage:latest
vagrant up                          # Ansible installe docker+terraform, Terraform lance le CV
# PC : http://192.168.56.101:8001 (vm1) et http://192.168.56.101:8002 (vm2) -> integration-cv.png

cd reverse-proxy                    # Défi
terraform init && terraform apply   # PC : http://192.168.56.101:8000 -> reverse-proxy.png
```

Ne pas commiter `terraform.tfstate`, `.terraform/`, `*.tfvars` (voir `.gitignore`). Commiter `.terraform.lock.hcl` après `terraform init`.

## Nettoyage
```bash
(cd tp5-vagrant/lab && vagrant destroy -f)
(cd tp6-terraform/integration/reverse-proxy && terraform destroy -auto-approve)
(cd tp6-terraform/integration && vagrant destroy -f)
```
