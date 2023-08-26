#USE BLAST BINARIES FROM UMMIDOCK REPO 
FROM ummidock/blast_binaries:2.6.0-binaries 
WORKDIR /NGStools/
RUN apt-get update
RUN apt-get install -y git make libatlas-base-dev wget g++ build-essential autoconf libgsl-dev zlib1g-dev

# Install mamba
RUN wget "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
RUN bash Mambaforge-$(uname)-$(uname -m).sh

#GET FastANI
RUN git clone https://github.com/ParBLiSS/FastANI

WORKDIR /NGStools/FastANI
RUN pwd
RUN ls
RUN ./bootstrap.sh
RUN ./configure --prefix=/NGStools/
RUN make install

# install basic dependencies
RUN apt-get update && \
    apt-get install -y curl wget && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --gid 1000 docker && \
    adduser --uid 1000 --ingroup docker --home /home/docker --shell /bin/sh --disabled-password --gecos "" docker

# add yaml config to /conf
ADD conda/ /conf/

# create a conda env for each yaml config
RUN CONDA_DIR="/opt/conda" && \
    for file in $(ls /conf); do mamba env create --file /conf/$file; done

# clean up unused and cached pkgs
RUN CONDA_DIR="/opt/conda" && \
    mamba clean --all --yes && \
    rm -rf $CONDA_DIR/conda-meta && \
    rm -rf $CONDA_DIR/include && \
    rm -rf $CONDA_DIR/lib/python3.*/site-packages/pip && \
    find $CONDA_DIR -name '__pycache__' -type d -exec rm -rf '{}' '+'