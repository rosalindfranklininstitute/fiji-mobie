ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Europe/London

# Include runtime libraries for Java GUI
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip \
    libx11-dev libxext6 libxrender1 libxtst6 libxi6 libxrandr2 \
    libfreetype6 fontconfig fonts-dejavu-core libgl1 shared-mime-info \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV FIJI_DIR=/opt/Fiji
ENV PATH=${PATH}:${FIJI_DIR}

# Download and extract the current Fiji Stable (JDK bundled)
RUN FIJI_BASE="https://downloads.imagej.net/fiji/stable" \
    && ZIP=fiji-stable-linux64-jdk.zip \
    && cd /tmp \
    && curl -fsSL -O "${FIJI_BASE}/${ZIP}" \
    && unzip -q "${ZIP}" -d /opt \
    && rm "${ZIP}" \
    && if [ ! -d "${FIJI_DIR}" ] && [ -d /opt/Fiji.app ]; then mv /opt/Fiji.app "${FIJI_DIR}"; fi \
    && if [ ! -e "${FIJI_DIR}/fiji-linux-x64" ] && [ -e "${FIJI_DIR}/ImageJ-linux64" ]; then \
         ln -s ImageJ-linux64 "${FIJI_DIR}/fiji-linux-x64"; \
       fi \
    && ls -l "${FIJI_DIR}/fiji-linux-x64"

# MoBIE and MorphoLibJ (IJPB-plugins): latest from their update sites at
# build time (cannot be pinned). The updater also brings the rest of Fiji up to date.
RUN "${FIJI_DIR}/fiji-linux-x64" --update edit-update-site MoBIE https://sites.imagej.net/MoBIE/ \
    && "${FIJI_DIR}/fiji-linux-x64" --update edit-update-site IJPB-plugins https://sites.imagej.net/IJPB-plugins/ \
    && "${FIJI_DIR}/fiji-linux-x64" --update update

# Suppress the updater prompt
COPY prefs/ /root/.java/.userPrefs/net/imagej/updater/

ARG IMAGE_VERSION="dev"
ARG IMAGE_REVISION=""
ARG IMAGE_CREATED=""

LABEL org.opencontainers.image.title="RFI/CCP-volumeEM Fiji with MoBIE" \
      org.opencontainers.image.description="Ubuntu container with Fiji (Stable) image viewer and MoBIE plugin" \
      org.opencontainers.image.authors="The Rosalind Franklin Institute, The Collaborative Computational Project for Volume Electron Microscopy" \
      org.opencontainers.image.source="https://github.com/rosalindfranklininstitute/fiji-mobie" \
      org.opencontainers.image.documentation="https://rosalindfranklininstitute.github.io/volume-em-container-documentation/software/fiji/" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:${UBUNTU_VERSION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}"

CMD ["/opt/Fiji/fiji-linux-x64"]
