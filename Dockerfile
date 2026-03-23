FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# --- System packages ---
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# --- Workdir ---
WORKDIR /workspace

# --- Upgrade pip ---
RUN python3 -m pip install --upgrade pip

# --- Install PyTorch (CUDA 12.1) ---
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# --- Performance libs ---
RUN pip install xformers insightface

# --- Install ComfyUI  ---
WORKDIR /workspace/ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .


# --- Installing Basic Python Dependencies ---
RUN pip install --no-cache-dir -r requirements.txt

# --- Install custom nodes ---
WORKDIR /workspace/ComfyUI/custom_nodes

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux
RUN git clone https://github.com/kijai/ComfyUI-SUPIR
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale
# RUN git clone https://github.com/Derfuu/ComfyUI-Efficiency-Nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui
# RUN git clone https://github.com/chrisgoringe/ComfyUI-FreeU
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts

# --- Install ALL node dependencies automatically ---
RUN for d in /workspace/ComfyUI/custom_nodes/* ; do \
    if [ -f "$d/requirements.txt" ]; then \
        echo "Installing requirements for $d..." && \
        pip install --no-cache-dir -r "$d/requirements.txt" || true; \
    fi \
done

# --- Cleanup (reduce image size) ---
RUN pip cache purge

# --- Back to root ---
WORKDIR /workspace/ComfyUI

# --- Port for RunPod ---
EXPOSE 8188

# --- Start ComfyUI ---
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]

