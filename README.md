# WAN2.1 bootstrap

allows to run WAN2.1 from command line on Linux

- https://huggingface.co/Wan-AI/Wan2.1-T2V-14B
- https://github.com/Wan-Video/Wan2.1

## checkout

```shell
git clone --recurse-submodules -j8 git://github.com/mazurkin/wan21.git
```

## conda

https://docs.anaconda.com/miniconda/#miniconda-latest-installer-links

Download the [latest Miniconda version](https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh)

## installation

my GPU is NVIDIA A100 80GB (Ampere)

refer to the [Makefile](Makefile) for the details of the operations

```shell
# make an isolated Conda environment with Python 3.12
$ make env-init-conda

# install PyTorch and HuggingFace
$ make env-init-poetry

# install and compile flash-attn package (with FLASH_ATTENTION_FORCE_BUILD=TRUE it takes a lot)
$ FLASH_ATTENTION_FORCE_BUILD=FALSE make env-init-attn

# then install all WAN-2.1 packages
$ make env-init-wan21

# clone Gemma repository (you must get HF_TOKEN and you must agree to the Gemma's license on HF)
# 1. register on HuggingFace: https://huggingface.co
# 2. create access token: https://huggingface.co/settings/tokens
$ HF_TOKEN=hf_xxxyyyzzz make download-wan21
```

## run

refer to the [bin/wan21.sh](bin/wan21.sh) for the details of the operations

```shell
# in case you need to use the specific GPU
$ export CUDA_VISIBLE_DEVICES=0
```

```shell
# render video based on the prompt
$ bin/wan21.sh \
  --task t2v-14B \
  --prompt 'cinematic video of the dark basement filled with the chemical laboratory equipment in spotlit, something is boiling in the big glass vials, the camera is going through the laboratory and then we see the actor Aaron Paul, the camera is coming closer to him, he is turning his face to the camera and yells «Data-science, bitch!» and then smiles wide'
```
