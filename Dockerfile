FROM nvidia/cuda:12.6.0-cudnn-runtime-ubuntu22.04

# Настройки среды
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    HF_HOME=/workspace/models/huggingface \
    TORCH_HOME=/workspace/models/torch \
    COMFYUI_PATH=/opt/ComfyUI

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    python3-pip python3-dev python3-venv git wget curl \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Обновление Python инструментов
RUN python3 -m pip install --upgrade pip setuptools wheel

# 3. PyTorch (CUDA 12) + ONNX + Insightface
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install xformers insightface
RUN pip install onnxruntime-gpu --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# 4. Установка ComfyUI
WORKDIR ${COMFYUI_PATH}
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git . \
    && pip install --no-cache-dir -r requirements.txt

# 5. Установка Custom Nodes (Твой набор для Flux и апскейла)
WORKDIR ${COMFYUI_PATH}/custom_nodes
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone --depth 1 https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-SUPIR.git && \
    git clone --depth 1 https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git && \
    git clone --depth 1 https://github.com/chrisgoringe/cg-use-everywhere.git && \
    git clone --depth 1 https://github.com/XLabs-AI/x-flux-comfyui.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-FluxTrainer.git && \
    git clone --depth 1 https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git

# Установка зависимостей всех нод
RUN for dir in ./*/; do \
        if [ -f "${dir}requirements.txt" ]; then \
            pip install --no-cache-dir -r "${dir}requirements.txt" || true; \
        fi; \
    done

# 6. Предустановленные LoRA (скачиваем в образ для переноса на диск)
RUN mkdir -p ${COMFYUI_PATH}/models/loras
WORKDIR ${COMFYUI_PATH}/models/loras
RUN wget -q https://civitai.com/api/download/models/753339 -O "Phlux_Photorealism.safetensors" && \
    wget -q https://civitai.com/api/download/models/993999 -O "Amateur_Photography_Flux.safetensors" && \
    wget -q https://civitai.com/api/download/models/980278 -O "Hyper_Realism_aidma_v0.3.safetensors"

# 7. Скрипт запуска
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR ${COMFYUI_PATH}
EXPOSE 8188

CMD ["/bin/bash", "/start.sh"]
