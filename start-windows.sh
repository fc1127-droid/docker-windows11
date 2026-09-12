#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "========================================"
echo " Windows 11 Codespace"
echo "========================================"

echo "[1/6] 確認 Docker..."

for i in $(seq 1 120); do
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon 已就緒。"
        break
    fi

    if [ "$i" -eq 120 ]; then
        echo "ERROR: Docker daemon 尚未就緒。"
        exit 1
    fi

    sleep 1
done

echo "[2/6] 檢查 KVM..."

if [ ! -e /dev/kvm ]; then
    echo "ERROR: /dev/kvm 不存在。"
    exit 1
fi

echo "/dev/kvm OK"

echo "[3/6] 檢查 TUN..."

if [ ! -e /dev/net/tun ]; then
    echo "ERROR: /dev/net/tun 不存在。"
    exit 1
fi

echo "/dev/net/tun OK"

echo "[4/6] 檢查 Codespace 可用空間..."

AVAIL_KB=$(df -Pk . | awk 'NR==2 {print $4}')
AVAIL_GB=$((AVAIL_KB / 1024 / 1024))

echo "目前可用空間：約 ${AVAIL_GB} GB"

if [ "$AVAIL_GB" -lt 40 ]; then
    echo
    echo "WARNING: 可用空間低於 40 GB。"
    echo "Windows 11 64G 虛擬磁碟 + ISO 下載可能無法完成。"
    echo "建議使用至少 64 GB storage 的 Codespace machine。"
    echo
fi

echo "[5/6] 建立持久化資料目錄..."

mkdir -p ./windows/data

echo "Windows 資料目錄：$(realpath ./windows/data)"

echo "[6/6] 啟動 Windows 11..."

# 保留 Docker Compose / Dockur 的自動下載與自動安裝：
# 不掛 custom ISO。
docker compose pull
docker compose up -d

echo
echo "========================================"
echo " Windows 11 container 已啟動"
echo "========================================"
echo " Web Console : 8006"
echo " RDP         : 3389"
echo " Data        : ./windows/data"
echo
echo "Dockur 會自動取得 Windows 11 ISO。"
echo "========================================"
echo
echo "查看即時日誌："
echo "  docker logs -f windows11"
echo
echo "查看狀態："
echo "  docker compose ps"
echo "========================================"
