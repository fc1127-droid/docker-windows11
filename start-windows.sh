#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "========================================"
echo " Windows 11 Codespace"
echo "========================================"

echo "[1/3] 確認 Docker..."

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

echo "[2/3] 建立 Windows 資料目錄..."
mkdir -p ./windows/data

echo "[3/3] 啟動 Windows 11..."
docker compose up -d

docker compose ps

echo "========================================"
echo " Windows 11 已啟動"
echo " Web : 8006"
echo " RDP : 3389"
echo "========================================"
