FROM python:3.12-slim

# Build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Get vLLM source
RUN git clone https://github.com/vllm-project/vllm.git
WORKDIR /opt/vllm

# Build/install vLLM for CPU
# (docs show cpu requirements + install from source)
RUN pip install --no-cache-dir -U pip setuptools wheel \
 && pip install --no-cache-dir -r requirements/cpu.txt \
 && VLLM_TARGET_DEVICE=cpu pip install --no-cache-dir -e .

# Runtime env
ENV VLLM_USE_V1=0 \
    VLLM_TARGET_DEVICE=cpu \
    VLLM_LOGGING_LEVEL=INFO \
    HF_HOME=/data/models/hf \
    HF_HUB_CACHE=/data/models/hf/hub

EXPOSE 8000
ENTRYPOINT ["vllm", "serve"]
