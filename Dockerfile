# Dotfiles development/testing environment
#
# Build (native arch):
#   docker build -t dotfiles .
#
# Build for amd64 from Apple Silicon (or any cross-arch):
#   docker buildx build --platform linux/amd64 -t dotfiles .
#
# Build and push multi-arch to a registry:
#   docker buildx build --platform linux/amd64,linux/arm64 -t myregistry/dotfiles:latest --push .
#
# Export image for a specific platform to a tar.gz (e.g. build on Apple Silicon, ship amd64):
#   docker buildx build --platform linux/amd64 --load -t dotfiles:amd64 .
#   docker save dotfiles:amd64 | gzip > dotfiles-amd64.tar.gz
#
# Load and run on the target machine:
#   docker load < dotfiles-amd64.tar.gz
#   docker run -it dotfiles:amd64
#
# Run:
#   docker run -it dotfiles
#
# Azure login inside container uses device code flow:
#   az login --use-device-code

# ==============================================================================
# Stage 1: Download standalone binaries and clone git-based tools
# ==============================================================================
FROM ubuntu:24.04 AS builder

ARG TARGETARCH=amd64

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# yq
RUN YQ_VERSION=$(curl -sf https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name // empty') && \
    [ -n "$YQ_VERSION" ] || { echo "Error: could not resolve yq version"; exit 1; } && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# kubectl
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" \
    -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# k9s
RUN K9S_URL=$(curl -sf https://api.github.com/repos/derailed/k9s/releases/latest | \
    jq -r --arg arch "${TARGETARCH}" \
    '[.assets[] | select(.name | ascii_downcase | test("k9s_linux_" + $arch + ".tar.gz"))] | first | .browser_download_url // empty') && \
    [ -n "$K9S_URL" ] || { echo "Error: could not find k9s release asset for ${TARGETARCH}"; exit 1; } && \
    curl -fsSL "$K9S_URL" -o /tmp/k9s.tar.gz && \
    tar -xzf /tmp/k9s.tar.gz -C /usr/local/bin k9s && \
    rm /tmp/k9s.tar.gz

# kubelogin
RUN KUBELOGIN_VERSION=$(curl -sf https://api.github.com/repos/Azure/kubelogin/releases/latest | jq -r '.tag_name // empty') && \
    [ -n "$KUBELOGIN_VERSION" ] || { echo "Error: could not resolve kubelogin version"; exit 1; } && \
    curl -fsSL "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-${TARGETARCH}.zip" \
    -o /tmp/kubelogin.zip && \
    unzip -q /tmp/kubelogin.zip -d /tmp/kubelogin && \
    mv /tmp/kubelogin/bin/linux_${TARGETARCH}/kubelogin /usr/local/bin/kubelogin && \
    chmod +x /usr/local/bin/kubelogin && \
    rm -rf /tmp/kubelogin /tmp/kubelogin.zip

# Oh My Zsh (direct clone — installer script not needed, dotfiles own .zshrc)
RUN git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git /root/.oh-my-zsh

# fzf-tab OMZ plugin
RUN git clone --depth 1 https://github.com/Aloxaf/fzf-tab \
    /root/.oh-my-zsh/custom/plugins/fzf-tab

# Starship
RUN curl -fsSS https://starship.rs/install.sh | sh -s -- --yes

# fzf (install script downloads the binary and writes ~/.fzf.zsh)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf && \
    /root/.fzf/install --all --no-bash --no-fish

# ==============================================================================
# Stage 2: Final runtime image
# ==============================================================================
FROM ubuntu:24.04

ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/zsh
ENV ZSH=/root/.oh-my-zsh

# Runtime packages (gpg + lsb-release needed by the az CLI installer)
RUN apt-get update && apt-get install -y \
    zsh \
    curl \
    git \
    make \
    stow \
    jq \
    gpg \
    ca-certificates \
    lsb-release \
    netcat-openbsd \
    bat \
    tmux \
    zsh-autosuggestions \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/batcat /usr/local/bin/bat

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Standalone binaries from builder
COPY --from=builder /usr/local/bin/yq        /usr/local/bin/yq
COPY --from=builder /usr/local/bin/kubectl   /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/k9s       /usr/local/bin/k9s
COPY --from=builder /usr/local/bin/kubelogin /usr/local/bin/kubelogin
COPY --from=builder /usr/local/bin/starship  /usr/local/bin/starship

# Git-based tools from builder
COPY --from=builder /root/.oh-my-zsh /root/.oh-my-zsh
COPY --from=builder /root/.fzf       /root/.fzf
COPY --from=builder /root/.fzf.zsh   /root/.fzf.zsh

# Install dotfiles
WORKDIR /root/dotfiles
COPY . .
RUN mkdir -p /root/.config && make install

CMD ["/bin/zsh"]
