# Sets Ubuntu Version and noninterctive mode on update
ARG UBUNTU_VERSION=24.04
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Europe/London

# From https://packages.ubuntu.com/ 
# Version Locking packages in a container is good practise. 
ARG CURL_VERSION="8.5.0-2ubuntu10.6"
ARG UNZIP_VERSION="6.0-28ubuntu4.1"
ARG OPENJDK_8_JRE_HEADLESS_VERSION="8u442-b06~us1-0ubuntu1~24.04"
ARG LIBX11_DEV_VERSION="2:1.8.7-1build1"

FROM ubuntu:${UBUNTU_VERSION}
# Allow for accesing Arugments 
ARG CURL_VERSION
ARG UNZIP_VERSION
ARG OPENJDK_8_JRE_HEADLESS_VERSION
ARG LIBX11_DEV_VERSION

# Install required packages to get install and run fiji with mobie.
RUN apt-get -y update && apt-get install -y --no-install-recommends \
    curl=${CURL_VERSION} \
    unzip=${UNZIP_VERSION} \
    openjdk-8-jre-headless=${OPENJDK_8_JRE_HEADLESS_VERSION} \
    libx11-dev=${LIBX11_DEV_VERSION} \
    # Clean up and remove cache to reduce the image size.
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Get fiji-linux64 package
RUN curl -o fiji-linux64.zip -L  https://downloads.micron.ox.ac.uk/fiji_update/mirrors/fiji-latest/fiji-linux64.zip \
    # Get sums from another mirror in case the above mirror is compromised. 
    && curl -o fiji-linux64.zip.md5 -L https://downloads.imagej.net/fiji/latest/fiji-linux64.zip.md5 \
    && curl -o fiji-linux64.zip.sha1 -L https://downloads.imagej.net/fiji/latest/fiji-linux64.zip.sha1 \
    && curl -o fiji-linux64.zip.sha256 -L https://downloads.imagej.net/fiji/latest/fiji-linux64.zip.sha256 \
    && curl -o fiji-linux64.zip.sha512 -L https://downloads.imagej.net/fiji/latest/fiji-linux64.zip.sha512

# Add filename to checksums and check they are as expected
RUN sed -i 's/$/  fiji-linux64.zip/' fiji-linux64.zip.md5 \
    && sed -i 's/$/  fiji-linux64.zip/' fiji-linux64.zip.sha1 \
    && sed -i 's/$/  fiji-linux64.zip/' fiji-linux64.zip.sha256 \
    && sed -i 's/$/  fiji-linux64.zip/' fiji-linux64.zip.sha512 \
    # Check fiji-linux64.zip has the same hash as expected
    && md5sum -c fiji-linux64.zip.md5 \
    && sha1sum -c fiji-linux64.zip.sha1 \
    && sha256sum -c fiji-linux64.zip.sha256 \
    && sha512sum -c fiji-linux64.zip.sha512 \
    # remove the checksum files to reduce image size
    && rm fiji-linux64.zip.*

# Unzip Contents
RUN unzip fiji-linux64.zip -d fiji \
    # Remove Zip to reduce image size
    && rm fiji-linux64.zip

# Install MOBIE 
RUN fiji/Fiji.app/fiji-linux-x64 --update edit-update-site MoBIE https://sites.imagej.net/MoBIE/ \
    && fiji/Fiji.app/fiji-linux-x64 --update update 

# Move the fiji app the the usr/local/bin
RUN mv fiji/Fiji.app/ /usr/local/bin/. \
    # Removes Warning that Fiji is not updatable by making the contents of the folder mutable. 
    && chattr -i -R /usr/local/bin/Fiji.app

# Remove uneeded programs to reduce image size
RUN apt-get purge --autoremove unzip curl -y 

# Entry Command on Run this launches Fiji. 
CMD ["/usr/local/bin/Fiji.app/fiji-linux-x64"]