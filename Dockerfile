# Dockerfile
FROM alpine:3.12

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Install Helm
# hadolint ignore=DL3018
RUN apk add --no-cache curl bash && \
    curl "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | VERIFY_CHECKSUM=false bash

# Install yq
RUN set -x && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m)" && \
    if [ "${ARCH}" = "x86_64" ]; then ARCH='amd64'; fi && \
    if [ "${ARCH}" = "aarch64" ]; then ARCH='arm64'; fi && \
    curl -fL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_${OS}_${ARCH}" && \
    chmod +x /usr/local/bin/yq

# Copy the script into the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
WORKDIR /github/workspace
