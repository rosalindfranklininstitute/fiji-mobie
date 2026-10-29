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

# Download the current Fiji (JDK bundled), verify and unzip.
# NB no build argument changes between builds, so use --no-cache to get a newer Fiji.
RUN FIJI_BASE="https://downloads.imagej.net/fiji/latest" \
    && ZIP=fiji-latest-linux64-jdk.zip \
    && cd /tmp \
    && curl -fsSL -O "${FIJI_BASE}/${ZIP}" \
    && for h in sha256 sha512; do \
         echo "$(curl -fsSL "${FIJI_BASE}/${ZIP}.${h}")  ${ZIP}" | ${h}sum -c - || exit 1; \
       done \
    && unzip -q "${ZIP}" -d /opt \
    && rm "${ZIP}"

ENV FIJI_DIR=/opt/Fiji
ENV PATH=${PATH}:${FIJI_DIR}

# MoBIE: latest from the update site at build time (cannot be pinned).
# The updater also brings the rest of Fiji up to date.
RUN "${FIJI_DIR}/fiji-linux-x64" --update edit-update-site MoBIE https://sites.imagej.net/MoBIE/ \
    && "${FIJI_DIR}/fiji-linux-x64" --update update \
    && ls "${FIJI_DIR}"/jars/mobie-viewer-fiji-*.jar

# Suppress the updater prompt: the image is a build-time snapshot, not updated at run time
COPY prefs/ /root/.java/.userPrefs/net/imagej/updater/

# Workaround for https://github.com/mobie/mobie-viewer-fiji/issues/1336:
# MoBIE still needs AWS SDK v1, which Fiji no longer ships. Remove once fixed upstream.
ARG AWS_SDK_V1_VERSION=1.12.772
RUN cd "${FIJI_DIR}/jars" \
    && for a in aws-java-sdk-s3 aws-java-sdk-core aws-java-sdk-kms jmespath-java; do \
         f="${a}-${AWS_SDK_V1_VERSION}.jar"; \
         u="https://repo1.maven.org/maven2/com/amazonaws/${a}/${AWS_SDK_V1_VERSION}/${f}"; \
         curl -fsSLO "$u" || exit 1; \
         echo "$(curl -fsSL "${u}.sha1")  ${f}" | sha1sum -c - || exit 1; \
       done

ARG IMAGE_VERSION="dev"
ARG IMAGE_REVISION=""
ARG IMAGE_CREATED=""

LABEL org.opencontainers.image.title="RFI/CCP-volumeEM Fiji with MoBIE" \
      org.opencontainers.image.description="Ubuntu container with Fiji image viewer and MoBIE plugin" \
      org.opencontainers.image.authors="The Rosalind Franklin Institute, The Collaborative Computational Project for Volume Electron Microscopy" \
      org.opencontainers.image.source="https://github.com/rosalindfranklininstitute/fiji-mobie" \
      org.opencontainers.image.documentation="https://rosalindfranklininstitute.github.io/volume-em-container-documentation/software/fiji/" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:${UBUNTU_VERSION}" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}"

CMD ["/opt/Fiji/fiji-linux-x64"]
