SHELL := /bin/bash
ROOT  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

CONDA_ENV_NAME  = wan21

# https://huggingface.co/Lightricks/LTX-2/tree/main
LTX2_MODEL     ?= ltx-2-19b-dev.safetensors
LTX2_DISTILLED ?= ltx-2-19b-distilled-lora-384.safetensors
LTX2_UPSCALER  ?= ltx-2-spatial-upscaler-x2-1.0.safetensors

# https://huggingface.co/google/gemma-3-12b-it (you have to accept the license)
LTX2_GEMMA     ?= google/gemma-3-12b-it

# remote host and path for rsync
RSYNC_HOST     ?= pp-wan21
RSYNC_PATH     ?= projects/wan21

# -----------------------------------------------------------------------------
# conda environment
# -----------------------------------------------------------------------------

.DEFAULT_GOAL = env-shell

.PHONY: env-init-conda
env-init-conda:
	@conda create --yes --copy --name "$(CONDA_ENV_NAME)" \
		conda-forge::python=3.12.12 \
		conda-forge::poetry=2.2.1

.PHONY: env-init-ltx2
env-init-ltx2:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/LTX-2" \
		pip install -e packages/ltx-core
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/LTX-2" \
		pip install -e packages/ltx-pipelines

.PHONY: env-shell
env-shell:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/LTX-2" \
		bash

.PHONY: env-info
env-info:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		conda info

.PHONY: env-remove
env-remove:
	@conda env remove --yes --name "$(CONDA_ENV_NAME)"

# -----------------------------------------------------------------------------
# run
# -----------------------------------------------------------------------------

.PHONY: gemma
gemma:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		hf download "$(LTX2_GEMMA)" --local-dir "$(ROOT)/models/gemma"

.PHONY: models
models:
	@wget --timestamping --continue \
		--output-document=$(ROOT)/models/$(LTX2_UPSCALER) \
		'https://huggingface.co/Lightricks/LTX-2/resolve/main/$(LTX2_UPSCALER)?download=true'
	@wget --timestamping --continue \
		--output-document=$(ROOT)/models/$(LTX2_DISTILLED) \
		'https://huggingface.co/Lightricks/LTX-2/resolve/main/$(LTX2_DISTILLED)?download=true'
	@wget --timestamping --continue \
		--output-document=$(ROOT)/models/$(LTX2_MODEL) \
		'https://huggingface.co/Lightricks/LTX-2/resolve/main/$(LTX2_MODEL)?download=true'

.PHONY: render
render:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		python -m ltx_pipelines.ti2vid_two_stages \
			--checkpoint-path "${ROOT}/models/$(LTX2_MODEL)" \
			--distilled-lora "${ROOT}/models/$(LTX2_DISTILLED)" \
			--spatial-upsampler-path "${ROOT}/models/$(LTX2_UPSCALER)" \
			--gemma-root "$(ROOT)/models/gemma" \
			--prompt "${PROMPT}" \
			--image "$(ROOT)/assets/aaron_paul.jpg" 0 0.6 \
			--width 1920 \
			--height 1024 \
			--frame-rate 24 \
			--num-frames 481 \
			--output-path "output.mp4"

# -----------------------------------------------------------------------------
# rsync
# -----------------------------------------------------------------------------

.PHONY: rsync-push
rsync-push:
	@rsync -avz \
		--exclude='/.git' \
		--exclude='/.idea' \
		--exclude='/cache/*' \
		--exclude='/target/*' \
		--exclude='/models/*' \
		--exclude='*.log' \
		--exclude='.ipynb_checkpoints' \
		'$(ROOT)/' \
		'$(RSYNC_HOST):$(RSYNC_PATH)'

.PHONY: rsync-pull
rsync-pull:
	@rsync -avz \
		--exclude='/.git' \
		--exclude='/.idea' \
		--exclude='/cache/*' \
		--exclude='/target/*' \
		--exclude='/models/*' \
		--exclude='*.log' \
		--exclude='.ipynb_checkpoints' \
		'$(RSYNC_HOST):$(RSYNC_PATH)' \
		'$(ROOT)/'

# -----------------------------------------------------------------------------
# browsing
# -----------------------------------------------------------------------------

.PHONY: browse
browse:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		python3 -m http.server --bind "0.0.0.0" "18181"
