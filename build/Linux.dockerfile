FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# From: https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Build_Instructions/Linux_Prerequisites
# Additions from bootstrap.py + dependencies for custom ppa.
RUN apt-get update && apt-get install --yes \
  alien \
  apt-transport-https \
  apt-utils \
  autoconf2.13 \
  autotools-dev \
  binutils-avr \
  build-essential \
  ccache \
  cdbs \
  debhelper \
  desktop-file-utils \
  fakeroot \
  gyp \
  hunspell-en-us \
  libasound2-dev \
  libcurl4-openssl-dev \
  libdbus-1-dev \
  libdbus-glib-1-dev \
  libffi-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libgl1-mesa-dev \
  libglib2.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer1.0-dev \
  libgtk-3-dev \
  libgtk2.0-dev \
  libiw-dev \
  libjack-dev \
  libnotify-dev \
  libnspr4-dev \
  libnss3-dev \
  libpango1.0-dev \
  libpulse-dev \
  libpython2-dev \
  libpython3-dev \
  libstartup-notification0-dev \
  libx11-dev \
  libx11-xcb-dev \
  libxext-dev \
  libxrender-dev \
  libxt-dev \
  lsb-release \
  make \
  mesa-common-dev \
  ninja-build \
  nodejs \
  pkg-config \
  python3-dbus \
  python3-dev \
  python3-pip \
  python3-setuptools \
  rpm \
  software-properties-common \
  sudo \
  unzip \
  uuid \
  wget \
  xvfb \
  yasm \
  zip

# Install clang + llvm version 10
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
 && add-apt-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-10 main" \
 && apt-get update \
 && apt-get install --yes clang-10 lldb-10 lld-10 clangd-10 libclang-10-dev

# Install awscli
RUN pip3 install awscli==1.17.5

# Install Mercurial
RUN pip3 install Mercurial==5.4.2

# Install aptly for ppa management
# RUN echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list \
#  && wget -qO - https://www.aptly.info/pubkey.txt | apt-key add - \
#  && apt-get update \
#  && apt-get install aptly --yes

# Install Rust toolchain version 1.41.1
ENV RUSTUP_HOME=/usr/local/rustup \
  CARGO_HOME=/usr/local/cargo \
  PATH=/usr/local/cargo/bin:$PATH

RUN wget "https://static.rust-lang.org/rustup/archive/1.22.0/x86_64-unknown-linux-gnu/rustup-init" \
 && echo "1875ea009c3284c147b3e06f10bb3b5764b7f18a6c82ce7c9e97bf5cece7c5b8 rustup-init" | sha256sum -c - \
 && chmod +x rustup-init \
 && ./rustup-init -y --no-modify-path --default-toolchain 1.41.1 \
 && rm rustup-init \
 && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
 && rustup --version \
 && cargo --version \
 && rustc --version

# Install cbindgen
RUN cargo install --version 0.14.3 cbindgen

# Install nasm 2.15 (see: https://www.nasm.us)
RUN mkdir -p /home/$user/nasm \
 && cd /home/$user/nasm \
 && wget --output-document=nasm.tar.xz --quiet "https://www.nasm.us/pub/nasm/releasebuilds/2.15.02/nasm-2.15.02.tar.xz" \
 && tar xf nasm.tar.xz \
 && cd nasm-2.15.02 \
 && sh configure \
 && sudo make install

ARG UID
ARG GID
ARG user
ENV HOME=/builds/worker \
    SHELL=/bin/bash \
    USER=worker \
    LOGNAME=worker \
    HOSTNAME=taskcluster-worker

# Declare default working folder
WORKDIR /builds/worker

# Enable passwordless sudo for users under the "sudo" group
RUN sed -i.bkp -e \
      's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
      /etc/sudoers

SHELL ["/bin/bash", "-l", "-c"]

# RUN cd /home/$user \
#  && hg clone https://hg.mozilla.org/projects/nspr \
#  && hg clone https://hg.mozilla.org/projects/nss \
#  && ./nss/build.sh
#
# RUN cd /home/$user/nspr \
#  && ./configure --with-mozilla --with-pthreads --enable-64bit \
#  && make \
#  && make install
#
# RUN cd /home/$user/nss \
#  && make BUILD_OPT=1 \
#       NSPR_INCLUDE_DIR=/home/$user/nspr/dist/include/nspr/ \
#       USE_SYSTEM_ZLIB=1 \
#       ZLIB_LIBS=-lz \
#       NSS_ENABLE_WERROR=0 \
#       USE_64=1 \
#  && make install

# Install Node.js (LTS = 12.x)
RUN wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo "deb https://deb.nodesource.com/node_12.x focal main" > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install --yes nodejs

RUN getent group $GID || groupadd $user --gid $GID && \
    useradd  $user --gid $GID -d /builds/worker && \
    mkdir -p /builds/worker/workspace
RUN chown -R $user /builds/worker/
USER $user
RUN id -u
RUN id -g
RUN whoami
ENV MOZ_FETCHES_DIR=/builds/worker/fetches/ \
    GECKO_PATH=/builds/worker/workspace \
    WORKSPACE=/builds/worker/workspace \
    TOOLTOOL_DIR=/builds/worker/fetches/

COPY configs /builds/worker/configs

WORKDIR $WORKSPACE
