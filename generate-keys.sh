#!/usr/bin/env bash
# ============================================
#  WIREGUARD MESH LAB — Key Generator
#  Generates WireGuard keys for all 5 nodes
#  and patches the config files automatically
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NODES_DIR="$SCRIPT_DIR/nodes"
NODES=(node-a node-b node-c node-d node-e)

# Check if wg is available
if ! command -v wg &>/dev/null; then
    echo "[!] WireGuard tools not found. Install with:"
    echo "    sudo apt install wireguard-tools   # Debian/Ubuntu"
    echo "    sudo pacman -S wireguard-tools      # Arch"
    echo "    sudo apk add wireguard-tools        # Alpine"
    exit 1
fi

echo "=== WireGuard Mesh Lab — Key Generator ==="
echo ""

# Generate key pairs
declare -A PRIVKEYS
declare -A PUBKEYS

for node in "${NODES[@]}"; do
    PRIVKEYS[$node]=$(wg genkey)
    PUBKEYS[$node]=$(echo "${PRIVKEYS[$node]}" | wg pubkey)
    echo "[+] $node: keys generated"
done

echo ""

# Map node names to placeholder prefixes (uppercase)
declare -A PREFIX_MAP
PREFIX_MAP=(
    [node-a]="NODE_A"
    [node-b]="NODE_B"
    [node-c]="NODE_C"
    [node-d]="NODE_D"
    [node-e]="NODE_E"
)

# Patch all config files
for node in "${NODES[@]}"; do
    CONF="$NODES_DIR/$node/wg0.conf"

    if [[ ! -f "$CONF" ]]; then
        echo "[!] Config not found: $CONF"
        continue
    fi

    # Replace this node's private key
    prefix="${PREFIX_MAP[$node]}"
    sed -i "s|${prefix}_PRIVATE_KEY|${PRIVKEYS[$node]}|g" "$CONF"

    # Replace all peer public keys
    for peer in "${NODES[@]}"; do
        if [[ "$peer" != "$node" ]]; then
            peer_prefix="${PREFIX_MAP[$peer]}"
            sed -i "s|${peer_prefix}_PUBLIC_KEY|${PUBKEYS[$peer]}|g" "$CONF"
        fi
    done

    echo "[+] $CONF patched"
done

echo ""
echo "=== Done! All keys generated and configs patched ==="
echo ""
echo "Keys summary:"
echo "-----------------------------------------------"
for node in "${NODES[@]}"; do
    echo "  $node:"
    echo "    Private: ${PRIVKEYS[$node]}"
    echo "    Public:  ${PUBKEYS[$node]}"
    echo ""
done
echo "-----------------------------------------------"
echo ""
echo "Now run: docker compose up --build -d"
