#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Docker 啟動"
echo "========================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: start-docker.sh 必須以 root 執行。"
    exit 1
fi

wait_for_apt() {
    echo "等待其他 apt/dpkg 程序完成..."

    for i in $(seq 1 180); do
        if pgrep -x apt-get >/dev/null 2>&1 ||
           pgrep -x apt >/dev/null 2>&1 ||
           pgrep -x dpkg >/dev/null 2>&1; then
            sleep 2
            continue
        fi

        # 確認常見的 apt lock 沒有被程序持有
        if command -v fuser >/dev/null 2>&1; then
            if fuser \
                /var/lib/apt/lists/lock \
                /var/lib/dpkg/lock \
                /var/lib/dpkg/lock-frontend \
                >/dev/null 2>&1; then
                sleep 2
                continue
            fi
        fi

        echo "apt/dpkg 已就緒。"
        return 0
    done

    echo "ERROR: 等待 apt/dpkg 超時。"
    echo
    echo "目前相關程序："
    ps aux | grep -E '[a]pt|[d]pkg' || true
    exit 1
}

echo "[1/5] 檢查 Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker 尚未安裝。"

    wait_for_apt

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
    wait_for_apt

    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y fuse-overlayfs
else
    echo "fuse-overlayfs 已經安裝。"
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
    echo
    echo "ERROR: Docker daemon 啟動失敗。"
    echo
    echo "===== /tmp/dockerd.log ====="
    cat /tmp/dockerd.log
    exit 1
fi

echo
echo "========================================"
echo " Docker 狀態"
echo "========================================"

docker info | grep -E 'Storage Driver|Docker Root Dir' || true
docker --version
docker compose version

echo
echo "========================================"
echo " Docker 已就緒"
echo "========================================"
