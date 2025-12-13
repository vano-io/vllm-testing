FROM vllm/vllm-openai:latest

ARG MODEL_ID=Qwen/Qwen3-4B-AWQ
ARG MODEL_DIR=hf-model

# Copy the model folder that GitHub Actions downloaded *before* the docker build
# This bakes the weights into the image layer.
COPY ${MODEL_DIR}/ /models/${MODEL_ID}/

EXPOSE 8000

# Serve baked AWQ model
CMD ["vllm","serve","/models/Qwen/Qwen3-4B-AWQ","--served-model-name","qwen3-4b-awq","--host","0.0.0.0","--port","8000","--quantization","awq_marlin"]
