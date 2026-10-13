# syntax=docker/dockerfile:1
# Ubuntu 26.04 image resolved on 2026-10-13. Toolchains are installed at runtime.
FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7

# The session CA is a temporary build mount and never enters an image layer.
# Docker's managed client configuration supplies the reachable proxy address.
RUN --mount=type=secret,id=combined_ca,required=true \
    apt-get -o Acquire::https::CaInfo=/run/secrets/combined_ca update \
    && DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::https::CaInfo=/run/secrets/combined_ca \
       install --yes --no-install-recommends \
       bash build-essential ca-certificates curl file git libglib2.0-0t64 \
       libglu1-mesa pkg-config python3 unzip xz-utils zip \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
WORKDIR /work
