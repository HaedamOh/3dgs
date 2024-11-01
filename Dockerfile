ARG UBUNTU_VERSION=22.04
ARG NVIDIA_CUDA_VERSION=11.8.0

FROM nvidia/cuda:${NVIDIA_CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME="/usr/local/cuda"


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    ffmpeg \
    git \
    python-is-python3 \
    python3.10-dev \
    python3-pip \
    vim \
    libglm-dev \ 
    wget && \
    rm -rf /var/lib/apt/lists/*
RUN python -m pip install --no-cache-dir --upgrade pip setuptools pathtools promise pybind11

RUN python -m pip install --no-cache-dir \
    torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118


ENV GID=1007
ENV UID=1007
ENV UNAME=docker_dev
RUN addgroup --gid $GID $UNAME && \
    adduser --disabled-password --gecos '' --uid $UID --gid $GID $UNAME && \
    groupadd -g 998 docker && \
    groupadd -g 1013 oxford_spires && \
    groupadd -g 1014 nerfstudio && \
    usermod -aG docker,oxford_spires,nerfstudio ${UNAME}


ARG GAUSSIAN_SPLATTING_DIR=/home/docker_dev/gaussian-splatting
WORKDIR ${GAUSSIAN_SPLATTING_DIR}


COPY ./requirements.txt ${GAUSSIAN_SPLATTING_DIR}/requirements.txt
RUN pip install -r requirements.txt


# Clone the repositories for submodules 
COPY ./submodules ${GAUSSIAN_SPLATTING_DIR}/submodules
RUN pip install submodules/diff-gaussian-rasterization && \
    pip install submodules/simple-knn


# COPY ./LangSplat/ ${GAUSSIAN_SPLATTING_DIR}/LangSplat
# COPY ./pyproject.toml ${GAUSSIAN_SPLATTING_DIR}/pyproject.toml
# RUN pip install -e .
# Make the outputs of the container match the host

RUN chown -R ${UID}:${GID} ${GAUSSIAN_SPLATTING_DIR}/*
USER ${UNAME}
RUN echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u@docker-\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> ~/.bashrc

CMD ["/bin/bash"]
