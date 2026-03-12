# WireGuard Full Mesh VPN Lab

A hands-on lab environment with **5 Docker containers** simulating servers in a **full mesh WireGuard VPN**. Every node connects directly to every other node through encrypted tunnels — no central server, no single point of failure.

## Network Topology

```
                    Docker Network (172.20.0.0/24) — simulates "public" internet
                    WireGuard Mesh  (10.10.0.0/24) — encrypted tunnel network

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

        Full mesh: every node has a direct WireGuard tunnel to every other node
                        Total connections: 10 (n*(n-1)/2)
```

## How WireGuard Mesh Works

In a full mesh topology, each node maintains a direct peer-to-peer WireGuard tunnel to every other node. There is no central hub or relay — traffic goes directly between nodes through encrypted UDP tunnels.

Each node has:
- A **private key** (kept secret) and a corresponding **public key** (shared with peers)
- A list of **peers** with their public keys and endpoints
- An **AllowedIPs** entry for each peer, defining what traffic goes through each tunnel

When node-a wants to reach node-c, the packet is encrypted with node-c's public key and sent directly via UDP — no intermediary needed.

## IP Addressing Scheme

| Node   | Docker IP (public sim) | WireGuard IP (mesh) | WireGuard Port |
|--------|------------------------|---------------------|----------------|
| node-a | 172.20.0.10            | 10.10.0.1           | 51820          |
| node-b | 172.20.0.20            | 10.10.0.2           | 51820          |
| node-c | 172.20.0.30            | 10.10.0.3           | 51820          |
| node-d | 172.20.0.40            | 10.10.0.4           | 51820          |
| node-e | 172.20.0.50            | 10.10.0.5           | 51820          |

## Quick Start

### 1. Generate WireGuard Keys

The config files ship with placeholder keys. Generate real keys before starting:

```bash
# Requires wireguard-tools installed on the host
chmod +x generate-keys.sh
./generate-keys.sh
```

### 2. Start the Lab

```bash
docker compose up --build -d
```

### 3. Verify All Nodes Are Running

```bash
docker compose ps
```

## Testing Connectivity

### Ping through the WireGuard mesh

```bash
# From node-a, ping all other nodes through the encrypted tunnel
docker exec node-a ping -c 3 10.10.0.2   # node-b
docker exec node-a ping -c 3 10.10.0.3   # node-c
docker exec node-a ping -c 3 10.10.0.4   # node-d
docker exec node-a ping -c 3 10.10.0.5   # node-e
```

### Check WireGuard status

```bash
# See active tunnels, handshakes, and data transferred
docker exec node-a wg show
```

### SSH between nodes

```bash
# SSH into node-a first
docker exec -it node-a bash

# From inside node-a, SSH to node-c through the mesh
ssh root@10.10.0.3
# Password: mesh123
```

### Full mesh ping test (all-to-all)

```bash
for src in node-a node-b node-c node-d node-e; do
  for ip in 10.10.0.1 10.10.0.2 10.10.0.3 10.10.0.4 10.10.0.5; do
    docker exec $src ping -c 1 -W 1 $ip > /dev/null 2>&1 && \
      echo "$src -> $ip: OK" || echo "$src -> $ip: FAIL"
  done
done
```

## Project Structure

```
wireguard-mesh-lab/
├── docker-compose.yml     # 5 services, one per node
├── Dockerfile             # Alpine Linux + WireGuard + SSH
├── generate-keys.sh       # Auto-generates and patches WireGuard keys
├── nodes/
│   ├── node-a/wg0.conf   # WireGuard config for node-a
│   ├── node-b/wg0.conf
│   ├── node-c/wg0.conf
│   ├── node-d/wg0.conf
│   └── node-e/wg0.conf
└── README.md
```

## Technologies

- **WireGuard** — Modern, fast, and minimal VPN protocol
- **Docker** — Container-based isolation for each node
- **Alpine Linux** — Lightweight base image (~5 MB)
- **OpenSSH** — Remote access between nodes for management

## Cleanup

```bash
docker compose down
```

## License

MIT
