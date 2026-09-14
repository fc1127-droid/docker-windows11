FROM docker:29-dind

RUN apk add --no-cache \
    bash \
    curl \
    wget \
    sudo \
    iproute2 \
    iptables \
    iputils \
    bind-tools \
    fuse-overlayfs \
    qemu-img \
    ethtool

# 建立一般 Codespaces 使用者
RUN addgroup -g 1000 codespace \
    && adduser -D -u 1000 -G codespace -s /bin/bash codespace \
    && echo "codespace ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/codespace \
    && chmod 0440 /etc/sudoers.d/codespace

# 加入 Docker / KVM 群組
RUN addgroup codespace docker 2>/dev/null || true \
    && addgroup codespace kvm 2>/dev/null || true

# 工作目錄
RUN mkdir -p /workspaces/docker-windows11 \
    && chown -R codespace:codespace /workspaces/docker-windows11

WORKDIR /workspaces/docker-windows11

USER root

ENV SHELL=/bin/bash
ENV TERM=xterm-256color
