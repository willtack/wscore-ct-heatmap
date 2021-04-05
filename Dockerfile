FROM python:3.7
MAINTAINER Will Tackett <william.tackett@pennmedicine.upenn.edu>

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
#ENV WBPATH=/usr/share/workbench
#RUN    curl -ssL -o ${WBPATH}.zip "https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.4.2.zip"
#RUN    unzip ${WBPATH}.zip -d /usr/share
#ENV PATH=$WBPATH/bin_linux64:$PATH

# Install ANTs 2.2.0 (NeuroDocker build)
ENV ANTSPATH=/usr/share/ants
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz" \
   | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

# Install python packages
RUN pip install --no-cache flywheel-sdk==12.4.0 \
 && pip install --no-cache jinja2==2.10 \
 && pip install --no-cache nilearn==0.5.2 \
 && pip install --no-cache pathlib==1.0.1 \
 && pip install --no-cache matplotlib==3.03 \
 && pip install --no-cache antspyx==0.2.7 \
 && pip install --no-cache pytest==4.3.1 \
 && pip install --no-cache scikit-learn==0.22 \
 && pip install --no-cache pandas==1.2.3 \
 && pip install --no-cache numpy==1.20.1



# ENV C3DDIR="/usr/share/c3d/bin"
# #RUN mkdir ${C3DDIR}
# COPY resources/c3d/bin ${C3DDIR}/
# ENV PATH="${C3DDIR}:$PATH"

RUN mkdir /opt/scripts
COPY run.py /opt/scripts/run.py
COPY generate_report.py /opt/scripts/generate_report.py
RUN chmod +x /opt/scripts/*

RUN mkdir -p /opt/labelset
COPY labelset /opt/labelset

RUN mkdir -p /opt/html_templates
COPY html_templates /opt/html_templates

# Set the entrypoint
ENTRYPOINT ["python /opt/scripts/run.py"]
