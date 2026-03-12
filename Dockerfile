# ============================================
#  WIREGUARD MESH LAB - Imagem base dos nodes
#  Cada container simula um servidor na mesh
# ============================================

# Alpine Linux = super leve (~5MB)
FROM alpine:3.19

# Instalar tudo que um node da mesh precisa:
#   wireguard-tools  → criar e gerenciar túneis WireGuard
#   openssh-server   → permitir SSH entre nodes
#   iproute2         → comandos de rede (ip addr, ip link, ip route)
#   iputils-ping     → comando ping pra testar conectividade
#   iptables         → firewall (bloquear tráfego de fora)
#   bash             → shell mais amigável que o sh padrão
RUN apk add --no-cache \
    wireguard-tools \
    openssh-server \
    iproute2 \
    iputils-ping \
    iptables \
    bash

# Configurar SSH:
#   1. Criar pasta pro SSH
#   2. Definir senha "mesh123" pro root (é lab, não precisa ser seguro)
#   3. Gerar chaves do servidor SSH (sem isso o SSH não inicia)
#   4. Permitir login como root via SSH
RUN mkdir -p /root/.ssh && \
    echo "root:mesh123" | chpasswd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Quando o container iniciar:
#   1. Sobe o SSH server
#   2. Fica vivo pra sempre (sleep infinity)
CMD ["sh", "-c", "/usr/sbin/sshd && sleep infinity"]
