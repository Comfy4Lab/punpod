FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
python3 \
python3-pip \
git \
wget \
libgl1 \
libglib2.0-0

WORKDIR /workspace

RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /workspace/ComfyUI

RUN pip install -r requirements.txt

WORKDIR /workspace/ComfyUI/custom_nodes

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux
RUN git clone https://github.com/kijai/ComfyUI-SUPIR
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale
RUN git clone https://github.com/Derfuu/ComfyUI-Efficiency-Nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui
RUN git clone https://github.com/chrisgoringe/ComfyUI-FreeU
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts

WORKDIR /workspace/ComfyUI

EXPOSE 8188

CMD ["python3","main.py","--listen","0.0.0.0","--port","8188"]
