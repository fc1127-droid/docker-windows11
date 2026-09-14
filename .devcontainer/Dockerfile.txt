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

RUN mkdir -p /workspaces/docker-windows11

WORKDIR /workspaces/docker-windows11
