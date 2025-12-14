FROM python:3.12-slim

RUN pip install --no-cache-dir "vllm" "huggingface_hub" "transformers"

# Optional: set caches
ENV HF_HOME=/data/models/hf \
    HF_HUB_CACHE=/data/models/hf/hub \
    TRANSFORMERS_CACHE=/data/models/hf/transformers \
    VLLM_TARGET_DEVICE=cpu \
    VLLM_USE_V1=0

EXPOSE 8000
ENTRYPOINT ["vllm", "serve"]
