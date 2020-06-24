FROM python:3.7
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
                    default-jdk \
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
#ENV C3DPATH="/opt/convert3d-nightly" \
#    PATH="/opt/convert3d-nightly/bin:$PATH"
#RUN echo "Downloading Convert3D ..." \
#    && mkdir -p /opt/convert3d-nightly \
#    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
#    | tar -xz -C /opt/convert3d-nightly --strip-components 1

# Install workbench
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

# Install python packages
RUN pip install --no-cache flywheel-sdk \
 && pip install --no-cache jinja2 \
 && pip install --no-cache nilearn \
 && pip install --no-cache pathlib \
 && pip install --no-cache matplotlib \
 && pip install --no-cache pytest

 ENV C3DDIR="/usr/share/c3d/bin"
 #RUN mkdir ${C3DDIR}
 COPY resources/c3d/bin ${C3DDIR}/
 ENV PATH="${C3DDIR}:$PATH"

COPY manifest.json ${FLYWHEEL}/manifest.json
COPY run.py ${FLYWHEEL}/run.py
COPY . ${FLYWHEEL}/
RUN chmod +x ${FLYWHEEL}/*
RUN chmod +x ${FLYWHEEL}/run.py
RUN chmod +x ${FLYWHEEL}/src/*

# ENV preservation for Flywheel Engine
RUN env -u HOSTNAME -u PWD | \
  awk -F = '{ print "export " $1 "=\"" $2 "\"" }' > ${FLYWHEEL}/docker-env.sh
RUN chmod +x ${FLYWHEEL}/docker-env.sh

# Set the entrypoint
ENTRYPOINT ["python /flywheel/v0/run.py"]
