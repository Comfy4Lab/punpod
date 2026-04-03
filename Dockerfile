FROM nvidia/cuda:12.6.0-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# 1. Системные пакеты (добавлен python3-dev для сборки нод)
RUN apt-get update && apt-get install -y \
    python3-pip python3-dev build-essential \
    git wget libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 2. Ставим всё приложение в /opt (эта папка НЕ затрется сетевым диском)
WORKDIR /opt

RUN python3 -m pip install --upgrade pip

# PyTorch для CUDA 12.6
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
RUN pip install xformers insightface onnxruntime-gpu

# Установка ComfyUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git . \
    && pip install --no-cache-dir -r requirements.txt

# 3. Установка Custom Nodes
WORKDIR /opt/custom_nodes
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack && \
    git clone --depth 1 https://github.com/Fannovel16/comfyui_controlnet_aux && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-SUPIR && \
    git clone --depth 1 https://github.com/ssitu/ComfyUI_UltimateSDUpscale && \
    git clone --depth 1 https://github.com/jags111/efficiency-nodes-comfyui && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Inspire-Pack && \
    git clone --depth 1 https://github.com/WASasquatch/was-node-suite-comfyui && \
    git clone --depth 1 https://github.com/chrisgoringe/cg-use-everywhere && \
    git clone --depth 1 https://github.com/pythongosssss/ComfyUI-Custom-Scripts

# Установка зависимостей нод
RUN for d in *; do [ -f "$d/requirements.txt" ] && pip install --no-cache-dir -r "$d/requirements.txt" || true; done

# 4. Скрипт запуска, который «подружит» ComfyUI и твой Network Volume
RUN echo '#!/bin/bash\n\
set -e\n\
echo "--- Initializing RunPod Network Volume ---"\n\
# Создаем структуру папок на сетевом диске, если её нет\n\
mkdir -p /workspace/models /workspace/output /workspace/input /workspace/user\n\
\n\
# Удаляем стандартные папки в образе и заменяем их ссылками на сетевой диск\n\
# Теперь все модели, которые ты скачаешь, будут жить вечно на /workspace\n\
rm -rf /opt/models && ln -s /workspace/models /opt/models\n\
rm -rf /opt/output && ln -s /workspace/output /opt/output\n\
rm -rf /opt/input && ln -s /workspace/input /opt/input\n\
# Сохраняем настройки пользователя (ноды, конфиги менеджера)\n\
[ -d "/workspace/user" ] || cp -r /opt/user /workspace/user\n\
rm -rf /opt/user && ln -s /workspace/user /opt/user\n\
\n\
cd /opt\n\
echo "--- Starting ComfyUI ---"\n\
exec python3 main.py --listen 0.0.0.0 --port 8188 --highvram' > /start.sh && chmod +x /start.sh

WORKDIR /opt
EXPOSE 8188
CMD ["/start.sh"]
