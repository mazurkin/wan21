#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o monitor
set -o noglob

# calculate the current directory
SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
declare -r SCRIPT_DIR

# calculate the package directory
PACKAGE_DIR=$(dirname -- "${SCRIPT_DIR}")
declare -r PACKAGE_DIR

# calculate the model dir
MODEL_DIR="${PACKAGE_DIR}/models"
declare -r MODEL_DIR

# python settings
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# torch settings
export PYTORCH_ALLOC_CONF=expandable_segments:True

exec conda run --no-capture-output --live-stream --name ltx2 --cwd "${PACKAGE_DIR}" \
    python -m ltx_pipelines.ti2vid_two_stages \
        --checkpoint-path "${MODEL_DIR}/ltx-2-19b-dev.safetensors" \
        --distilled-lora "${MODEL_DIR}/ltx-2-19b-distilled-lora-384.safetensors" \
        --spatial-upsampler-path "${MODEL_DIR}/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
        --gemma-root "${MODEL_DIR}/gemma" \
        --width 1920 \
        --height 1024 \
        --frame-rate 24 \
        --num-frames 481 \
        --output-path "output.mp4" \
        "$@"
