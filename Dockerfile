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
                    nano \
                    git && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
                    nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install FSL
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
  | tar -xz -C /usr/share/fsl --strip-components 1

ENV PATH="${FSLDIR}/bin:$PATH"
ENV FSLOUTPUTTYPE="NIFTI_GZ"

# Install c3d
ENV C3DPATH="/opt/convert3d-nightly" \
    PATH="/opt/convert3d-nightly/bin:$PATH"
RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-nightly \
    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-nightly --strip-components 1

# Install workbench
#RUN apt-get update && \
#    apt-get install -y connectome-workbench=1.2.3
ENV WBPATH=/usr/share/workbench
RUN    curl -ssL -o ${WBPATH}.zip "https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.4.2.zip"
RUN    unzip ${WBPATH}.zip -d /usr/share
ENV PATH=$WBPATH/bin_linux64:$PATH

# Install ANTs 2.2.0 (NeuroDocker build)
ENV ANTSPATH=/usr/share/ants
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz" \
   | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

# Installing and setting up miniconda
RUN curl -sSLO https://repo.continuum.io/miniconda/Miniconda3-4.5.12-Linux-x86_64.sh && \
    bash Miniconda3-4.5.12-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-4.5.12-Linux-x86_64.sh
ENV PATH=/usr/local/miniconda/bin:$PATH

# Install python packages
RUN conda install -y python=3.7.1 \
                     numpy=1.15.4 \
                     scipy=1.2.0 \
                     mkl=2019.1 \
                     mkl-service \
                     pytest \
                     scikit-learn=0.20.2 \
                     matplotlib=2.2.3 \
                     pandas=0.24.0 \
                     libxml2=2.9.9 \
                     graphviz=2.40.1 \
                     traits=4.6.0 \
                     zlib; sync &&  \
    chmod -R a+rX /usr/local/miniconda; sync && \
    chmod +x /usr/local/miniconda/bin/*; sync && \
    conda build purge-all; sync && \
    conda clean -tipsy && sync

# Install Flywheel Python SDK
RUN pip install --no-cache flywheel-sdk \
 && pip install --no-cache jinja2 \
 && pip install --no-cache nilearn

COPY manifest.json ${FLYWHEEL}/manifest.json
COPY heatmap_run.py ${FLYWHEEL}/heatmap_run.py
COPY . ${FLYWHEEL}/
RUN chmod +x ${FLYWHEEL}/*
RUN chmod +x ${FLYWHEEL}/src/*

# Set the entrypoint
ENTRYPOINT ["/flywheel/v0/heatmap_run.py"]
