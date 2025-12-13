# CI/CD Parameters

This document lists the environment variables, build arguments, and secrets commonly required by the repository's CI/CD
pipeline and Docker build. Use these in your GitHub Actions workflow (`.github/workflows/deploy.yml`) or local build
scripts.

| Parameter       |        Type |                  Required                  | Default                       | Source          | Description / Example                                                                                                         |
|-----------------|------------:|:------------------------------------------:|-------------------------------|-----------------|-------------------------------------------------------------------------------------------------------------------------------|
| MODEL_ID        |      string |                    Yes                     | -                             | env             | Hugging Face model repo id, e.g. `Qwen/Qwen3-4B-AWQ`.                                                                         |
| MODEL_REVISION  |      string |                     No                     | `main`                        | env             | HF model revision or commit (branch, tag, or SHA).                                                                            |
| MODEL_DIR       |      string |                     No                     | `hf-model`                    | env / build-arg | Directory inside workspace where model snapshot will be downloaded (or mounted). Used as `--build-arg` or runtime mount path. |
| IMAGE_NAME      |      string |                    Yes                     | -                             | env             | Docker image name (without registry), e.g. `qwen3-4b-vllm`.                                                                   |
| REGISTRY_NAME   |      string |                    Yes                     | -                             | env             | Container registry namespace / user, e.g. `your-dockerhub-username` (used as registry prefix).                                |
| DOCKER_USERNAME |      secret |               Yes (for push)               | -                             | secret          | Docker registry username — store in GitHub Secrets.                                                                           |
| DOCKER_PASSWORD |      secret |               Yes (for push)               | -                             | secret          | Docker registry password / token — store in GitHub Secrets.                                                                   |
| HF_TOKEN        |      secret | No (for public models) / Yes (for private) | -                             | secret          | Hugging Face access token (required for gated or private models). Store in GitHub Secrets.                                    |
| GITHUB_TOKEN    |      secret |           Yes (Actions-provided)           | `${{ secrets.GITHUB_TOKEN }}` | secret          | Built-in token provided to GitHub Actions; used for some workflow steps.                                                      |
| VERSION         | string/file |                     No                     | -                             | file/env        | Optional semantic version string. Some flows read a `VERSION` file in the repo to tag the image.                              |
| BUILD_PLATFORMS |      string |                     No                     | `linux/amd64`                 | env             | Platforms passed to `docker buildx --platform` (comma-separated for multiple platforms).                                      |
| DOCKER_BUILDKIT |     boolean |                     No                     | `1`                           | env             | Enable Docker BuildKit during builds (recommended).                                                                           |
| CACHE_FROM      |      string |                     No                     | -                             | env             | Image reference to enable build cache reuse, e.g. `your/repo:cache`.                                                          |

## Example GitHub Actions env block

Below is a minimal example snippet you can paste into a workflow step or `env:` block. Keep secrets in the repository
Secrets store and don't echo them in logs.

```yaml
env:
  MODEL_ID: "Qwen/Qwen3-4B-AWQ"
  MODEL_DIR: "hf-model"
  IMAGE_NAME: "qwen3-4b-vllm"
  REGISTRY_NAME: "your-dockerhub-username"
  BUILD_PLATFORMS: "linux/amd64"
  DOCKER_BUILDKIT: "1"

# and set secrets:
# secrets.HF_TOKEN (if required), secrets.DOCKER_USERNAME, secrets.DOCKER_PASSWORD
```

## Notes & Best Practices

- Keep secrets out of repo files and only set them in repository or organization Secrets.
- For large models prefer mounting the model at runtime rather than baking it into the image; use `MODEL_DIR` only to
  point to the runtime path inside the container.
- Use a `.dockerignore` to keep the build context small and avoid accidentally sending model weights to the builder when
  you do not intend to.
- When downloading models in CI, use
  `huggingface_hub.snapshot_download(repo_id=MODEL_ID, revision=MODEL_REVISION, local_dir=MODEL_DIR, local_dir_use_symlinks=False)`
  and pass `token=HF_TOKEN` when required.
- Tag images with both `latest` and a commit SHA (and `VERSION` if present) to make rollbacks and debugging easier.

## Troubleshooting

- Authentication errors pushing images: verify `DOCKER_USERNAME`/`DOCKER_PASSWORD` secrets and login steps in the
  workflow.
- Model download errors: if a repository is gated, ensure `HF_TOKEN` is present and has appropriate scopes.
- Large build contexts: verify `.dockerignore` and prefer runtime mounts.

---

If you'd like, I can also:

- Add this file to the README with a cross-link.
- Update `.github/workflows/deploy.yml` to reference these exact variable names and provide a template workflow.

