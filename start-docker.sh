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
    ps aux | grep -E '[a]pt|[d]pkg' || true
    exit 1
}

echo "[1/7] 檢查 Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker 尚未安裝。"
    wait_for_apt

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y docker.io docker-compose-v2

    echo "Docker 安裝完成。"
else
    echo "Docker 已經安裝。"
fi

echo "[2/7] 安裝必要工具..."

wait_for_apt
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    fuse-overlayfs \
    ca-certificates \
    curl \
    iproute2 \
    iptables \
    iputils-ping \
    dnsutils

echo "[3/7] 設定 Docker storage driver + DNS..."

mkdir -p /etc/docker

cat > /etc/docker/daemon.json <<'EOF'
{
  "storage-driver": "fuse-overlayfs",
  "dns": [
    "168.63.129.16",
    "1.1.1.1",
    "8.8.8.8"
  ]
}
EOF

echo "[4/7] 開啟 IPv4 forwarding..."

sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

echo "[5/7] 啟動 Docker daemon..."

if pgrep -x dockerd >/dev/null 2>&1; then
    echo "Docker daemon 已經在執行。"
    echo "重新啟動 Docker 以套用 daemon.json..."

    kill "$(pgrep -xo dockerd)" 2>/dev/null || true
    sleep 2
fi

rm -f /var/run/docker.pid

nohup dockerd >/tmp/dockerd.log 2>&1 &

echo "Docker daemon 啟動中..."

echo "[6/7] 等待 Docker daemon..."

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

echo "[7/7] 基本網路檢查..."

echo "--- DNS ---"
getent hosts software-static.download.prss.microsoft.com || true

echo
echo "--- Docker ---"
docker info | grep -E 'Storage Driver|Docker Root Dir' || true
docker --version
docker compose version

echo
echo "========================================"
echo " Docker 已就緒"
echo "========================================"
