#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Docker DinD 啟動"
echo "========================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: 必須以 root 執行。"
    exit 1
fi

mkdir -p /etc/docker
mkdir -p /var/lib/docker
mkdir -p /run

echo "[1/6] 設定 Docker..."

cat > /etc/docker/daemon.json <<'EOF'
{
  "storage-driver": "fuse-overlayfs",
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "live-restore": true,
  "dns": [
    "168.63.129.16",
    "1.1.1.1",
    "8.8.8.8"
  ]
}
EOF

echo "[2/6] 設定 iptables..."

update-alternatives --set iptables /usr/sbin/iptables-legacy || true
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true

iptables --version || true
ip6tables --version || true

echo "[3/6] 開啟 IPv4 forwarding..."

sysctl -w net.ipv4.ip_forward=1 || true

echo "[4/6] 清理舊 Docker daemon..."

if pgrep -x dockerd >/dev/null 2>&1; then
    echo "停止舊 dockerd..."

    pkill -TERM dockerd || true
    sleep 3

    pkill -KILL dockerd || true
fi

rm -f /run/docker.pid
rm -f /var/run/docker.pid

echo "[5/6] 啟動 Docker daemon..."

nohup dockerd \
    --host=unix:///var/run/docker.sock \
    --config-file=/etc/docker/daemon.json \
    >/tmp/dockerd.log 2>&1 &

echo "[6/6] 等待 Docker daemon..."

READY=0

for i in $(seq 1 120); do
    if docker info >/dev/null 2>&1; then
        READY=1
        break
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo
    echo "ERROR: Docker daemon 啟動失敗"
    echo
    echo "===== /tmp/dockerd.log ====="
    cat /tmp/dockerd.log
    exit 1
fi

echo
echo "===== Docker ====="
docker info | grep -E \
    'Storage Driver|Docker Root Dir|Server Version' \
    || true

echo
echo "===== Network ====="
docker network ls

echo
echo "===== Internet test ====="
curl -4 -I --max-time 10 https://www.microsoft.com || true

echo
echo "========================================"
echo " Docker DinD 已就緒"
echo "========================================"