# Use Ubuntu 16.04 LTS
FROM ubuntu:xenial-20161213
MAINTAINER Will Tackett <william.tackett@pennmedicine.upenn.edu>

# Make directory for flywheel spec (v0)
ENV FLYWHEEL /flywheel/v0
RUN mkdir -p ${FLYWHEEL}

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    curl \
                    bzip2 \
                    ca-certificates \
                    xvfb \
                    cython3 \
                    build-essential \
                    autoconf \
                    libtool \
                    pkg-config \
                    jq \
                    zip \
                    unzip \
                    git && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
                    nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### FSL ####
ENV FSLDIR="/usr/share/fsl"
RUN apt-get update -qq \
  && apt-get install -y -q --no-install-recommends \
         bc \
         dc \
         file \
         libfontconfig1 \
         libfreetype6 \
         libgl1-mesa-dev \
         libglu1-mesa-dev \
         libgomp1 \
         libice6 \
         libxcursor1 \
         libxft2 \
         libxinerama1 \
         libxrandr2 \
         libxrender1 \
         libxt6 \
         wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && echo "Downloading FSL ..." \
  && mkdir -p /usr/share/fsl \
  && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.9-centos6_64.tar.gz \
  | tar -xz -C /usr/share/fsl --strip-components 1 \
  && echo "Installing FSL conda environment ..." \
  && bash /usr/share/fsl/etc/fslconf/fslpython_install.sh -f /usr/share/fsl

ENV PATH="${FSLDIR}/bin:$PATH"

### c3d ###
ENV C3DDIR="/usr/share/c3d"
MKDIR ${C3DDIR}
COPY /usr/local/c3d/bin/ ${C3DDIR}/

ENV PATH="${C3DDIR}/bin:$PATH"

### Flywheel SDK ###
RUN pip install --no-cache flywheel-sdk

COPY manifest.json ${FLYWHEEL}/manifest.json
COPY run.sh ${FLYWHEEL}/run.sh
COPY . ${FLYWHEEL}/
RUN chmod +x ${FLYWHEEL}/*

# Set the entrypoint
ENTRYPOINT ["/flywheel/v0/run.sh"]
