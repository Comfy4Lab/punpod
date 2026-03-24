FROM nvidia/cuda:12.6.0-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --- System packages ---
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# --- Upgrade pip ---
RUN python3 -m pip install --upgrade pip

# --- PyTorch (CUDA 12.6) ---
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# --- Performance libraries ---
RUN pip install xformers insightface

# ==================== COMFYUI ====================
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

WORKDIR /workspace/ComfyUI

RUN pip install --no-cache-dir -r requirements.txt

# ==================== CUSTOM NODES ====================
WORKDIR /workspace/ComfyUI/custom_nodes

# Git config для больших клонов
RUN git config --global http.postBuffer 1048576000 && \
    git config --global http.lowSpeedLimit 0 && \
    git config --global http.lowSpeedTime 999999

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

# --- Установка зависимостей всех нод ---
RUN for d in *; do \
        if [ -f "$d/requirements.txt" ]; then \
            echo "Installing requirements for $d..." && \
            pip install --no-cache-dir -r "$d/requirements.txt" || echo "Skipped $d"; \
        fi; \
    done

# --- Cleanup ---
RUN pip cache purge

# --- Final setup ---
WORKDIR /workspace/ComfyUI

EXPOSE 8188

CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
