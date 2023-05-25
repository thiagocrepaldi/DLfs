# Deep Learning From Scratch (aka DLfs)

Deep Learning From Scratch is a tool that creates a Docker image with the
most used frameworks and libraries used by PyTorch and ONNX Runtime engineers at Microsoft.

The following projects are compiled from source:

* [Detectron2](https://github.com/facebookresearch/detectron2)
  * Source-code at /opt/detectron2
  * With CUDA support
* [ONNX](https://github.com/onnx/onnx)
  * Source-code at /opt/onnx
* [ONNX Script](https://github.com/microsoft/onnxscript)
  * Source-code at /opt/onnxscript
* [ONNX Runtime](https://github.com/mirosoft/onnxruntime)
  * Source-code at /opt/onnxruntime
  * With CUDA support
* [Open MPI](https://github.com/open-mpi/ompi)
  * Source-code not kept
  * Version 4.0.4
* [Pytorch](https://github.com/pytorch/pytorch)
  * Source-code at /opt/pytorch
  * With CUDA support
* [Torch Audio](https://github.com/pytorch/audio)
  * Source-code at /opt/torchaudio
  * With CUDA support
* [Torch Text](https://github.com/pytorch/text)
  * Source-code at /opt/torchtext
  * With CUDA support
* [Torch Vision](https://github.com/pytorch/vision)
  * Source-code at /opt/torchvision
  * With CUDA support

Although all source-code (and compiled files) are kept inside the image for easy access/recompilation, they are also pip-installed on the default (aka base) /opt/conda miniconda3 environment

## Building the docker image

The entry point for the build script is docker_build.sh, which has the following usage interface:

```bash
./docker_build.sh
                [ --torchaudio ]   # github.com/pytorch/audio commit/branch/tag (default is main)
                [ --base ]         # Docker image (default is ptebic.azurecr.io/internal/azureml/aifx/nightly-ubuntu2004-cu117-py38-torch210dev:latest)
                [ --cuda ]         # CUDA version (default is 11.7.0)
                [ --detectron2 ]   # github.com/facebookresearch/detectron2 commit/branch/tag (default is main)
                [ --torchtext ]    # github.com/pytorch/text commit/branch/tag (default is main)
                [ --dockerfile ]   # Dockerfile name within root folder (default is Dockerfile)
                [ --target ]       # Docker build target (default is __ALL__)
                                        # One of (__ALL__, __LAST__, os, conda, onnx, torch, torchtext, torchaudio, torchvision, detectron2, onnxruntime)
                                        #         __ALL__ must be set to build all targets available (only for multi-stage Dockerfile)
                                        #         __LAST__ must be set to build the last stage which combines all previous (only for multi-stage Dockerfile)
                [ --id ]           # Unique ID to be added to the resulting Docker image name (default is YYYYMMDD)
                [ --openmpi ]      # Builds open MPI 4.0 from source (tarball) (default is 1)
                [ --protobuf ]     # Builds Protobuf from source (tarball) (default is 1)
                [ --onnx ]         # github.com/onnx/onnx commit/branch/tag (default is main)
                [ --python ]       # python version (default is 3.8)
                [ --onnxruntime ]  # github.com/microsoft/onnxruntime commit/branch/tag (default is main)
                [ --torch ]        # github.com/pytorch/torch commit/branch/tag (default is main)
                [ --push ]         # Push image after it is built (default is 1)
                [ --torchvision ]  # github.com/pytorch/torchvision commit/branch/tag (default is main)
                [ --onnxscript ]   # github.com/microsoft/onnxscript commit/branch/tag (default is main)
                [ -h | --help  ]   # This message :)
```

**IMPORTANT:** ALL parameters (except `--help`), **MUST** be specified. If you know how to getopts to play nice with optional arguments, please contribute. It would be great to have default values and only specifying the ones we care about!

### Access to private base images

In order to use private base images, such as Azure Container for PyTorch (ACPT)'s internal images,
you must be authenticate to the Azure CR service before calling `docker_build.sh`.

The first step is to authenticate to Docker hub registry or Azure CR.
The snippet below shows an example for Azure CR:

```bash
az login --use-device-code
```

One authenticated to the registry, you need to authenticate against the desired repository.
The snippet below shows an example for ACPT:

```bash
az acr login --name ptebic
```

After both steps, you are ready to pull image from your private repo. Enjoy!

### Example using ACPT's private CUDA image (nightly)

Below is an example on how to build the docker image with all projects pointing to their latest development branch (aka main).
It assumes you have authenticated your session on ACPT's registry.

```bash
docker_build.sh \
  --torchaudio main \
  --base ptebic.azurecr.io/internal/azureml/aifx/nightly-ubuntu2004-cu117-py38-torch210dev:latest \
  --cuda 11.7.0 \
  --detectron2 main \
  --torchtext main \
  --dockerfile Dockerfile \
  --target __ALL__ \
  --id 20230518 \
  --protobuf 1 \
  --openmpi 0 \
  --onnx main \
  --python 3.8 \
  --onnxruntime main \
  --torch   main \
  --push  0 \
  --torchvision  main \
  --onnxscript  main
```

### Example using ACPT's private CUDA image (stable)

Below is an example on how to build the docker image with stable releases for all projects.
It assumes you have authenticated your session on ACPT's registry.

```bash
docker_build.sh \
  --torchaudio v2.0.2 \
  --base ptebic.azurecr.io/public/azureml/aifx/stable-ubuntu2004-cu117-py39-torch201:latest \
  --cuda 11.7.0 \
  --detectron2 main \
  --torchtext v0.15.1 \
  --dockerfile Dockerfile \
  --target __ALL__ \
  --id 20230518 \
  --protobuf 0 \
  --openmpi 0 \
  --onnx v1.14.0 \
  --python 3.8 \
  --onnxruntime v1.14.1 \
  --torch   v2.0.1 \
  --push  0 \
  --torchvision  v0.15.1 \
  --onnxscript  main
```

### Example using NVIDIA's public CUDA image (WORK IN PROGRESS)

Below is an example on how to build the docker image with all projects pointing to their latest development branch (aka main).

```bash
docker_build.sh \
  --torchaudio main \
  --base nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 \
  --cuda 11.7.1 \
  --detectron2 main \
  --torchtext main \
  --dockerfile Dockerfile \
  --target __ALL__ \
  --id 20230518 \
  --protobuf 1 \
  --openmpi 0 \
  --onnx main \
  --python 3.10 \
  --onnxruntime main \
  --torch   main \
  --push  0 \
  --torchvision  main \
  --onnxscript  main
```

## Limitations

This is just an initial prototype, so only a few variations of OS, CUDA and Github projects were tested. In special:

* Only the development branches of the listed projects above were tested
  * Stable releases should work, as long as dependencies are properly satisfied by `scripts/101_install_python_deps.sh`

* The following OS + CUDA environments were tested
  * Ubuntu 20.04 + CUDA 11.3.1 (nvidia:cuda base image)
  * Ubuntu 20.04 + CUDA 11.7.0 (ACPT base image)
  * Ubuntu 22.04 + CUDA 11.7.1 (nvidia:cuda base image)

* Only CUDA builds are supported
  * ROCM and CPU-only might work, but were not tested

* The following python versions are supported:
  * 3.8
  * 3.9
  * 3.10 were tested
  * Any version >= 3.7 should work, if `scripts/101_install_python_deps.sh` succeeds

* Each project may have custom build flags, but they are not exposed to docker_build.sh yet
  * Some flags are available as `ARG` at `Dockerfile` and can be manually overridden
  * Others flags are directly hard-coded to the `RUN` at `Dockerfile` or each project's bash script

* There is no official pre-built docker images from Microsoft
  * The plan is to have nightly builds publishing Docker images with latest development branches
  * Until there, you might find some images at *https://hub.docker.com/r/thiagocrepaldi/dlfs/tags*

More projects, OSes, execution providers (CPU, ROCM, etc) can be added as the project matures.
Extensions to the build script should be added to allow custom builds too.

## Contact

Send an email to pytorch-onnx-export@microsoft.com with feature requests, bug reports or any feedback.
