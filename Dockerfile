# Pull base image.
FROM ubuntu:xenial-20200706

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    curl \
                    bzip2 \
                    ca-certificates \
                    xvfb \
                    build-essential \
                    autoconf \
                    libtool \
                    pkg-config \
                    dcm2niix \
                    jo \
                    jq \
                    git && \
    curl -sSL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
                    nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="DCMNII" \
      org.label-schema.description="Private DCM2NII Converter" \
      org.label-schema.url="http://sphub.net" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/nipreps/fmriprep" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"