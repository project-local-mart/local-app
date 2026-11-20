FROM mcr.microsoft.com/devcontainers/typescript-node:1-22-bookworm

# Some corporate and guest networks block plain HTTP package mirrors. Debian's
# repositories support HTTPS, so make feature installation work on those
# networks before the Dev Container CLI adds its feature layers.
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources
