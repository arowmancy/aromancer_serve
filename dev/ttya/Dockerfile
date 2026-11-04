FROM archlinux AS base
RUN echo "DisableSandboxSyscalls" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    sudo \
    man-db \
    nano \
    which \
    git \
    coreutils \
    wget \
    base-devel \
    gcc \
    openssl \
    openssh \
    ruby && \
    ((useradd --create-home --user-group --password $(openssl passwd -1 "default") default && \
        usermod --append --groups wheel default) \
    || echo "default user exists")


FROM base AS build

WORKDIR /home/default

COPY --chown=default:default ./dev/ttya/default_home/* .

FROM build
