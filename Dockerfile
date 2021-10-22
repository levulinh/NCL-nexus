FROM nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04 AS builder
COPY . /nexus
RUN apt-get update \
 && apt-get install -y unzip build-essential git autoconf automake libtool pkg-config curl make zlib1g-dev wget \
                       libswscale-dev libjpeg-dev libpng-dev libsm6 libxext6 libxrender-dev \
                       python-dev python-pip \
                       libcurl4-openssl-dev \
                       software-properties-common python3-pip python3.7 python3.7-dev\
 && python3.7 -m pip install --upgrade six 'numpy<1.19.0' wheel setuptools keras_applications --no-deps keras_preprocessing --no-deps mock 'future>=0.17.1' \
 && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - \
 && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' \
 && apt-get update \
 && apt-get install -y cmake \
 && rm -rf /var/lib/apt/lists/*

RUN /nexus/build-deps.bash \
 && /nexus/build-tensorflow.bash \
 && cd /nexus/build-dep-install/tensorflow/ \
 && rm -rf c cc compiler core stream_executor \
 && rm -rf /nexus/build-dep-src /root/.cache/bazel

RUN mkdir /nexus/build \
 && cd /nexus/build \
 && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebugInfo -DCUDA_PATH=/usr/local/cuda-11.0 -DUSE_TENSORFLOW=ON -DUSE_CAFFE2=OFF \
 && make -j$(nproc)
 
RUN find /nexus/build-dep-install -type d \( -name "bin" -o -name "include" -o -name "share" \) -exec rm -rf {} + \
 && find /nexus/build-dep-install -type f -name "*.a" -exec rm -f {} + \
 && rm -rf /nexus/build-dep-install/bazel \
 && cd /nexus/build \
 && rm -rf CMakeFiles gen *.a *.txt *.cmake Makefile bench_tfshare test_*


FROM nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04
LABEL maintainer="Lequn Chen <lqchen@cs.washington.edu>"
COPY --from=builder /nexus /nexus
RUN apt-get update \
 && apt-get install -y libswscale4 libjpeg8 libpng16-16 libjpeg-dev zlib1g-dev \
                       software-properties-common wget  python3-pip python3.7 python3.7-dev \
 && add-apt-repository -y ppa:deadsnakes/ppa \
 && apt-get update \
 && python3.7 -m pip install --upgrade numpy protobuf pyyaml Pillow \
 && python3.7 -m pip install --editable /nexus/python \
 && python3.7 -m pip uninstall -y pip \
 && apt-get purge -y python3.7-dev software-properties-common wget \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /root/.cache/pip
WORKDIR /nexus
