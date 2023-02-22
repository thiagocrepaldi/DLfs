# DLfs

Deep Learning From Scratch is a tool that creates a Docker image with the
most used frameworks and libraries used by PyTorch and ONNX Runtime engineers at Microsoft.

The following projects are compiled from source:

* [Detectron2](https://github.com/facebookresearch/detectron2)
  * Source-code at /opt/detectron2
  * With CUDA support
* [ONNX](https://github.com/onnx/onnx)
  * Source-code at /opt/onnx
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
                [ -a | --torchaudio ]   # github.com/pytorch/audio commit/branch/tag (default is main)
                [ -b | --base_os ]      # Docker image (default is nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04)
                [ -c | --cuda ]         # CUDA version (default is 11.7.1)
                [ -d | --detectron2 ]   # github.com/facebookresearch/detectron2 commit/branch/tag (default is main)
                [ -e | --torchtext ]    # github.com/pytorch/text commit/branch/tag (default is main)
                [ -f | --dockerfile ]   # Dockerfile name within root folder (default is Dockerfile)
                [ -g | --target ]       # Docker build target (default is __ALL__)
                                        # One of (__NONE__, __ALL__, __LAST__, os, conda, onnx, torch, torchtext, torchaudio, torchvision, detectron2, onnxruntime)
                                        #         __NONE__ must be set for single-stage DOCKERFILE (only for single-stage Dockerfile)
                                        #         __ALL__ must be set to build all targets available (only for multi-stage Dockerfile)
                                        #         __LAST__ must be set to build the last stage which combines all previous (only for multi-stage Dockerfile)
                [ -i | --id ]           # Unique ID to be added to the resulting Docker image name (default is YYYYMMDD)
                [ -m | --openmpi ]      # Builds open MPI 4.0 from source (tarball) (default is 1)
                [ -o | --onnx ]         # github.com/onnx/onnx commit/branch/tag (default is main)
                [ -p | --python ]       # python version (default is 3.10)
                [ -r | --onnxruntime ]  # github.com/microsoft/onnxruntime commit/branch/tag (default is main)
                [ -t | --torch ]        # github.com/pytorch/torch commit/branch/tag (default is master)
                [ -u | --push ]         # Push image after it is built (default is 1)
                [ -v | --torchvision ]  # github.com/pytorch/torchvision commit/branch/tag (default is main)
                [ -h | --help  ]        # This message :)
```

**IMPORTANT:** ALL parameters (except `-h`), **MUST** be specified. If you know how to getopts to play nice with optional arguments, please contribute. It would be great to have default values and only specifying the ones we care about!

### Example

Below is an example on how to build the docker image with all projects pointing to their latest development branch (aka main/master)

```bash
docker_build.sh -a main -b nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 -c 11.7.1 -d main -e main -o main -p 3.10 -r main -t master -v main -m 1 -f Dockerfile -i 20230301 -g __ALL__
```

## Limitations

This is just an initial prototype, so only a few variations of OS, CUDA and Github projects were tested. In special:

* Only the development branches of the listed projects above were tested

* Only Ubuntu 20.04 + CUDA 11.3.1 and Ubuntu 22.04 + CUDA 11.7.1 were tested

* Only CUDA builds are supported. ROCM and CPU-only were not tested

* Only Python 3.9 and 3.10 were tested
  * Any version >= 3.7 should work, if `scripts/install_python_deps.sh` succeeds

* Each project may have custom build flags, but they are not exposed to docker_build.sh yet
  * Some flags are available as `ARG` at `Dockerfile` and can be manually overriden
  * Others flags are directly hard-coded to the `RUN` at `Dockerfile` and probably should be refactored into `ARG` arguments.

* There is no official pre-built docker images from Microsoft
  * The plan is to have nightly builds publishing Docker images with latest development branches
  * Until there, you might find some images at *https://hub.docker.com/r/thiagocrepaldi/dlfs/tags*

More projects, OSes, execution providers (CPU, ROCM, etc) can be added as the project matures.
Extensions to the build script should be added to allow custom builds too.

## Contact

Send an email to pytorch-onnx-export@microsoft.com with feature requests, bug reports or any feedback.
