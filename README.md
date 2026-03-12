# WireGuard Full Mesh VPN Lab

Ambiente de laboratorio hands-on com **5 containers Docker** simulando servidores em uma **VPN WireGuard full mesh**. Cada node se conecta diretamente a todos os outros atraves de tuneis criptografados — sem servidor central, sem ponto unico de falha.

## Topologia de Rede

```
                    Docker Network (172.20.0.0/24) — simula internet "publica"
                    WireGuard Mesh  (10.10.0.0/24) — rede de tuneis criptografados

                                 node-a
                              10.10.0.1
                            172.20.0.10
                           /    |    \    \
                          /     |     \    \
                         /      |      \    \
                node-b -+-------+-------+- node-e
             10.10.0.2  |       |       |  10.10.0.5
            172.20.0.20 |       |       | 172.20.0.50
                  \     |       |       |     /
                   \    |       |       |    /
                    \   |       |       |   /
                node-c -+-------+-------+- node-d
             10.10.0.3                     10.10.0.4
            172.20.0.30                   172.20.0.40

        Full mesh: cada node tem um tunel WireGuard direto para todos os outros
                        Total de conexoes: 10 (n*(n-1)/2)
```

## Como Funciona o WireGuard Mesh

Em uma topologia full mesh, cada node mantem um tunel WireGuard peer-to-peer direto para todos os outros nodes. Nao existe hub central ou relay — o trafego vai diretamente entre os nodes atraves de tuneis UDP criptografados.

Cada node possui:
- Uma **chave privada** (mantida em segredo) e uma **chave publica** correspondente (compartilhada com os peers)
- Uma lista de **peers** com suas chaves publicas e endpoints
- Uma entrada **AllowedIPs** para cada peer, definindo qual trafego passa por cada tunel

Quando o node-a quer alcanca o node-c, o pacote e criptografado com a chave publica do node-c e enviado diretamente via UDP — sem intermediario.

## Esquema de Enderecos IP

| Node   | IP Docker (sim. publico) | IP WireGuard (mesh) | Porta WireGuard |
|--------|--------------------------|---------------------|-----------------|
| node-a | 172.20.0.10              | 10.10.0.1           | 51820           |
| node-b | 172.20.0.20              | 10.10.0.2           | 51820           |
| node-c | 172.20.0.30              | 10.10.0.3           | 51820           |
| node-d | 172.20.0.40              | 10.10.0.4           | 51820           |
| node-e | 172.20.0.50              | 10.10.0.5           | 51820           |

## Como Usar

### 1. Gerar Chaves WireGuard

Os arquivos de configuracao vem com chaves placeholder. Gere chaves reais antes de iniciar:

```bash
# Requer wireguard-tools instalado no host
chmod +x generate-keys.sh
./generate-keys.sh
```

### 2. Iniciar o Lab

```bash
docker compose up --build -d
```

### 3. Verificar se Todos os Nodes Estao Rodando

```bash
docker compose ps
```

## Testando a Conectividade

### Ping pelo mesh WireGuard

```bash
# Do node-a, pingar todos os outros nodes pelo tunel criptografado
docker exec node-a ping -c 3 10.10.0.2   # node-b
docker exec node-a ping -c 3 10.10.0.3   # node-c
docker exec node-a ping -c 3 10.10.0.4   # node-d
docker exec node-a ping -c 3 10.10.0.5   # node-e
```

### Verificar status do WireGuard

```bash
# Ver tuneis ativos, handshakes e dados transferidos
docker exec node-a wg show
```

### SSH entre nodes

```bash
# Conectar via SSH no node-a primeiro
docker exec -it node-a bash

# De dentro do node-a, SSH para o node-c pelo mesh
ssh root@10.10.0.3
# Senha: mesh123
```

### Teste de ping full mesh (todos para todos)

```bash
for src in node-a node-b node-c node-d node-e; do
  for ip in 10.10.0.1 10.10.0.2 10.10.0.3 10.10.0.4 10.10.0.5; do
    docker exec $src ping -c 1 -W 1 $ip > /dev/null 2>&1 && \
      echo "$src -> $ip: OK" || echo "$src -> $ip: FALHA"
  done
done
```

## Estrutura do Projeto

```
wireguard-mesh-lab/
├── docker-compose.yml     # 5 servicos, um por node
├── Dockerfile             # Alpine Linux + WireGuard + SSH
├── generate-keys.sh       # Gera e substitui chaves WireGuard automaticamente
├── nodes/
│   ├── node-a/wg0.conf   # Configuracao WireGuard do node-a
│   ├── node-b/wg0.conf
│   ├── node-c/wg0.conf
│   ├── node-d/wg0.conf
│   └── node-e/wg0.conf
└── README.md
```

## Tecnologias

- **WireGuard** — Protocolo VPN moderno, rapido e minimalista
- **Docker** — Isolamento baseado em containers para cada node
- **Alpine Linux** — Imagem base leve (~5 MB)
- **OpenSSH** — Acesso remoto entre nodes para gerenciamento

## Limpeza

```bash
docker compose down
```

### Resultados e Impacto

- **Simulação realista de redes corporativas** — Reproduz cenários multi-site para validação antes de ir para produção
- **Latência mínima** — Mesh full permite comunicação direta entre nodes sem passar por hub central
- **Segurança enterprise** — Criptografia WireGuard de última geração em todas as conexões
- **Deploy automatizado** — Geração automática de chaves e configurações reduz setup de horas para minutos
- **Custo zero de licenciamento** — Alternativa open-source a VPNs comerciais como Cisco ou Palo Alto

## Licenca

MIT
