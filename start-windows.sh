#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/docker-windows11

echo "========================================"
echo " Windows 11 Codespace"
echo "========================================"

echo "[1/5] 等待 Docker..."

for i in $(seq 1 120); do
    if sudo docker info >/dev/null 2>&1; then
        echo "Docker daemon OK"
        break
    fi

    if [ "$i" -eq 120 ]; then
        echo "ERROR: Docker daemon 尚未就緒。"
        echo
        echo "===== Docker info ====="
        sudo docker info || true
        exit 1
    fi

    sleep 1
done

echo "[2/5] 檢查 KVM..."

test -e /dev/kvm
echo "/dev/kvm OK"

echo "[3/5] 檢查 TUN..."

test -e /dev/net/tun
echo "/dev/net/tun OK"

echo "[4/5] 確認 Windows 資料..."

mkdir -p ./windows/data

echo "Windows data: $(realpath ./windows/data)"

echo
df -h .

echo "[5/5] 啟動 Windows..."

sudo docker compose up -d

echo
echo "========================================"
echo " Windows 11 container 已啟動"
echo "========================================"

sudo docker compose ps

echo
echo "查看 Windows 日誌："
echo "sudo docker logs -f windows11"
