FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone https://github.com/vllm-project/vllm.git
WORKDIR /opt/vllm

# Build/install vLLM for CPU
RUN pip install --no-cache-dir -U pip setuptools wheel \
 && pip install --no-cache-dir -r requirements/cpu.txt \
      --extra-index-url https://download.pytorch.org/whl/cpu \
 && VLLM_TARGET_DEVICE=cpu pip install --no-cache-dir -e .

ENV VLLM_USE_V1=0 \
    VLLM_TARGET_DEVICE=cpu \
    VLLM_LOGGING_LEVEL=INFO \
    HF_HOME=/data/models/hf \
    HF_HUB_CACHE=/data/models/hf/hub

EXPOSE 8000
ENTRYPOINT ["vllm", "serve"]
