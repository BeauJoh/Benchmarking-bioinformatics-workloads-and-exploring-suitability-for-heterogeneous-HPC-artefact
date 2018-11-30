# An Ubuntu environment configured for building the phd repo.
FROM nvidia/opencl:devel-ubuntu16.04
#FROM ubuntu:16.04

MAINTAINER Beau Johnston <beau.johnston@anu.edu.au>

# Disable post-install interactive configuration.
# For example, the package tzdata runs a post-installation prompt to select the
# timezone.
ENV DEBIAN_FRONTEND noninteractive

# Setup the environment.
ENV HOME /root
ENV USER docker
ENV LSB_SRC /libscibench-source
ENV LSB /libscibench
ENV LEVELDB_SRC /leveldb-source
ENV LEVELDB_ROOT /leveldb
ENV OCLGRIND_SRC /oclgrind-source
ENV OCLGRIND /oclgrind
ENV OCLGRIND_BIN /oclgrind/bin/oclgrind
ENV GIT_LSF /git-lsf
ENV PREDICTIONS /opencl-predictions-with-aiwc
ENV EOD /OpenDwarfs
ENV OCL_INC /opt/khronos/opencl/include
ENV OCL_LIB /opt/intel/opencl-1.2-6.4.0.25/lib64
ENV PANDOC /pandoc

# Install essential packages.
RUN apt-get update
RUN apt-get install --no-install-recommends -y software-properties-common \
    ocl-icd-opencl-dev \
    pkg-config \
    build-essential \
    git \
    make \
    zlib1g-dev \
    apt-transport-https \
    wget

# Install cmake -- newer version than with apt
RUN wget -qO- "https://cmake.org/files/v3.12/cmake-3.12.1-Linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr

# Install OpenCL Device Query tool
RUN git clone https://github.com/BeauJoh/opencl_device_query.git /opencl_device_query

# Install LibSciBench
RUN apt-get install --no-install-recommends -y llvm-3.9 llvm-3.9-dev clang-3.9 libclang-3.9-dev gcc g++
RUN git clone https://github.com/spcl/liblsb.git $LSB_SRC
WORKDIR $LSB_SRC
RUN ./configure --prefix=$LSB
RUN make
RUN make install

# Install leveldb (optional dependency for OclGrind)
RUN git clone https://github.com/google/leveldb.git $LEVELDB_SRC
RUN mkdir $LEVELDB_SRC/build
WORKDIR $LEVELDB_SRC/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=$LEVELDB_ROOT
RUN make
RUN make install

# Install OclGrind
RUN git clone https://github.com/BeauJoh/Oclgrind.git $OCLGRIND_SRC

RUN mkdir $OCLGRIND_SRC/build
WORKDIR $OCLGRIND_SRC/build
ENV CC clang-3.9
ENV CXX clang++-3.9

RUN cmake $OCLGRIND_SRC -DUSE_LEVELDB=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLLVM_DIR=/usr/lib/llvm3.9/lib/cmake -DCLANG_ROOT=/usr/lib/clang/3.9.1 -DCMAKE_INSTALL_PREFIX=$OCLGRIND

RUN make
RUN make install

# Install R and model dependencies
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu cosmic-cran35/'
RUN add-apt-repository ppa:marutter/rrutter3.5
RUN apt-get update
RUN apt-get install -y --no-install-recommends r-base
RUN apt-get install --no-install-recommends -y libcurl4-openssl-dev libssl-dev liblapack-dev libblas-dev gfortran
RUN Rscript -e "install.packages('devtools',repos = 'http://cran.us.r-project.org');"
RUN Rscript -e "install.packages('knitr',repos = 'http://cran.us.r-project.org');"
RUN Rscript -e "devtools::install_github('RcppCore/Rcpp')"
RUN Rscript -e "devtools::install_github('RcppCore/RcppEigen')"
RUN Rscript -e "devtools::install_github('imbs-hl/ranger')"

# Install the git-lsf module
WORKDIR /downloads
RUN wget https://github.com/git-lfs/git-lfs/releases/download/v2.5.1/git-lfs-linux-amd64-v2.5.1.tar.gz
RUN mkdir $GIT_LSF
RUN tar -xvf git-lfs-linux-amd64-v2.5.1.tar.gz --directory $GIT_LSF
WORKDIR $GIT_LSF
RUN ./install.sh
RUN git lfs install
# Install the R model
RUN git clone https://github.com/BeauJoh/opencl-predictions-with-aiwc.git $PREDICTIONS

# Install beakerx
RUN apt-get install --no-install-recommends -y python3-pip python3-setuptools python3-dev libreadline-dev libpcre3-dev libbz2-dev liblzma-dev
RUN pip3 install --upgrade pip
RUN pip3 install simplegeneric tzlocal rpy2 requests beakerx \
    && beakerx install

# Install R module for beakerx
RUN Rscript -e "devtools::install_github('IRkernel/IRkernel')"
RUN Rscript -e "IRkernel::installspec(user = FALSE)"
RUN Rscript -e "devtools::install_github('tidyverse/magrittr')"
RUN Rscript -e "devtools::install_github('tidyverse/ggplot2')"
RUN Rscript -e "devtools::install_github('tidyverse/tidyr')"
RUN Rscript -e "devtools::install_github('BeauJoh/fmsb')"
RUN Rscript -e "devtools::install_github('wilkelab/cowplot')"

# Install LetMeKnow
RUN pip3 install -U 'lmk==0.0.14'
# setup lmk by copying or add .lmkrc to /root/
# is used as: python3 ../opendwarf_grinder.py 2>&1 | lmk -
# or: lmk 'python3 ../opendwarf_grinder.py'

# Intel CPU OpenCL
RUN apt-get update -q && apt-get install --no-install-recommends -yq alien wget clinfo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download the Intel OpenCL CPU runtime and convert to .deb packages
RUN export RUNTIME_URL="http://registrationcenter-download.intel.com/akdlm/irc_nas/9019/opencl_runtime_16.1.1_x64_ubuntu_6.4.0.25.tgz" \
    && export TAR=$(basename ${RUNTIME_URL}) \
    && export DIR=$(basename ${RUNTIME_URL} .tgz) \
    && wget -q ${RUNTIME_URL} \
    && tar -xf ${TAR} \
    && for i in ${DIR}/rpm/*.rpm; do alien --to-deb $i; done \
    && rm -rf ${DIR} ${TAR} \
    && dpkg -i *.deb \
    && rm *.deb

RUN mkdir -p /etc/OpenCL/vendors/ \
    && echo "$OCL_LIB/libintelocl.so" > /etc/OpenCL/vendors/intel.icd

# Let the system know where the OpenCL library can be found at load time.
ENV LD_LIBRARY_PATH $OCL_LIB:$LD_LIBRARY_PATH

# Install EOD
RUN apt-get update && apt-get install --no-install-recommends -y autoconf libtool automake
RUN git clone https://github.com/BeauJoh/OpenDwarfs.git $EOD
WORKDIR $EOD
RUN ./autogen.sh
RUN mkdir build
WORKDIR $EOD/build
RUN ../configure --with-libscibench=$LSB
RUN make

# Install Pandoc and Latex to build the paper
RUN apt-get install --no-install-recommends -y lmodern texlive-latex-recommended texlive-fonts-recommended texlive-latex-extra texlive-science python-pip python-dev
RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | python
RUN pip2 install setuptools && pip2 install wheel && pip2 install pandocfilters pandoc-fignos
WORKDIR $PANDOC
RUN wget https://github.com/jgm/pandoc/releases/download/1.19.2/pandoc-1.19.2-1-amd64.deb && apt-get install -y ./pandoc-1.19.2-1-amd64.deb
RUN wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.0.0/linux-ghc8-pandoc-2-0.tar.gz
RUN tar -xvf linux-ghc8-pandoc-2-0.tar.gz
RUN mv pandoc-crossref /usr/bin/

#container variables and startup...
WORKDIR /workspace
ENV LD_LIBRARY_PATH "${OCLGRIND}/lib:${LSB}/lib:./lib:${LD_LIBRARYPATH}"
ENV PATH "${PATH}:${OCLGRIND}/bin}"

#start beakerx/jupyter by default
#CMD ["beakerx","--allow-root"]

CMD ["/bin/bash"]

