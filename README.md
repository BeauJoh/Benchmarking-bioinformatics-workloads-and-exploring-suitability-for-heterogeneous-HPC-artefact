
Benchmarking bioinformatics workloads and exploring suitability for heterogeneous HPC
-------------------------------------------------------------------------------------

Note: This artefact also uses binder -- automatic cloud hosting of Jupyter workbooks with support for docker. So if you want to avoid all the steps mentioned below, simply click the binder badge.

[![Binder](https://mybinder.org/badge.svg)](https://mybinder.org/v2/gh/BeauJoh/Benchmarking-bioinformatics-workloads-and-exploring-suitability-for-heterogeneous-HPC-artefact.git/master
)

# Installation

This project uses Docker to facilitate reproducibility. As such, it has the following dependencies:

* Cuda 9.0 Runtime -- available [here](https://developer.nvidia.com/cuda-downloads)
* Docker -- available [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* nvidia-docker2, install instructions found [here](https://github.com/NVIDIA/nvidia-docker)
* Docker nvidia container, installed with: `sudo apt install nvidia-container-runtime`

# Build

To generate a docker image named workbook, run:

`docker build -t workbook .`

# Run

To start the docker image run:

`docker run --runtime=nvidia -it --mount src=`pwd`,target=/workspace,type=bind -p 8888:8888 --net=host workbook`

And run the codes with:
`cd /workspace`

`make`

`make test`

This generates a sample of the runtimes with libscibench and the AIWC metrics

For reproducibility, BeakerX has also been added for replicating results and for the transparency of analysis.
It is lauched by running:

`cd /workbook/codes`
`beakerx --allow-root`

from within the container and following the prompts to access it from the website front-end.

*Note* that if this node is accessed from an ssh session local ssh port forwarding is required and is achieved with the following:

`ssh -N -f -L localhost:8888:localhost:8888 <node-name>`

