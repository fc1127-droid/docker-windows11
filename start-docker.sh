#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Docker 啟動"
echo "========================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: start-docker.sh 必須以 root 執行。"
    exit 1
fi

echo "[1/5] 檢查 Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "正在安裝 Docker..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y docker.io docker-compose-v2
    echo "Docker 安裝完成。"
else
    echo "Docker 已經安裝。"
fi

echo "[2/5] 安裝 fuse-overlayfs..."

if ! command -v fuse-overlayfs >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y fuse-overlayfs
fi

echo "fuse-overlayfs: $(command -v fuse-overlayfs)"

echo "[3/5] 設定 Docker storage driver..."

mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "storage-driver": "fuse-overlayfs"
}
EOF

echo "[4/5] 啟動 Docker daemon..."

if pgrep -x dockerd >/dev/null 2>&1; then
    echo "Docker daemon 已經在執行。"
else
    rm -f /var/run/docker.pid
    rm -f /var/run/docker.sock
    nohup dockerd >/tmp/dockerd.log 2>&1 &
    echo "Docker daemon 啟動中..."
fi

echo "[5/5] 等待 Docker daemon..."

for i in $(seq 1 120); do
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon 已就緒。"
        break
    fi
    sleep 1
done

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon 啟動失敗。"
    echo "===== /tmp/dockerd.log ====="
    cat /tmp/dockerd.log
    exit 1
fi

docker info | grep -E 'Storage Driver|Docker Root Dir' || true
docker --version
docker compose version

echo "Docker 已就緒。"
