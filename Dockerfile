ARG CUDA_VERSION=11.8.0
ARG OS_VERSION=22.04
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION}

ARG CUDA_VERSION
ARG OS_VERSION

# Define username, user uid and gid
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
ENV CUDA_HOME="/usr/local/cuda"
ENV PATH="${PATH}:/home/${USERNAME}/.local/bin"

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    ffmpeg \
    git \
    libatlas-base-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libhdf5-dev \
    libcgal-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libgflags-dev \
    libglew-dev \
    libgoogle-glog-dev \
    libmetis-dev \
    libprotobuf-dev \
    libqt5opengl5-dev \
    libsqlite3-dev \
    libsuitesparse-dev \
    nano \
    protobuf-compiler \
    python-is-python3 \
    python3.10-dev \
    python3-pip \
    qtbase5-dev \
    sudo \
    vim-tiny \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -d /home/${USERNAME} --shell /usr/bin/bash \
    && echo "${USERNAME}:password" | chpasswd \
    && usermod -aG sudo ${USERNAME}

# Create workspace folder and change ownership
RUN mkdir /workspace && chown ${USER_UID}:${USER_GID} /workspace

# Switch to new user and workdir
USER ${USER_UID}
WORKDIR /home/${USERNAME}

# Upgrade pip and install packages
RUN python3.10 -m pip install --no-cache-dir --upgrade pip setuptools

# Install PyTorch and CUDA toolkit
RUN python3.10 -m pip install torch==2.1.2+cu118 torchvision==0.16.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118

RUN python3.10 -m pip install "numpy<2"

# Install tiny-cuda-nn
ARG CUDA_ARCHITECTURES=86
ENV TCNN_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}
RUN python3.10 -m pip install ninja git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch

# Install nerfstudio
RUN git clone https://github.com/nerfstudio-project/nerfstudio.git \
    && cd nerfstudio \
    && python3.10 -m pip install -e .

# Install cuml (for global clustering)
RUN python3.10 -m pip install \
    --extra-index-url=https://pypi.nvidia.com \
    cudf-cu11==24.6.* dask-cudf-cu11==24.6.* cuml-cu11==24.6.* \
    cugraph-cu11==24.6.* cuspatial-cu11==24.6.* cuproj-cu11==24.6.* \
    cuxfilter-cu11==24.6.* cucim-cu11==24.6.* pylibraft-cu11==24.6.* \
    raft-dask-cu11==24.6.* cuvs-cu11==24.6.*

# Install GARField
RUN git clone https://github.com/chungmin99/garfield.git \
    && cd garfield \
    && python3.10 -m pip install -e .

RUN python3.10 -m pip install rawpy==0.19.1 && python3 -m pip install numpy==1.26.4
# Set working directory to workspace
WORKDIR /workspace

CMD ["/bin/bash", "-l"]