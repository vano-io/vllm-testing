# vllm-testing

This repository contains a Docker-based build pipeline and GitHub Actions workflow to assemble and publish a Docker image that packages a language model (downloaded from the Hugging Face Hub) and a vLLM-ready runtime.

The workflow downloads a model snapshot into the repository workspace and then builds/pushes a Docker image. The `Dockerfile` at the repo root is used to create the image; the workflow lives at `.github/workflows/deploy.yml`.

This README explains how to build the image locally, the CI/GH Actions flow, required secrets, and recommended best practices for large model artifacts.

---

## Repository layout (important files)

- `Dockerfile` — builds the runtime image. Review it for exposed ports, entrypoint, and where it expects model files (commonly `MODEL_DIR` or a fixed path like `/app/hf-model`).
- `.github/workflows/deploy.yml` — GitHub Actions workflow that downloads a model snapshot and builds + pushes the Docker image to a registry.
- (recommended) `.dockerignore` — exclude caches, model artifacts, and other large files from Docker build context.

---

## Docs

Additional documentation is available in the `docs/` folder. See the CI/CD parameters reference for environment variables, build args, and secrets:

- `docs/ci-cd-parameters.md` — CI/CD parameters and secrets (link: ./docs/ci-cd-parameters.md)

---

## Goals

- Download a model snapshot from Hugging Face Hub.
- Build a Docker image that contains (or can access) the model and a vLLM-based serving runtime.
- Publish the image to a Docker registry (Docker Hub by default in the workflow).

---

## Prerequisites

- Docker (local builds) and optionally Docker Buildx for multi-platform builds.
- A GitHub repository with this project and Actions enabled (for CI build/publish).
- (Optional for private models) A Hugging Face token with access to the model.
- A Docker Hub account (or other registry) and credentials for pushing images.

---

## GitHub Actions workflow overview

Path: `.github/workflows/deploy.yml`

What it does (high level):

1. On push to `main`, the workflow runs.
2. It downloads the desired model snapshot via `huggingface_hub.snapshot_download` into `MODEL_DIR`.
3. It sets up Docker Buildx and logs into Docker Hub.
4. It builds and pushes the Docker image, tagging `latest`, the short commit SHA, and a semantic `VERSION` value when present.

Environment variables configured in the workflow (adjust as needed):

- `MODEL_ID` — model repo on HF (example: `Qwen/Qwen3-4B-AWQ`).
- `MODEL_DIR` — local directory name inside the repo workspace where the model is downloaded (example: `hf-model`).
- `IMAGE_NAME` — image base name used for tagging.
- `REGISTRY_NAME` — your Docker Hub username (used as the image namespace).

Secrets the workflow expects (set in GitHub repository settings → Secrets):

- `HF_TOKEN` — (optional) Hugging Face token for gated/private models.
- `DOCKER_USERNAME` and `DOCKER_PASSWORD` — credentials to push to Docker Hub.
- (The workflow also uses the built-in `GITHUB_TOKEN` for some steps.)

---

## Building locally

You have two common strategies:

A) Bake the model into the Docker image (image contains model files)

1. Download the model into `MODEL_DIR` (matching the build arg used by `Dockerfile`) locally:

```bash
# from repo root
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(repo_id="Qwen/Qwen3-4B-AWQ", local_dir="hf-model", local_dir_use_symlinks=False)
PY
```

2. Build the Docker image (this sends the model files as part of the build context — use a good `.dockerignore` to keep it minimal):

```bash
docker build \
  --build-arg MODEL_ID="Qwen/Qwen3-4B-AWQ" \
  --build-arg MODEL_DIR="hf-model" \
  -t <your-dockerhub-username>/qwen3-4b-awq-vllm:local .
```

3. Run the image (check the `Dockerfile` for the actual port/entrypoint):

```bash
docker run --rm -p 8000:8000 <your-dockerhub-username>/qwen3-4b-awq-vllm:local
```

Notes:
- Baking the model into the image increases image size and build time and may hit build-time transfer limits.
- Use `.dockerignore` to exclude everything except the model dir and necessary files.

B) Mount the model at runtime (recommended for development and large models)

1. Download the model into a local `hf-model` folder as shown above.
2. Build an image without including the model (adjust `Dockerfile` to accept `MODEL_DIR` or a runtime path), then run while mounting the local model folder into the container:

```bash
# Build the runtime image (no heavy model files in the build context)
docker build -t <your-dockerhub-username>/qwen3-4b-awq-vllm:runtime .

# Run and mount the local model directory (adjust destination path to what the container expects)
docker run --rm -p 8000:8000 -v "$(pwd)/hf-model:/app/hf-model" <your-dockerhub-username>/qwen3-4b-awq-vllm:runtime
```

This keeps images small, and model files are provided at container runtime.

---

## Using the GitHub Actions CI to publish an image

1. Edit `.github/workflows/deploy.yml` to set the default env values appropriately (or override via workflow inputs). Defaults in the file include `MODEL_ID`, `MODEL_DIR`, `IMAGE_NAME`, and `REGISTRY_NAME`.
2. Add the necessary repository secrets (`HF_TOKEN` if needed, and `DOCKER_USERNAME`/`DOCKER_PASSWORD`).
3. Push to the `main` branch — the workflow will download the model snapshot and publish the image to Docker Hub using the provided `REGISTRY_NAME` and `IMAGE_NAME`.

Tags pushed: `latest`, commit SHA, and the semantic `VERSION` file value (if present).

---

## Recommended .dockerignore (to keep build context small)

Exclude caches, model archives, large dataset directories, virtualenvs, and editor metadata. Example entries:

```
.DS_Store
.git
venv/
.venv/
__pycache__/
*.pyc
hf-model/
models/
*.ckpt
*.safetensors
*.pt
*.bin
node_modules/
```

Adjust `hf-model/` depending on whether you bake the model into the image or mount at runtime.

---

## Troubleshooting

- Build context too large: add proper patterns to `.dockerignore` and prefer runtime mounts for models.
- Private/gated models: set `HF_TOKEN` as a GitHub secret and ensure `snapshot_download` receives it.
- Push/auth errors: verify `DOCKER_USERNAME` and `DOCKER_PASSWORD` are set as secrets and valid.
- Check `Dockerfile` for the correct path where the runtime expects model files — mount or bake into that path.

---

## Security & privacy

Do not commit model weights, large binaries, or tokens to the repository. Use `.gitignore` to avoid committing local model directories and keep `HF_TOKEN` and Docker credentials in GitHub Secrets only.

---

## Contributing

If you'd like the project to support more models or alternative registries, open a PR or an issue. When adding CI changes, include small smoke tests to validate the image runtime.

---

## License

Add an appropriate license file (e.g., `LICENSE`) to the repo before publishing if you intend to release the code publicly.
